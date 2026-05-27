import XCTest
@testable import FitTrack

final class WhoopServiceTests: XCTestCase {

    func test_parseCycleResponse_extractsRecoveryAndStrain() throws {
        let json = """
        {
          "id": "abc123",
          "score": {
            "recovery_score": 73,
            "strain": 12.4
          }
        }
        """.data(using: .utf8)!
        let result = try WhoopService.parseCycleResponse(data: json)
        XCTAssertEqual(result.recoveryScore, 73)
        XCTAssertEqual(result.strainScore ?? 0, 12.4, accuracy: 0.01)
    }

    func test_parseCycleResponse_throwsOnMalformedData() {
        let json = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try WhoopService.parseCycleResponse(data: json))
    }

    func test_parseCycleResponse_handlesNullScore() throws {
        let json = """
        {"id": "abc", "score": null}
        """.data(using: .utf8)!
        let result = try WhoopService.parseCycleResponse(data: json)
        XCTAssertNil(result.recoveryScore)
        XCTAssertNil(result.strainScore)
    }
}
