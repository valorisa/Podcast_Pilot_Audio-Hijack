import ArgumentParser
import Foundation

struct StartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Démarre une session Audio Hijack par son nom."
    )

    @Argument(help: "Nom exact de la session (sensible à la casse).")
    var name: String

    func run() async throws {
        let service: AudioHijackService = OSAKitAudioHijackService()
        do {
            try await service.start(sessionNamed: name)
            print("✅ Session '\(name)' démarrée.")
        } catch {
            let (code, message) = ErrorHandler.mapAudioHijackError(error)
            ErrorHandler.die(code, message)
        }
    }
}
