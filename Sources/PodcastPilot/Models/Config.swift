import Foundation

struct WatchConfig: Sendable {
    var sourceDir: URL
    var outputDir: URL
    var pattern: String
    var template: String
    var loudnessTarget: Double
    var embedMetadata: Bool
    var artist: String
    var copyright: String

    static let defaults = WatchConfig(
        sourceDir: URL(fileURLWithPath: NSString(string: "~/Music/Audio Hijack").expandingTildeInPath),
        outputDir: URL(fileURLWithPath: NSString(string: "~/Podcasts/Ready").expandingTildeInPath),
        pattern: "*.m4a",
        template: "{show}/EP{episode}_{title}.m4a",
        loudnessTarget: -16.0,
        embedMetadata: true,
        artist: "",
        copyright: "© 2026 PodcastPilot user"
    )

    /// Parser TOML minimal : clé = "valeur" | nombre | true|false. Une ligne par
    /// clé. Lignes vides et commentaires `#` ignorés. Suffisant pour un fichier
    /// utilisateur court ; pas de tables imbriquées.
    static func load(from url: URL) throws -> WatchConfig {
        let raw = try String(contentsOf: url, encoding: .utf8)
        var config = WatchConfig.defaults

        for rawLine in raw.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eqIdx = line.firstIndex(of: "=") else { continue }
            let key = line[..<eqIdx].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: eqIdx)...].trimmingCharacters(in: .whitespaces)
            if let hashIdx = value.firstIndex(of: "#"), !value.hasPrefix("\"") {
                value = String(value[..<hashIdx]).trimmingCharacters(in: .whitespaces)
            }
            let unquoted = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            switch key {
            case "source_dir": config.sourceDir = URL(fileURLWithPath: NSString(string: unquoted).expandingTildeInPath)
            case "output_dir": config.outputDir = URL(fileURLWithPath: NSString(string: unquoted).expandingTildeInPath)
            case "pattern": config.pattern = unquoted
            case "template": config.template = unquoted
            case "loudness_target": config.loudnessTarget = Double(unquoted) ?? config.loudnessTarget
            case "embed_metadata": config.embedMetadata = (unquoted == "true")
            case "artist": config.artist = unquoted
            case "copyright": config.copyright = unquoted
            default: break
            }
        }
        return config
    }
}
