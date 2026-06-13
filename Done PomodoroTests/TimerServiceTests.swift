//
//  TimerServiceTests.swift
//  Done PomodoroTests
//
//  Tests for TimerService: state transitions, guard conditions, and the
//  timestamp-based countdown (the design decision that keeps the timer accurate
//  across backgrounding — elapsed time derives from absolute dates, not ticks).
//
//  ⏱ The accuracy tests spin the main run loop for a second or two so the
//  internal Timer can fire. Tolerances are generous to avoid CI flakiness.
//

import XCTest
@testable import Done_Pomodoro

final class TimerServiceTests: XCTestCase {

    // MARK: - Properties

    private var timerService: TimerService!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        timerService = TimerService()
    }

    override func tearDownWithError() throws {
        timerService.stop()
        timerService = nil
    }

    // MARK: - Helpers

    /// Spins the main run loop so the service's internal Timer can tick.
    private func spinRunLoop(for seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - State Transitions

    func testStartSetsUpRunningSession() throws {
        timerService.start(duration: 1500, type: .work)

        XCTAssertEqual(timerService.state, .running)
        XCTAssertEqual(timerService.sessionType, .work)
        XCTAssertEqual(timerService.timeRemaining, 1500)
    }

    func testPauseOnlyWorksWhileRunning() throws {
        // 🚫 Pausing a stopped timer should do nothing
        timerService.pause()
        XCTAssertEqual(timerService.state, .stopped)

        // ✅ Pausing a running timer works
        timerService.start(duration: 1500, type: .work)
        timerService.pause()
        XCTAssertEqual(timerService.state, .paused)
    }

    func testResumeOnlyWorksWhilePaused() throws {
        // 🚫 Resuming a running (not paused) timer should not change state
        timerService.start(duration: 1500, type: .work)
        timerService.resume()
        XCTAssertEqual(timerService.state, .running)

        // ✅ Resume after pause returns to running
        timerService.pause()
        timerService.resume()
        XCTAssertEqual(timerService.state, .running)
    }

    func testStopResetsTimer() throws {
        timerService.start(duration: 1500, type: .shortBreak)
        timerService.stop()

        XCTAssertEqual(timerService.state, .stopped)
        XCTAssertEqual(timerService.timeRemaining, 0)
    }

    // MARK: - Timestamp-Based Countdown Accuracy

    func testCountdownTracksElapsedWallClockTime() throws {
        // ⏱ Start a 10-second timer and let ~2 seconds of real time pass
        timerService.start(duration: 10, type: .work)
        spinRunLoop(for: 2.1)

        // Remaining should be ~8 seconds (derived from the start timestamp)
        XCTAssertEqual(timerService.timeRemaining, 8, accuracy: 1.5,
                       "timeRemaining should track wall-clock elapsed time")
    }

    func testPausedTimeIsNotCountedAgainstTheSession() throws {
        // ⏱ Run for ~1s, pause for 1s, resume for ~1s → only ~2s of active time
        timerService.start(duration: 10, type: .work)
        spinRunLoop(for: 1.1)

        timerService.pause()
        let remainingAtPause = timerService.timeRemaining
        Thread.sleep(forTimeInterval: 1.0) // Paused wall-clock time — must not count

        timerService.resume()
        spinRunLoop(for: 1.1)

        // If the paused second were (wrongly) counted, remaining would be ~7.
        // Correct behavior: ~8 seconds remain (10 - ~2 active seconds).
        XCTAssertEqual(timerService.timeRemaining, remainingAtPause - 1.1, accuracy: 1.0,
                       "Pause duration must be excluded from elapsed time (start date is shifted on resume)")
    }

    func testTimerStopsItselfAtZero() throws {
        // ⏱ A 1-second timer should complete and reset itself
        timerService.start(duration: 1, type: .work)
        spinRunLoop(for: 2.5)

        XCTAssertEqual(timerService.state, .stopped,
                       "Timer should stop itself when it reaches zero")
        XCTAssertEqual(timerService.timeRemaining, 0)
    }
}
