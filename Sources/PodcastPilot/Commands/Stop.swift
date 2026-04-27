import ArgumentParser
import Foundation

struct StopCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Arrête une session Audio Hijack par son nom."
    )

    @Argument(help: "Nom exact de la session (sensible à la casse).")
    var name: String

    func run() async throws {
        let service: AudioHijackService = OSAKitAudioHijackService()
        do {
            try await service.stop(sessionNamed: name)
            print("✅ Session '\(name)' arrêtée.")
        } catch {
            let (code, message) = ErrorHandler.mapAudioHijackError(error)
            ErrorHandler.die(code, message)
        }
    }
}
