import CoreServices
import Foundation

/// Wrapper FSEvents autour d'un dossier. Émet les chemins créés/modifiés, filtre
/// par glob simple (`*.ext`), et debounce pour attendre que les fichiers soient
/// complètement écrits.
final class SessionWatcher {
    typealias Handler = @Sendable (URL) -> Void

    private let directory: URL
    private let pattern: String
    private let handler: Handler
    private var stream: FSEventStreamRef?

    init(directory: URL, pattern: String, handler: @escaping Handler) {
        self.directory = directory
        self.pattern = pattern
        self.handler = handler
    }

    deinit { stop() }

    func start() throws {
        let callback: FSEventStreamCallback = { _, clientInfo, count, paths, _, _ in
            guard let info = clientInfo,
                  let cStrings = unsafeBitCast(paths, to: UnsafePointer<UnsafePointer<CChar>>?.self)
            else { return }
            let watcher = Unmanaged<SessionWatcher>.fromOpaque(info).takeUnretainedValue()
            for i in 0..<count {
                let path = String(cString: cStrings[i])
                watcher.handle(path: path)
            }
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )

        guard let stream = FSEventStreamCreate(
            nil, callback, &context,
            [directory.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.5, // latence : on laisse Audio Hijack finir d'écrire
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        ) else {
            throw NSError(domain: "SessionWatcher", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Impossible de créer le FSEventStream"])
        }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private func handle(path: String) {
        guard matches(pattern: pattern, filename: (path as NSString).lastPathComponent) else { return }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        handler(url)
    }

    private func matches(pattern: String, filename: String) -> Bool {
        // fnmatch via NSString : "*.m4a" → suffixe .m4a, etc.
        return fnmatch(pattern, filename, 0) == 0
    }
}
