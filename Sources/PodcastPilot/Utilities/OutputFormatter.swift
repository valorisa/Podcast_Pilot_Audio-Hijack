import Foundation

enum OutputFormatter {
    static func renderTable(_ sessions: [Session]) -> String {
        guard !sessions.isEmpty else { return "(aucune session)\n" }

        let nameWidth = max(sessions.map(\.name.count).max() ?? 4, 4)
        let idWidth = 10
        let stateWidth = 8

        func pad(_ s: String, _ w: Int) -> String {
            s.count >= w ? String(s.prefix(w)) : s + String(repeating: " ", count: w - s.count)
        }

        var out = ""
        out += "\(pad("Name", nameWidth))  \(pad("ID", idWidth))  \(pad("State", stateWidth))\n"
        out += "\(String(repeating: "-", count: nameWidth))  \(String(repeating: "-", count: idWidth))  \(String(repeating: "-", count: stateWidth))\n"
        for s in sessions {
            let shortID = s.id.count > idWidth ? String(s.id.prefix(idWidth - 1)) + "…" : s.id
            out += "\(pad(s.name, nameWidth))  \(pad(shortID, idWidth))  \(pad(s.state.rawValue, stateWidth))\n"
        }
        return out
    }

    static func renderJSON(_ sessions: [Session]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sessions)
        return String(decoding: data, as: UTF8.self)
    }
}
