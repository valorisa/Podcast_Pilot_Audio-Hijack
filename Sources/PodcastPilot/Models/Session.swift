import Foundation

enum SessionState: String, Codable, Sendable {
    case stopped
    case running
    case paused
    case unknown
}

struct Session: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let state: SessionState

    var isRunning: Bool { state == .running }
}
