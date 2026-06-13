//
//  WorkSessionRepositoryTests.swift
//  Done PomodoroTests
//
//  Tests for WorkSessionRepository: CRUD, per-task fetches, and the
//  date-range query that powers "All Tasks" reports (Decision: report totals
//  come from one getAllSessionsInRange call, not per-task summation — these
//  tests guard the equivalence of the two approaches).
//
//  All tests use an in-memory Core Data store so nothing touches real user data.
//

import XCTest
import UIKit
@testable import Done_Pomodoro

final class WorkSessionRepositoryTests: XCTestCase {

    // MARK: - Properties

    private var persistence: PersistenceController!
    private var sessionRepo: WorkSessionRepository!
    private var taskRepo: TaskRepository!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        // 🧪 Fresh in-memory store for every test
        persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        sessionRepo = WorkSessionRepository(context: context)
        taskRepo = TaskRepository(context: context)
    }

    override func tearDownWithError() throws {
        taskRepo = nil
        sessionRepo = nil
        persistence = nil
    }

    // MARK: - Helpers

    /// Creates a simple test task in the in-memory store.
    private func makeTask(name: String = "Test Task") throws -> Task {
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: UIColor.blue,
                                                         requiringSecureCoding: false)
        return taskRepo.createTask(name: name,
                                   color: colorData,
                                   workDuration: 25,
                                   shortBreakDuration: 5,
                                   longBreakDuration: 15,
                                   longBreakAfter: 4,
                                   dailyGoal: 4,
                                   startBreaksAutomatically: false,
                                   startWorkSessionsAutomatically: false)
    }

    /// Creates a completed work session for `task` starting at `startTime`.
    @discardableResult
    private func makeSession(for task: Task,
                             startTime: Date,
                             intervalCount: Double = 1.0,
                             duration: Double = 25) -> WorkSession? {
        sessionRepo.createSession(for: task,
                                  startTime: startTime,
                                  type: SessionType.work.rawValue,
                                  isPaused: false,
                                  isCompleted: true,
                                  duration: duration,
                                  intervalCount: intervalCount,
                                  pauseTime: nil,
                                  totalPauseDuration: 0)
    }

    // MARK: - Create & Fetch

    func testCreateSessionPersistsAllFields() throws {
        let task = try makeTask()
        let start = Date()

        let session = try XCTUnwrap(makeSession(for: task, startTime: start,
                                                intervalCount: 0.5, duration: 12.5))

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.startTime, start)
        XCTAssertEqual(session.type, SessionType.work.rawValue)
        XCTAssertEqual(session.intervalCount, 0.5)
        XCTAssertEqual(session.duration, 12.5)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(session.task, task, "Session must be linked to its parent task")
    }

    func testGetSessionsFiltersByTaskAndSortsNewestFirst() throws {
        let taskA = try makeTask(name: "Task A")
        let taskB = try makeTask(name: "Task B")
        let now = Date()

        // 📋 Two sessions for A (older + newer), one for B
        makeSession(for: taskA, startTime: now.addingTimeInterval(-3600))
        makeSession(for: taskA, startTime: now)
        makeSession(for: taskB, startTime: now)

        let sessionsA = sessionRepo.getSessions(for: taskA)
        XCTAssertEqual(sessionsA.count, 2, "Only Task A's sessions should be returned")
        XCTAssertEqual(sessionsA.first?.startTime, now,
                       "Sessions should be sorted newest first")
    }

    // MARK: - Date-Range Query (powers "All Tasks" reports)

    func testGetAllSessionsInRangeIncludesBoundariesAndExcludesOutside() throws {
        let task = try makeTask()
        let rangeStart = Date().addingTimeInterval(-7200) // 2 hours ago
        let rangeEnd = Date()

        // 📋 Sessions exactly on both boundaries, inside, and outside the range
        makeSession(for: task, startTime: rangeStart)                          // on start boundary
        makeSession(for: task, startTime: rangeStart.addingTimeInterval(600))  // inside
        makeSession(for: task, startTime: rangeEnd)                            // on end boundary
        makeSession(for: task, startTime: rangeStart.addingTimeInterval(-600)) // before range
        makeSession(for: task, startTime: rangeEnd.addingTimeInterval(600))    // after range

        let inRange = sessionRepo.getAllSessionsInRange(from: rangeStart, to: rangeEnd)
        XCTAssertEqual(inRange.count, 3,
                       "Range query should be inclusive of both boundaries and exclude outside sessions")
    }

    func testAllTasksRangeQueryMatchesPerTaskSummation() throws {
        // 🛡 Regression guard for the report-totals fix: one range query across
        // all tasks must equal the sum of per-task results.
        let taskA = try makeTask(name: "Task A")
        let taskB = try makeTask(name: "Task B")
        let now = Date()

        makeSession(for: taskA, startTime: now.addingTimeInterval(-300), intervalCount: 1.0)
        makeSession(for: taskA, startTime: now.addingTimeInterval(-200), intervalCount: 0.5)
        makeSession(for: taskB, startTime: now.addingTimeInterval(-100), intervalCount: 1.0)

        let rangeTotal = sessionRepo
            .getAllSessionsInRange(from: now.addingTimeInterval(-3600), to: now)
            .reduce(0) { $0 + $1.intervalCount }

        let perTaskTotal = (sessionRepo.getSessions(for: taskA) + sessionRepo.getSessions(for: taskB))
            .reduce(0) { $0 + $1.intervalCount }

        XCTAssertEqual(rangeTotal, 2.5)
        XCTAssertEqual(rangeTotal, perTaskTotal,
                       "All-tasks range query and per-task summation must agree")
    }

    // MARK: - Delete

    func testDeleteSessionRemovesIt() throws {
        let task = try makeTask()
        let session = try XCTUnwrap(makeSession(for: task, startTime: Date()))

        sessionRepo.deleteSession(session)

        XCTAssertEqual(sessionRepo.getSessions(for: task).count, 0)
    }
}
