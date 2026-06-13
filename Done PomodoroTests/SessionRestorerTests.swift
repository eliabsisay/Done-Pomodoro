//
//  SessionRestorerTests.swift
//  Done PomodoroTests
//
//  Tests for SessionRestorer: restoring a persisted session from UserDefaults,
//  the force-quit (app_clean_exit) discard rule, and expiry handling.
//
//  ⚠️ These tests read/write UserDefaults.standard (which SessionRestorer uses
//  directly), so every key is snapshotted in setUp and restored in tearDown to
//  avoid corrupting real app state in the test host.
//

import XCTest
@testable import Done_Pomodoro

final class SessionRestorerTests: XCTestCase {

    // MARK: - Properties

    /// The exact key SessionRestorer/app lifecycle use for the clean-exit flag.
    private let cleanExitKey = "app_clean_exit"

    /// All UserDefaults keys these tests touch.
    private var touchedKeys: [String] {
        [cleanExitKey,
         Constants.UserDefaultsKeys.activeSessionStartDate,
         Constants.UserDefaultsKeys.activeSessionDuration,
         Constants.UserDefaultsKeys.activeSessionType]
    }

    /// Snapshot of pre-test values so tearDown can put everything back.
    private var snapshot: [String: Any] = [:]

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        // 📸 Snapshot current values, then start each test from a clean slate
        snapshot = [:]
        for key in touchedKeys {
            snapshot[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDownWithError() throws {
        // ♻️ Restore the pre-test UserDefaults state
        for key in touchedKeys {
            if let value = snapshot[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Helpers

    /// Writes a complete persisted-session record, started `elapsed` seconds ago.
    private func persistSession(elapsed: TimeInterval,
                                duration: TimeInterval,
                                type: String = SessionType.work.rawValue) {
        UserDefaults.standard.set(Date().addingTimeInterval(-elapsed),
                                  forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
        UserDefaults.standard.set(duration,
                                  forKey: Constants.UserDefaultsKeys.activeSessionDuration)
        UserDefaults.standard.set(type,
                                  forKey: Constants.UserDefaultsKeys.activeSessionType)
    }

    // MARK: - Force-Quit Discard Rule

    func testForceQuitDisablesRestoreAndClearsSessionData() throws {
        // 💥 Simulate a force-quit: clean-exit flag is false but session data exists
        UserDefaults.standard.set(false, forKey: cleanExitKey)
        persistSession(elapsed: 60, duration: 1500)

        XCTAssertFalse(SessionRestorer.hasPersistedSession,
                       "Force-quit (no clean exit) must disable session restoration")

        // 🧹 The stale session data should also have been cleared
        XCTAssertNil(UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionStartDate))
        XCTAssertNil(UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionDuration))
        XCTAssertNil(UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionType))
    }

    // MARK: - Happy-Path Restore

    func testRestoreReturnsSessionWithCorrectRemainingTime() throws {
        // ✅ Clean exit + a 25-minute work session that started 5 minutes ago
        UserDefaults.standard.set(true, forKey: cleanExitKey)
        persistSession(elapsed: 300, duration: 1500)

        XCTAssertTrue(SessionRestorer.hasPersistedSession)

        let restored = try XCTUnwrap(SessionRestorer.restore(),
                                     "A valid in-progress session should restore")
        XCTAssertEqual(restored.sessionType, .work)
        XCTAssertEqual(restored.totalDuration, 1500)
        // ⏳ ~1200 seconds should remain (generous tolerance for test execution time)
        XCTAssertEqual(restored.timeRemaining, 1200, accuracy: 5)
    }

    func testRestoreHandlesBreakSessions() throws {
        // ✅ Break sessions restore too, with the right type
        UserDefaults.standard.set(true, forKey: cleanExitKey)
        persistSession(elapsed: 30, duration: 300, type: SessionType.shortBreak.rawValue)

        let restored = try XCTUnwrap(SessionRestorer.restore())
        XCTAssertEqual(restored.sessionType, .shortBreak)
    }

    // MARK: - Expiry

    func testExpiredSessionIsNotRestored() throws {
        // ⌛️ A 10-minute session that started 30 minutes ago has fully expired
        UserDefaults.standard.set(true, forKey: cleanExitKey)
        persistSession(elapsed: 1800, duration: 600)

        XCTAssertNil(SessionRestorer.restore(),
                     "An expired session should not be restored")
    }

    // MARK: - Missing / Invalid Data

    func testHasPersistedSessionIsFalseWhenDataIncomplete() throws {
        // ✅ Clean exit, but only a start date — no duration or type
        UserDefaults.standard.set(true, forKey: cleanExitKey)
        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.activeSessionStartDate)

        XCTAssertFalse(SessionRestorer.hasPersistedSession,
                       "All three session keys must exist for a restorable session")
        XCTAssertNil(SessionRestorer.restore())
    }

    func testRestoreReturnsNilWhenNoDataExists() throws {
        UserDefaults.standard.set(true, forKey: cleanExitKey)

        XCTAssertFalse(SessionRestorer.hasPersistedSession)
        XCTAssertNil(SessionRestorer.restore())
    }

    func testRestoreReturnsNilForUnknownSessionType() throws {
        // 🧨 A corrupted/unknown session type string must not restore
        UserDefaults.standard.set(true, forKey: cleanExitKey)
        persistSession(elapsed: 60, duration: 1500, type: "notARealSessionType")

        XCTAssertNil(SessionRestorer.restore(),
                     "An unrecognized session type should fail the restore gracefully")
    }
}
