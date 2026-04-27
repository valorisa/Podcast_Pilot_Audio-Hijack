import XCTest
@testable import PodcastPilot

final class SessionTests: XCTestCase {

    func testIsRunningMirrorsState() {
        XCTAssertTrue(Session(id: "1", name: "A", state: .running).isRunning)
        XCTAssertFalse(Session(id: "2", name: "B", state: .stopped).isRunning)
        XCTAssertFalse(Session(id: "3", name: "C", state: .paused).isRunning)
        XCTAssertFalse(Session(id: "4", name: "D", state: .unknown).isRunning)
    }

    func testCodableRoundtrip() throws {
        let session = Session(id: "uuid-1", name: "Podcast", state: .running)
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        XCTAssertEqual(decoded.id, "uuid-1")
        XCTAssertEqual(decoded.name, "Podcast")
        XCTAssertEqual(decoded.state, .running)
    }

    func testExitCodesStable() {
        XCTAssertEqual(ExitCode.appNotRunning.rawValue, 10)
        XCTAssertEqual(ExitCode.sessionNotFound.rawValue, 11)
        XCTAssertEqual(ExitCode.permissionDenied.rawValue, 12)
        XCTAssertEqual(ExitCode.scriptFailed.rawValue, 13)
    }
}
