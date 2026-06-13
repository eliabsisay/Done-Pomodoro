//
//  TaskListSortPersistenceTests.swift
//  Done PomodoroTests
//
//  Tests that the To-Do and Done list sort selections persist across launches.
//  A "launch" is simulated by creating a fresh TaskListViewModel — the bug was
//  that sort options reset to their defaults every time the view model was
//  recreated because they were never written to / read from UserDefaults.
//
//  ⚠️ These tests read/write UserDefaults.standard (the production store the
//  view model uses), so the two sort keys are snapshotted in setUp and restored
//  in tearDown to avoid corrupting real app state in the test host.
//

import XCTest
@testable import Done_Pomodoro

final class TaskListSortPersistenceTests: XCTestCase {

    // MARK: - Properties

    private var touchedKeys: [String] {
        [Constants.UserDefaultsKeys.todoSortOption,
         Constants.UserDefaultsKeys.doneSortOption]
    }

    private var snapshot: [String: Any] = [:]

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        // 📸 Snapshot + clear so each test starts from "nothing persisted yet"
        snapshot = [:]
        for key in touchedKeys {
            snapshot[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDownWithError() throws {
        for key in touchedKeys {
            if let value = snapshot[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Defaults

    func testFreshViewModelUsesDefaultSortOptionsWhenNothingPersisted() throws {
        let viewModel = TaskListViewModel()

        XCTAssertEqual(viewModel.todoSortOption, .creationDate,
                       "To-Do list should default to Creation Date")
        XCTAssertEqual(viewModel.doneSortOption, .completionDate,
                       "Done list should default to Completion Date")
    }

    // MARK: - Persistence Across "Launches"

    func testTodoSortOptionPersistsAcrossViewModelRecreation() throws {
        // 🔧 First "launch": user changes the To-Do sort
        let firstLaunch = TaskListViewModel()
        firstLaunch.todoSortOption = .nameAZ

        // 🔁 Second "launch": a brand-new view model should read the saved value
        let secondLaunch = TaskListViewModel()
        XCTAssertEqual(secondLaunch.todoSortOption, .nameAZ,
                       "To-Do sort selection should survive recreation")
    }

    func testDoneSortOptionPersistsAcrossViewModelRecreation() throws {
        let firstLaunch = TaskListViewModel()
        firstLaunch.doneSortOption = .nameZA

        let secondLaunch = TaskListViewModel()
        XCTAssertEqual(secondLaunch.doneSortOption, .nameZA,
                       "Done sort selection should survive recreation")
    }

    func testBothSortOptionsAreTrackedIndependently() throws {
        let firstLaunch = TaskListViewModel()
        firstLaunch.todoSortOption = .nameZA
        firstLaunch.doneSortOption = .creationDate

        let secondLaunch = TaskListViewModel()
        XCTAssertEqual(secondLaunch.todoSortOption, .nameZA)
        XCTAssertEqual(secondLaunch.doneSortOption, .creationDate)
    }

    // MARK: - Raw Persistence Format

    func testSortOptionIsStoredAsItsRawValueString() throws {
        let viewModel = TaskListViewModel()
        viewModel.todoSortOption = .nameAZ

        // The persisted form should be the enum's rawValue, matching the
        // pattern used elsewhere (e.g. report settings).
        let stored = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.todoSortOption)
        XCTAssertEqual(stored, TodoSortOption.nameAZ.rawValue)
    }
}
