import XCTest
@testable import FitTrack

final class FatigueEngineTests: XCTestCase {

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date())!
    }

    func test_green_ifTrainedWithin4Days() {
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(2), today: Date()), .green)
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(4), today: Date()), .green)
    }

    func test_yellow_if5to7DaysAgo() {
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(5), today: Date()), .yellow)
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(7), today: Date()), .yellow)
    }

    func test_red_ifOver7DaysAgo() {
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(8), today: Date()), .red)
    }

    func test_red_ifNeverTrained() {
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: nil, today: Date()), .red)
    }

    func test_gymSession_contributesFullVolumeForPrimaryMuscle() {
        let contribution = FatigueEngine.volume(muscle: .chest, isPrimary: true, sets: 3, reps: 8)
        XCTAssertEqual(contribution, 24.0)  // 3 * 8 = 24
    }

    func test_gymSession_contributesHalfVolumeForSecondaryMuscle() {
        let contribution = FatigueEngine.volume(muscle: .triceps, isPrimary: false, sets: 3, reps: 8)
        XCTAssertEqual(contribution, 12.0)  // 3 * 8 * 0.5 = 12
    }

    func test_activitySession_flatVolumeByIntensity() {
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .low), 20.0)
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .moderate), 40.0)
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .high), 60.0)
    }
}
