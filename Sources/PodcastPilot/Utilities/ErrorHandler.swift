import Foundation

enum ExitCode: Int32 {
    case success = 0
    case generic = 1
    case appNotRunning = 10
    case sessionNotFound = 11
    case permissionDenied = 12
    case scriptFailed = 13
    case invalidArgument = 14
    case configError = 15
}

enum ErrorHandler {
    static func die(_ code: ExitCode, _ message: String) -> Never {
        FileHandle.standardError.write(Data("❌ \(message)\n".utf8))
        Darwin.exit(code.rawValue)
    }

    static func mapAudioHijackError(_ error: Error) -> (ExitCode, String) {
        if let err = error as? AudioHijackError {
            switch err {
            case .appNotRunning: return (.appNotRunning, err.localizedDescription)
            case .sessionNotFound: return (.sessionNotFound, err.localizedDescription)
            case .permissionDenied: return (.permissionDenied, err.localizedDescription)
            case .scriptFailed, .malformedResult: return (.scriptFailed, err.localizedDescription)
            }
        }
        return (.generic, error.localizedDescription)
    }
}
