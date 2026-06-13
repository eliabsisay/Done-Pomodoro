//
//  SessionManagerTests.swift
//  Done PomodoroTests
//
//  Tests for SessionManager: interval-credit rounding, session logging rules,
//  next-session selection (short vs. long break), and auto-start decisions.
//
//  All tests use an in-memory Core Data store so nothing touches real user data.
//

import XCTest
import UIKit
@testable import Done_Pomodoro

final class SessionManagerTests: XCTestCase {

    // MARK: - Properties

    private var persistence: PersistenceController!
    private var sessionRepo: WorkSessionRepository!
    private var taskRepo: TaskRepository!
    private var manager: SessionManager!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        // 🧪 Fresh in-memory store for every test — fully isolated from the app's real store
        persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        sessionRepo = WorkSessionRepository(context: context)
        taskRepo = TaskRepository(context: context)
        manager = SessionManager(sessionRepo: sessionRepo)
    }

    override func tearDownWithError() throws {
        manager = nil
        taskRepo = nil
        sessionRepo = nil
        persistence = nil
    }

    // MARK: - Helpers

    /// Creates a standard test task (25/5/15, long break after 4) in the in-memory store.
    private func makeTask(longBreakAfter: Int32 = 4,
                          startBreaksAutomatically: Bool = false,
                          startWorkSessionsAutomatically: Bool = false) throws -> Task {
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: UIColor.red,
                                                         requiringSecureCoding: false)
        return taskRepo.createTask(name: "Test Task",
                                   color: colorData,
                                   workDuration: 25,
                                   shortBreakDuration: 5,
                                   longBreakDuration: 15,
                                   longBreakAfter: longBreakAfter,
                                   dailyGoal: 4,
                                   startBreaksAutomatically: startBreaksAutomatically,
                                   startWorkSessionsAutomatically: startWorkSessionsAutomatically)
    }

    /// Logs a work session that ran for `fraction` of `totalDuration` seconds.
    /// Uses explicit start/end dates so there is zero timing flakiness.
    private func logSession(for task: Task,
                            fraction: Double,
                            totalDuration: TimeInterval = 1000,
                            type: SessionType = .work,
                            intervalCount: Double? = nil) {
        let end = Date()
        let start = end.addingTimeInterval(-totalDuration * fraction)
        manager.logCompletedSession(task: task,
                                    start: start,
                                    sessionType: type,
                                    totalDuration: totalDuration,
                                    intervalCount: intervalCount,
                                    end: end)
    }

    // MARK: - Interval Credit Rounding (PRD thresholds: <50% → 0, ≥50% → 0.5, ≥80% → 1)

    func testCreditBelowFiftyPercentIsNotLogged() throws {
        let task = try makeTask()

        // ⏱ 49% complete → no credit → session should NOT be saved
        logSession(for: task, fraction: 0.49)

        XCTAssertEqual(sessionRepo.getSessions(for: task).count, 0,
                       "A session under 50% should earn no credit and not be logged")
    }

    func testCreditAtJustOverFiftyPercentIsHalfInterval() throws {
        let task = try makeTask()

        // ⏱ 51% complete → half credit (0.5)
        logSession(for: task, fraction: 0.51)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.intervalCount, 0.5)
    }

    func testCreditJustUnderEightyPercentIsStillHalfInterval() throws {
        let task = try makeTask()

        // ⏱ 79% complete → still half credit (full credit starts at 80%)
        logSession(for: task, fraction: 0.79)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.intervalCount, 0.5)
    }

    func testCreditAtOverEightyPercentIsFullInterval() throws {
        let task = try makeTask()

        // ⏱ 81% complete → full credit (1.0)
        logSession(for: task, fraction: 0.81)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.intervalCount, 1.0)
    }

    func testFullSessionEarnsFullInterval() throws {
        let task = try makeTask()

        // ⏱ 100% complete → full credit (1.0)
        logSession(for: task, fraction: 1.0)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.intervalCount, 1.0)
    }

    // MARK: - Explicit Interval Count (complete-task-from-paused-session flow)

    func testExplicitIntervalCountOverridesCalculation() throws {
        let task = try makeTask()

        // ✅ Even though elapsed is tiny (1%), an explicit count of 1.0 must win
        logSession(for: task, fraction: 0.01, intervalCount: 1.0)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.intervalCount, 1.0)
    }

    func testExplicitZeroIntervalCountIsNotLogged() throws {
        let task = try makeTask()

        // 🚫 Explicit zero credit → nothing saved
        logSession(for: task, fraction: 1.0, intervalCount: 0)

        XCTAssertEqual(sessionRepo.getSessions(for: task).count, 0)
    }

    // MARK: - Session Logging Rules

    func testBreakSessionsAreNeverLogged() throws {
        let task = try makeTask()

        // 🚫 Breaks earn no interval credit even when fully completed
        logSession(for: task, fraction: 1.0, type: .shortBreak)
        logSession(for: task, fraction: 1.0, type: .longBreak)

        XCTAssertEqual(sessionRepo.getSessions(for: task).count, 0,
                       "Only work sessions should ever be logged")
    }

    func testDurationIsStoredInMinutes() throws {
        let task = try makeTask()

        // ⏱ 1200 seconds elapsed (96% of 1250) → stored duration should be 20 minutes
        logSession(for: task, fraction: 0.96, totalDuration: 1250)

        let sessions = sessionRepo.getSessions(for: task)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.duration ?? 0, 20.0, accuracy: 0.01,
                       "WorkSession.duration is stored in minutes, not seconds")
    }

    func testCompletedWorkSessionsCounterIncrements() throws {
        let task = try makeTask()

        XCTAssertEqual(manager.completedWorkSessions, 0)

        logSession(for: task, fraction: 1.0)
        logSession(for: task, fraction: 1.0)

        XCTAssertEqual(manager.completedWorkSessions, 2)
    }

    func testSkippedSessionDoesNotIncrementCounter() throws {
        let task = try makeTask()

        // 🚫 Under-50% session is skipped — counter must not move
        logSession(for: task, fraction: 0.3)

        XCTAssertEqual(manager.completedWorkSessions, 0)
    }

    // MARK: - Next Session Selection (longBreakAfter cadence)

    func testShortBreakFollowsWorkBeforeCycleCompletes() throws {
        let task = try makeTask(longBreakAfter: 4)

        // 1 completed session → 1 % 4 != 0 → short break next
        logSession(for: task, fraction: 1.0)

        let (nextType, nextDuration) = manager.nextSession(after: .work, for: task)
        XCTAssertEqual(nextType, .shortBreak)
        XCTAssertEqual(nextDuration, TimeInterval(task.shortBreakDuration * 60))
    }

    func testLongBreakFollowsWorkWhenCycleCompletes() throws {
        let task = try makeTask(longBreakAfter: 4)

        // 4 completed sessions → 4 % 4 == 0 → long break next
        for _ in 1...4 {
            logSession(for: task, fraction: 1.0)
        }

        let (nextType, nextDuration) = manager.nextSession(after: .work, for: task)
        XCTAssertEqual(nextType, .longBreak)
        XCTAssertEqual(nextDuration, TimeInterval(task.longBreakDuration * 60))
    }

    func testWorkFollowsShortBreak() throws {
        let task = try makeTask()

        let (nextType, nextDuration) = manager.nextSession(after: .shortBreak, for: task)
        XCTAssertEqual(nextType, .work)
        XCTAssertEqual(nextDuration, TimeInterval(task.workDuration * 60))
    }

    func testWorkFollowsLongBreak() throws {
        let task = try makeTask()

        let (nextType, nextDuration) = manager.nextSession(after: .longBreak, for: task)
        XCTAssertEqual(nextType, .work)
        XCTAssertEqual(nextDuration, TimeInterval(task.workDuration * 60))
    }

    // MARK: - Auto-Start Decisions

    func testShouldAutoStartRespectsBreakSetting() throws {
        let autoBreaksTask = try makeTask(startBreaksAutomatically: true)
        let manualBreaksTask = try makeTask(startBreaksAutomatically: false)

        XCTAssertTrue(manager.shouldAutoStart(.shortBreak, for: autoBreaksTask))
        XCTAssertTrue(manager.shouldAutoStart(.longBreak, for: autoBreaksTask))
        XCTAssertFalse(manager.shouldAutoStart(.shortBreak, for: manualBreaksTask))
        XCTAssertFalse(manager.shouldAutoStart(.longBreak, for: manualBreaksTask))
    }

    func testShouldAutoStartRespectsWorkSetting() throws {
        let autoWorkTask = try makeTask(startWorkSessionsAutomatically: true)
        let manualWorkTask = try makeTask(startWorkSessionsAutomatically: false)

        XCTAssertTrue(manager.shouldAutoStart(.work, for: autoWorkTask))
        XCTAssertFalse(manager.shouldAutoStart(.work, for: manualWorkTask))
    }
}
