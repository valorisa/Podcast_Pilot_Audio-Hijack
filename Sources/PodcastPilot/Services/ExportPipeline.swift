import CryptoKit
import Foundation

// MARK: - Ledger (persistance idempotente)

struct LedgerEntry: Codable, Sendable {
    let id: String         // SHA256(head 1MB + size)
    let source: String
    let destination: String
    let status: String     // "exported" | "failed"
    let timestamp: String
}

actor ExportLedger {
    private let url: URL
    private var seen: Set<String> = []

    init(url: URL) throws {
        self.url = url
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let raw = try String(contentsOf: url, encoding: .utf8)
            for line in raw.split(separator: "\n") {
                guard let data = line.data(using: .utf8),
                      let entry = try? JSONDecoder().decode(LedgerEntry.self, from: data),
                      entry.status == "exported" else { continue }
                seen.insert(entry.id)
            }
        }
    }

    func alreadyProcessed(_ id: String) -> Bool { seen.contains(id) }

    func record(_ entry: LedgerEntry) throws {
        let data = try JSONEncoder().encode(entry)
        let line = String(decoding: data, as: UTF8.self) + "\n"
        let handle = try FileHandle(forWritingTo: ensureFile())
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(line.utf8))
        try handle.close()
        if entry.status == "exported" { seen.insert(entry.id) }
    }

    private func ensureFile() throws -> URL {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        return url
    }
}

// MARK: - Fingerprint (identité par contenu, pas par nom)

enum FileFingerprint {
    static func compute(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let head = try handle.read(upToCount: 1_048_576) ?? Data()
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? Int) ?? 0
        var hasher = SHA256()
        hasher.update(data: head)
        hasher.update(data: Data(String(size).utf8))
        let digest = hasher.finalize()
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Pipeline

struct ExportContext {
    let source: URL
    var destination: URL?
    var metadata: [String: String] = [:]
    var fingerprint: String = ""
    var intermediate: URL?
}

protocol ExportStage {
    func apply(_ ctx: inout ExportContext, config: WatchConfig) async throws
}

struct ExportPipeline {
    let stages: [ExportStage]
    let ledger: ExportLedger

    func run(source: URL, config: WatchConfig) async throws {
        var ctx = ExportContext(source: source)
        ctx.fingerprint = try FileFingerprint.compute(for: source)

        if await ledger.alreadyProcessed(ctx.fingerprint) {
            return // déjà traité : idempotence
        }

        do {
            try await waitForFileStable(url: source)
            for stage in stages {
                try await stage.apply(&ctx, config: config)
            }
            try await ledger.record(LedgerEntry(
                id: ctx.fingerprint,
                source: source.path,
                destination: ctx.destination?.path ?? "",
                status: "exported",
                timestamp: ISO8601DateFormatter().string(from: Date())
            ))
        } catch {
            try? await ledger.record(LedgerEntry(
                id: ctx.fingerprint,
                source: source.path,
                destination: "",
                status: "failed",
                timestamp: ISO8601DateFormatter().string(from: Date())
            ))
            throw error
        }
    }

    private func waitForFileStable(url: URL, timeoutSeconds: Int = 60) async throws {
        var lastSize: Int64 = -1
        var stableTicks = 0
        for _ in 0..<timeoutSeconds {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs?[.size] as? Int64) ?? 0
            if size == lastSize && size > 0 { stableTicks += 1 } else { stableTicks = 0 }
            if stableTicks >= 2 { return }
            lastSize = size
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}

// MARK: - Stages

struct ExtractMetadataStage: ExportStage {
    func apply(_ ctx: inout ExportContext, config: WatchConfig) async throws {
        let stem = ctx.source.deletingPathExtension().lastPathComponent
        let parts = stem.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false)
        ctx.metadata["show"] = parts.indices.contains(0) ? String(parts[0]) : "Unknown"
        ctx.metadata["episode"] = parts.indices.contains(1) ? String(parts[1]) : "00"
        ctx.metadata["title"] = parts.indices.contains(2) ? String(parts[2]) : stem
        let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
        ctx.metadata["date"] = dateFmt.string(from: Date())
    }
}

struct LoudnessNormalizeStage: ExportStage {
    func apply(_ ctx: inout ExportContext, config: WatchConfig) async throws {
        // Écrit un intermédiaire normalisé via ffmpeg loudnorm. Si ffmpeg
        // échoue, on passe en fallback copy (ctx.intermediate = ctx.source).
        let out = ctx.source.deletingPathExtension()
            .appendingPathExtension("normalized.m4a")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "ffmpeg", "-y", "-i", ctx.source.path,
            "-af", "loudnorm=I=\(config.loudnessTarget):TP=-1.5:LRA=11",
            "-c:a", "aac", "-b:a", "192k",
            out.path
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            ctx.intermediate = out
        } else {
            ctx.intermediate = ctx.source // fallback : copie brute
        }
    }
}

struct ApplyTemplateStage: ExportStage {
    func apply(_ ctx: inout ExportContext, config: WatchConfig) async throws {
        var rendered = config.template
        for (key, raw) in ctx.metadata {
            let safe = sanitize(raw)
            rendered = rendered.replacingOccurrences(of: "{\(key)}", with: safe)
        }
        ctx.destination = config.outputDir.appendingPathComponent(rendered)
    }

    private func sanitize(_ s: String) -> String {
        // Whitelist contre path traversal : on garde [A-Za-z0-9 _.-]
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 _.-")
        return String(s.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }
}

struct AtomicMoveStage: ExportStage {
    func apply(_ ctx: inout ExportContext, config: WatchConfig) async throws {
        guard let destination = ctx.destination,
              let intermediate = ctx.intermediate else { return }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        let staging = destination.appendingPathExtension("part")
        if FileManager.default.fileExists(atPath: staging.path) {
            try FileManager.default.removeItem(at: staging)
        }

        if intermediate == ctx.source {
            try FileManager.default.copyItem(at: intermediate, to: staging)
        } else {
            try FileManager.default.moveItem(at: intermediate, to: staging)
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: staging, to: destination)
    }
}

enum DefaultPipeline {
    static func build(ledger: ExportLedger) -> ExportPipeline {
        ExportPipeline(
            stages: [
                ExtractMetadataStage(),
                LoudnessNormalizeStage(),
                ApplyTemplateStage(),
                AtomicMoveStage(),
            ],
            ledger: ledger
        )
    }
}
