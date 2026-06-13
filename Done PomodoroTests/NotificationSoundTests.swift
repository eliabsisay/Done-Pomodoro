//
//  NotificationSoundTests.swift
//  Done PomodoroTests
//
//  Tests for notification sound resolution after the move to a Default/None
//  model. The previous code offered sound names ("chime", "bell", "marimba")
//  that mapped to .caf files which were never bundled — so those options
//  played nothing deliberate, and "none" still produced the default sound.
//
//  Now: "none" → silent (nil), everything else → the system default sound.
//  Legacy stored values are coerced to "default" by SettingsViewModel.
//
//  ⚠️ The normalization tests read/write UserDefaults.standard, so the two
//  sound keys are snapshotted in setUp and restored in tearDown.
//

import XCTest
import UserNotifications
@testable import Done_Pomodoro

final class NotificationSoundTests: XCTestCase {

    // MARK: - getSoundFor mapping

    func testNoneResolvesToSilentNil() {
        XCTAssertNil(NotificationService.shared.getSoundFor(name: "none"),
                     "'none' must produce no sound (a silent banner)")
    }

    func testDefaultResolvesToSystemDefaultSound() {
        XCTAssertEqual(NotificationService.shared.getSoundFor(name: "default"), .default)
    }

    func testLegacySoundNamesFallBackToDefault() {
        // Names that used to point at missing .caf files must now degrade to
        // the system default sound rather than silence-by-accident.
        for legacy in ["ding", "chime", "bell", "marimba", "swoosh", "completed", "anything"] {
            XCTAssertEqual(NotificationService.shared.getSoundFor(name: legacy), .default,
                           "Unrecognized '\(legacy)' should fall back to the default sound")
        }
    }

    // MARK: - supportedSounds invariant

    func testSupportedSoundsIsDefaultAndNone() {
        XCTAssertEqual(SettingsViewModel.supportedSounds, ["default", "none"])
    }

    // MARK: - Legacy value normalization in SettingsViewModel

    private var soundKeys: [String] {
        [Constants.UserDefaultsKeys.workCompletedSound,
         Constants.UserDefaultsKeys.breakCompletedSound]
    }
    private var snapshot: [String: Any] = [:]

    override func setUpWithError() throws {
        snapshot = [:]
        for key in soundKeys {
            snapshot[key] = UserDefaults.standard.object(forKey: key)
        }
    }

    override func tearDownWithError() throws {
        for key in soundKeys {
            if let value = snapshot[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    @MainActor
    func testLegacyStoredSoundIsCoercedToDefault() {
        // Simulate a user who saved "chime" before custom sounds were removed.
        UserDefaults.standard.set("chime", forKey: Constants.UserDefaultsKeys.workCompletedSound)
        UserDefaults.standard.set("marimba", forKey: Constants.UserDefaultsKeys.breakCompletedSound)

        let viewModel = SettingsViewModel()

        // The picker-facing values are valid options...
        XCTAssertEqual(viewModel.workCompletedSound, "default")
        XCTAssertEqual(viewModel.breakCompletedSound, "default")

        // ...and the coercion is persisted so it doesn't recur.
        XCTAssertEqual(UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.workCompletedSound), "default")
        XCTAssertEqual(UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.breakCompletedSound), "default")
    }

    @MainActor
    func testValidStoredSoundIsPreserved() {
        UserDefaults.standard.set("none", forKey: Constants.UserDefaultsKeys.workCompletedSound)
        UserDefaults.standard.set("default", forKey: Constants.UserDefaultsKeys.breakCompletedSound)

        let viewModel = SettingsViewModel()

        XCTAssertEqual(viewModel.workCompletedSound, "none")
        XCTAssertEqual(viewModel.breakCompletedSound, "default")
    }
}
