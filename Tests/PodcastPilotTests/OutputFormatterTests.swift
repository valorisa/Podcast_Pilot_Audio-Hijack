import XCTest
@testable import PodcastPilot

final class OutputFormatterTests: XCTestCase {

    func testRenderTableEmpty() {
        let out = OutputFormatter.renderTable([])
        XCTAssertTrue(out.contains("(aucune session)"))
    }

    func testRenderTableIncludesSessionName() {
        let sessions = [
            Session(id: "abc123", name: "Podcast", state: .running),
            Session(id: "def456", name: "Interview", state: .stopped),
        ]
        let out = OutputFormatter.renderTable(sessions)
        XCTAssertTrue(out.contains("Podcast"))
        XCTAssertTrue(out.contains("Interview"))
        XCTAssertTrue(out.contains("running"))
        XCTAssertTrue(out.contains("stopped"))
    }

    func testRenderJSONRoundtrip() throws {
        let sessions = [Session(id: "xyz", name: "Test", state: .running)]
        let jsonString = try OutputFormatter.renderJSON(sessions)
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let decoded = try JSONDecoder().decode([Session].self, from: data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.name, "Test")
        XCTAssertEqual(decoded.first?.state, .running)
    }
}
