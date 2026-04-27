import ArgumentParser
import Foundation

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Liste les sessions Audio Hijack."
    )

    @Flag(name: .long, help: "Sortie JSON au lieu du tableau ASCII.")
    var json: Bool = false

    func run() async throws {
        let service: AudioHijackService = OSAKitAudioHijackService()
        do {
            let sessions = try await service.listSessions()
            if json {
                print(try OutputFormatter.renderJSON(sessions))
            } else {
                print(OutputFormatter.renderTable(sessions), terminator: "")
            }
        } catch {
            let (code, message) = ErrorHandler.mapAudioHijackError(error)
            ErrorHandler.die(code, message)
        }
    }
}
