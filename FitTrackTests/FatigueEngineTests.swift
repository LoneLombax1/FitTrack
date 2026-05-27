import XCTest
@testable import FitTrack

final class FatigueEngineTests: XCTestCase {

    private func daysAgo(_ n: Int, from reference: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: reference)!
    }

    func test_green_ifTrainedWithin4Days() {
        let today = Date()
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(2, from: today), today: today), .green)
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(4, from: today), today: today), .green)
    }

    func test_yellow_if5to7DaysAgo() {
        let today = Date()
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(5, from: today), today: today), .yellow)
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(7, from: today), today: today), .yellow)
    }

    func test_red_ifOver7DaysAgo() {
        let today = Date()
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: daysAgo(8, from: today), today: today), .red)
    }

    func test_red_ifNeverTrained() {
        XCTAssertEqual(FatigueEngine.fatigueColor(lastTrained: nil, today: Date()), .red)
    }

    func test_gymSession_contributesFullVolumeForPrimaryMuscle() {
        let contribution = FatigueEngine.volume(isPrimary: true, sets: 3, reps: 8)
        XCTAssertEqual(contribution, 24.0)  // 3 * 8 = 24
    }

    func test_gymSession_contributesHalfVolumeForSecondaryMuscle() {
        let contribution = FatigueEngine.volume(isPrimary: false, sets: 3, reps: 8)
        XCTAssertEqual(contribution, 12.0)  // 3 * 8 * 0.5 = 12
    }

    func test_activitySession_flatVolumeByIntensity() {
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .low), 20.0)
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .moderate), 40.0)
        XCTAssertEqual(FatigueEngine.activityVolume(intensity: .high), 60.0)
    }

    func test_lastTrainedDates_returnsCorrectDateForTrainedMuscle() {
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let sessions = [
            TrainingSessionSnapshot(date: threeDaysAgo, musclesWorked: [.chest, .triceps])
        ]
        let result = FatigueEngine.lastTrainedDates(from: sessions, windowDays: 7, today: today)
        XCTAssertEqual(result[.chest], threeDaysAgo)
        XCTAssertEqual(result[.triceps], threeDaysAgo)
        XCTAssertNil(result[.legs])
    }

    func test_lastTrainedDates_excludesSessionsOutsideWindow() {
        let today = Date()
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: today)!
        let sessions = [
            TrainingSessionSnapshot(date: eightDaysAgo, musclesWorked: [.chest])
        ]
        let result = FatigueEngine.lastTrainedDates(from: sessions, windowDays: 7, today: today)
        XCTAssertNil(result[.chest])
    }

    func test_lastTrainedDates_keepsLatestDateWhenMultipleSessions() {
        let today = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: today)!
        let sessions = [
            TrainingSessionSnapshot(date: fiveDaysAgo, musclesWorked: [.chest]),
            TrainingSessionSnapshot(date: twoDaysAgo, musclesWorked: [.chest]),
        ]
        let result = FatigueEngine.lastTrainedDates(from: sessions, windowDays: 7, today: today)
        XCTAssertEqual(result[.chest], twoDaysAgo)
    }
}
