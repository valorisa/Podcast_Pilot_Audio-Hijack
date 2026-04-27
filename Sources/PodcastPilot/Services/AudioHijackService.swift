import AppKit
import Foundation
import OSAKit

enum AudioHijackError: Error, LocalizedError {
    case appNotRunning
    case permissionDenied
    case sessionNotFound(String)
    case scriptFailed(code: Int, message: String)
    case malformedResult(String)

    var errorDescription: String? {
        switch self {
        case .appNotRunning:
            return "Audio Hijack n'est pas lancé."
        case .permissionDenied:
            return "Permission d'automatisation refusée. Réglages Système → Confidentialité → Automatisation."
        case .sessionNotFound(let name):
            return "Session '\(name)' introuvable dans Audio Hijack."
        case .scriptFailed(let code, let message):
            return "AppleScript error \(code): \(message)"
        case .malformedResult(let raw):
            return "Résultat AppleScript inattendu : \(raw)"
        }
    }
}

protocol AudioHijackService: Sendable {
    func isRunning() -> Bool
    func listSessions() async throws -> [Session]
    func start(sessionNamed name: String) async throws
    func stop(sessionNamed name: String) async throws
}

/// Implémentation via OSAKit + AppleScript officiel d'Audio Hijack.
///
/// TODO(sdef): les noms de propriétés (`name`, `id`, `running`) et les commandes
/// (`start`, `stop`) sont à confirmer contre le dictionnaire réel d'Audio
/// Hijack 4.5.7 — à dumper sur le Mac mini M2 avec :
///   sdef /Applications/Audio\ Hijack.app > audiohijack.sdef
struct OSAKitAudioHijackService: AudioHijackService {
    private static let targetBundleID = "com.rogueamoeba.audiohijack"

    func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.targetBundleID
        }
    }

    func listSessions() async throws -> [Session] {
        // On passe par JavaScript for Automation (JXA) qui retourne du JSON
        // natif — pas de parsing regex fragile sur les records AppleScript.
        let jxa = """
        (function() {
          const ah = Application('\(Self.targetBundleID)');
          const out = ah.sessions().map(s => ({
            id: String(s.id()),
            name: String(s.name()),
            running: Boolean(s.running())
          }));
          return JSON.stringify(out);
        })();
        """
        let raw = try await executeJXA(jxa)
        guard let data = raw.data(using: .utf8) else {
            throw AudioHijackError.malformedResult(raw)
        }
        struct Row: Decodable { let id: String; let name: String; let running: Bool }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.map { Session(id: $0.id, name: $0.name, state: $0.running ? .running : .stopped) }
    }

    func start(sessionNamed name: String) async throws {
        try await control(name: name, action: "start")
    }

    func stop(sessionNamed name: String) async throws {
        try await control(name: name, action: "stop")
    }

    private func control(name: String, action: String) async throws {
        let escaped = name.replacingOccurrences(of: "\"", with: "\\\"")
        let jxa = """
        (function() {
          const ah = Application('\(Self.targetBundleID)');
          const match = ah.sessions.whose({name: "\(escaped)"})[0];
          if (!match) throw new Error('SESSION_NOT_FOUND');
          match.\(action)();
          return 'ok';
        })();
        """
        do {
            _ = try await executeJXA(jxa)
        } catch AudioHijackError.scriptFailed(_, let message) where message.contains("SESSION_NOT_FOUND") {
            throw AudioHijackError.sessionNotFound(name)
        }
    }

    // MARK: - OSAKit plumbing

    private func executeJXA(_ source: String) async throws -> String {
        guard isRunning() else { throw AudioHijackError.appNotRunning }

        let script = OSAScript(source: source, language: OSALanguage(forName: "JavaScript"))
        var errorInfo: NSDictionary?
        guard let descriptor = script.executeAndReturnError(&errorInfo) else {
            if let info = errorInfo {
                let code = (info[OSAScriptErrorNumber] as? Int) ?? -1
                let message = (info[OSAScriptErrorMessage] as? String) ?? "unknown"
                if code == -1743 { throw AudioHijackError.permissionDenied }
                throw AudioHijackError.scriptFailed(code: code, message: message)
            }
            throw AudioHijackError.scriptFailed(code: -1, message: "unknown")
        }
        return descriptor.stringValue ?? ""
    }
}
