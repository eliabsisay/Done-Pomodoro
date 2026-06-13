# Done Pomodoro — Agent Brief

Native iOS Pomodoro timer app (SwiftUI, MVVM). **Fully offline and private by design**: no networking layer, no accounts, no analytics telemetry, no third-party dependencies — Apple frameworks only (SwiftUI, Core Data, UserNotifications, Swift Charts, StoreKit). If a feature seems to need networking, that's a deliberate architectural decision to raise, not a gap to fix.

Full product history and rationale: `~/Downloads/Pomodoro_App_Project_Handoff.md`. The repo is source of truth where they conflict.

## Build & run

- Xcode 26.3+, open `Done Pomodoro.xcodeproj`. Deployment target: **iOS 18.2**.
- No SPM/CocoaPods/Carthage, no secrets, no signing needed for simulator.
- First launch seeds a default 25/5/15 task (`DataSeeder` + `hasCreatedDefaultTask` flag).
- ⚠️ **Before running, check `Common/DevEnvironment.swift`**: its flags (`shouldDeleteAllTasks`, `shouldForceReseedTasks`, `shouldDeleteAllSessions`) run at every launch via `DevEnvironment.configure()` and will wipe data if `true`. All are `false` as of June 2026 — keep them that way except for deliberate resets, and never commit them as `true`.

## Architecture map

Views (SwiftUI) ↔ ViewModels (`ObservableObject`/`@Published`) ↔ Services/Repositories ↔ Core Data + UserDefaults.

| Area | Location | Key types |
|---|---|---|
| App entry | `Done Pomodoro/` | `Done_PomodoroApp` (@main), `Persistence.swift` (`PersistenceController`) |
| Services | `App Core/` | `TimerService`, `SessionManager`, `SessionRestorer`, `SettingsService`, `AppEvents` |
| Shared | `Common/` | `Constants`, `DevEnvironment`, color/font/string extensions |
| Tabs | `Modules/MainTabView.swift` | |
| Timer | `Modules/Timer/` | `WorkSessionView(+ViewModel)`, `TaskPickerView` |
| Tasks | `Modules/TaskManagement/` | `TaskListView(+ViewModel)`, `ToDoListView`, `DoneListView`, `TaskEditView`, `DurationPickerView`, `AlertView`, `TaskCompletionOverlayService` |
| Settings | `Modules/Settings/` | `SettingsView`, `SettingViewModel`, `AboutView`, `HowItWorksView` |
| Reports | `Modules/Reports/` | `ReportsView(+ViewModel)`, `ReportBarChartView`, `ReportPieChartView`, `ReportCache`, `ReportSettingsView` |
| Data | `Data/` | `TaskRepository`, `WorkSessionRepository`, `DataSeeder`, xcdatamodeld |
| Notifications | `Notifications/` | `NotificationService` |

**Persistence is split deliberately** (don't relitigate): Core Data holds business entities (`Task`, `WorkSession`) only; UserDefaults holds settings, lifecycle flags, and active-session state. Single source of truth per value — never duplicate across stores.

## Gotchas (each of these has caused real bugs)

- **`Task` is the Core Data entity**, shadowing Swift Concurrency's `Task`. Write `_Concurrency.Task` explicitly if you need the concurrency type.
- **Core Data codegen is Class Definition** — never hand-write `NSManagedObject` subclasses, and don't re-add conformances the generated classes already have (re-adding `Identifiable` to `Task` broke the build once).
- **Session-state UserDefaults keys must match `Constants.UserDefaultsKeys` exactly** or session restore fails *silently*. Always use the `Constants` namespaces (`UserDefaultsKeys`, `SessionLabels`, `NotificationConstants`, `AppearanceMode`, `UI`) — no string literals.
- **Tab switching uses a raw magic-string notification `"SwitchToTimerTab"`** (posted in `TaskListViewModel`, observed in `MainTabView`) — it is *not* in `AppEvents`; don't typo it.
- **Cross-view refreshes go through `AppEvents`** (NotificationCenter wrapper: `sessionCompleted`, `taskModified`, `taskSelected`), not direct calls. Post the event when adding data Reports/lists should reflect; remove observers in `deinit`.
- **The timer is timestamp-based, not tick-counting** — elapsed time derives from stored absolute start timestamps so it survives backgrounding and restore. Never refactor toward a decrementing counter.
- **Backgrounding preserves the session; force-quit discards it** (`app_clean_exit` flag). Intentional UX, not a bug.
- **Task color is archived `UIColor` Binary Data**, decoded with deprecated `unarchiveTopLevelObjectWithData` duplicated across 5 files (`WorkSessionViewModel`, `TaskPickerView`, `TaskRowView`, `TaskEditView`, `ReportsViewModel`). Match the existing pattern, or refactor all 5 at once — never half.
- **Register new settings' defaults in `SettingsService.registerDefaults()`** (called from app entry).
- **Portrait-locked** (Info.plist). No landscape layouts.

## Conventions

- Heavy inline comments and emoji-tagged `print` debug statements (📋 🔁 ✅ etc.) are **intentional** owner preference — keep new code in the same verbose style; don't strip them.
- Custom `AlertView` instead of system `.alert()` for visual consistency.
- Branches: `feature/*` / `bugfix/*` merged to `main` via PR.
- Interval credit rounding (PRD-confirmed, in `SessionManager`): ≥80% of work time → 1 interval; ≥50% → 0.5; below → 0.
- "All Tasks" reports use one direct range query (`getAllSessionsInRange`), not per-task summation — this fixed a totals bug; keep it.

## Current state & known gaps (June 2026)

- Last feature work: June 2025 (duration wheel-picker in `TaskEditView`, PRs #8–11).
- **No meaningful tests** (targets are Xcode boilerplate), **no CI**, **no SwiftLint**. Highest-priority debt: tests for timer accuracy, interval credit, session restore, report aggregation.
- **Custom notification sounds are broken-by-omission**: `NotificationService.getSoundFor` references `chime.caf`/`bell.caf`/`swoosh.caf`/`completed.caf` but no audio files are bundled — falls back to default/silent. Decision pending: bundle sounds or commit to `.default`.
- Task-list sort selection doesn't persist across launches (known gap).
- Onboarding (carousel) was never built; `hasCompletedOnboarding` flag exists unused. In/out decision pending.
- App rating uses `SKStoreReviewController`, simulated in debug; production path unverified.
- Custom pie chart predates the iOS 18.2 target — could now be Swift Charts `SectorMark`, but works fine as is; low priority.
