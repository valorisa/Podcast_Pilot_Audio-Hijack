import XCTest
@testable import PodcastPilot

final class ExportPipelineTests: XCTestCase {

    func testApplyTemplateSubstitutes() async throws {
        var ctx = ExportContext(source: URL(fileURLWithPath: "/tmp/src.m4a"))
        ctx.metadata = ["show": "MyShow", "episode": "042", "title": "Pilot"]
        ctx.intermediate = ctx.source

        var config = WatchConfig.defaults
        config.outputDir = URL(fileURLWithPath: "/tmp/out")
        config.template = "{show}/EP{episode}_{title}.m4a"

        try await ApplyTemplateStage().apply(&ctx, config: config)
        XCTAssertEqual(ctx.destination?.path, "/tmp/out/MyShow/EP042_Pilot.m4a")
    }

    func testApplyTemplateSanitizesPathTraversal() async throws {
        var ctx = ExportContext(source: URL(fileURLWithPath: "/tmp/src.m4a"))
        ctx.metadata = ["show": "../../etc", "episode": "1", "title": "safe"]

        var config = WatchConfig.defaults
        config.outputDir = URL(fileURLWithPath: "/tmp/out")
        config.template = "{show}/EP{episode}_{title}.m4a"

        try await ApplyTemplateStage().apply(&ctx, config: config)
        let path = ctx.destination?.path ?? ""
        XCTAssertFalse(path.contains(".."), "Path traversal autorisée : \(path)")
    }

    func testExtractMetadataParsesFilename() async throws {
        var ctx = ExportContext(source: URL(fileURLWithPath: "/tmp/MyShow_042_PilotEpisode.m4a"))
        try await ExtractMetadataStage().apply(&ctx, config: .defaults)
        XCTAssertEqual(ctx.metadata["show"], "MyShow")
        XCTAssertEqual(ctx.metadata["episode"], "042")
        XCTAssertEqual(ctx.metadata["title"], "PilotEpisode")
    }

    func testFingerprintStableForSameContent() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fingerprint-\(UUID().uuidString).bin")
        let content = Data(repeating: 0x42, count: 4096)
        try content.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let a = try FileFingerprint.compute(for: url)
        let b = try FileFingerprint.compute(for: url)
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.hasPrefix("sha256:"))
    }

    func testLedgerDeduplicates() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ledger-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: url) }

        let ledger = try ExportLedger(url: url)
        let entry = LedgerEntry(id: "sha256:abc", source: "/a", destination: "/b",
                                status: "exported", timestamp: "2026-04-27T00:00:00Z")
        try await ledger.record(entry)

        let reloaded = try ExportLedger(url: url)
        let seen = await reloaded.alreadyProcessed("sha256:abc")
        XCTAssertTrue(seen)
    }
}
