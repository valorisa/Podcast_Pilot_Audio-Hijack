import ArgumentParser
import Foundation

@main
struct PodcastPilot: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "podcastpilot",
        abstract: "Pilote Audio Hijack depuis le terminal.",
        version: "0.1.0-alpha",
        subcommands: [ListCommand.self, StartCommand.self, StopCommand.self, WatchCommand.self]
    )
}
