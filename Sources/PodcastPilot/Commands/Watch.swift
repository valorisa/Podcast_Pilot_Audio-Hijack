import ArgumentParser
import Foundation

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch",
        abstract: "Surveille le dossier source et exporte les enregistrements."
    )

    @Option(name: .long, help: "Chemin vers le fichier de config TOML.")
    var config: String = NSString(string: "~/.ppilot.toml").expandingTildeInPath

    @Flag(name: .long, help: "N'exporte pas ; affiche seulement ce qui serait fait.")
    var dryRun: Bool = false

    func run() async throws {
        let configURL = URL(fileURLWithPath: config)
        let conf: WatchConfig
        if FileManager.default.fileExists(atPath: configURL.path) {
            conf = try WatchConfig.load(from: configURL)
        } else {
            print("⚠️  Config introuvable (\(configURL.path)). Utilisation des valeurs par défaut.")
            conf = .defaults
        }

        let ledgerURL = URL(fileURLWithPath: NSString(string: "~/.ppilot").expandingTildeInPath)
            .appendingPathComponent("ledger.jsonl")
        let ledger = try ExportLedger(url: ledgerURL)
        let pipeline = DefaultPipeline.build(ledger: ledger)

        print("📁 Surveillance : \(conf.sourceDir.path)")
        print("📤 Destination  : \(conf.outputDir.path)")
        print("🎚️  Loudness    : \(conf.loudnessTarget) LUFS")
        if dryRun { print("🧪 Mode DRY-RUN — aucun fichier ne sera déplacé.") }

        let watcher = SessionWatcher(directory: conf.sourceDir, pattern: conf.pattern) { url in
            Task {
                do {
                    if dryRun {
                        print("🧪 Détecté : \(url.lastPathComponent) (dry-run, skip)")
                        return
                    }
                    try await pipeline.run(source: url, config: conf)
                    print("✅ Exporté : \(url.lastPathComponent)")
                } catch {
                    print("❌ Échec \(url.lastPathComponent) : \(error.localizedDescription)")
                }
            }
        }

        try watcher.start()
        print("🎙️  PodcastPilot watch démarré. Ctrl-C pour arrêter.")

        // Boucle d'attente — FSEvents tourne sur sa propre queue.
        while !Task.isCancelled {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
