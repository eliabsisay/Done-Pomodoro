# Plan: Modern Visual Redesign of Done Pomodoro

## Context

The app works but looks "old-school" — it was built with default SwiftUI components to get a functional product in place. The owner wants a modern, dynamic, textured, polished, inviting look and feel. We assessed the current design layer and confirmed it's a deliberately lean, **stock-SwiftUI** foundation: 8 system text styles (`Font+Extensions`), 5 flat brand colors (`Color+Extensions`), and only two UI constants (16pt padding, 12pt radius in `Constants.UI`). There is **no spacing scale, no elevation/shadow system, no custom button/control styles, and almost no materials or motion** — most screens use default `List`/`Form`/`Button`/segmented pickers. Upside: no legacy styling to unwind, and the project uses filesystem-synchronized groups, so new files/folders auto-add to the target with no `project.pbxproj` editing.

**Decisions made with the owner:**
- **Method: SwiftUI-first.** Build the design system directly in SwiftUI and iterate against rendered output. No Figma/Claude Design translation gap; the modern qualities wanted (materials, gradients, depth, spring/phase motion) live in code anyway.
- **Aesthetic: prototype-and-pick.** Before committing a direction, build a few variants and screenshot them so the owner chooses from real renders, not adjectives.
- **Scope: hero-first, incremental.** One reviewable PR per stage, CI green each time. Order: design system + Timer → Task list → Reports → secondary screens.
- **Light + dark are both fully supported** — first-class in every prototype and PR.
- **App icon is out of scope** for this effort.

The 57-test suite covers **logic only** (timer/rounding/restore/sounds/colors) and executes **no view code** — it does not catch view regressions. View correctness is verified by the manual test matrix + screenshots below, in both light and dark mode.

## Pre-steps (do before Phase 0)

1. **Validate the render→screenshot loop with a one-view spike.** Confirm we can render a single SwiftUI view variant and produce light + dark screenshots end-to-end before investing in full prototypes. Screenshots from **SwiftUI Previews with mock data** are acceptable (no need to drive the running app into a live-session state).
2. **Remove the stray `Done Pomodoro copy` target.** It's an accidental duplicate native target (no shared scheme; shares the synchronized source folder, so it silently absorbs every new file). Cleanest removal is via Xcode UI (right-click the target → Delete). Do this first so it can't inject confusing build noise once we start adding design-system files.

## Approach

### Phase 0 — Direction prototypes (throwaway, for the pick)
Build a few visually distinct redesigns as **self-contained SwiftUI Previews with mock data** (not wired into the running app), covering meaningfully different vibes (e.g. calm/minimal, bold/energetic, dark/glassy). Prototype **two screens, not one**: the timer (`WorkSessionView`, a sparse focal layout) **and** the task list (`TaskListView`/`TaskRowView`, a dense list layout) — a direction must work on both before it's chosen, or it won't survive Phase 2. Screenshot each variant in **light and dark**. Owner picks the winning direction. **Commit the prototypes to a throwaway branch (`spike/design-directions`) immediately** so nothing is lost on a branch switch. Only the chosen direction graduates into the real design system. Nothing logic-related changes.

### Phase 1 (PR1) — Design system foundation + Timer screen
Build the reusable backbone from the chosen direction, then redesign the timer screen on top of it. **Treat the token set as provisional and revisable through PR2** — it isn't "locked" until it has survived the dense task-list screen.

- **Tokens** (namespaced under `Constants`, matching the existing convention — e.g. `Constants.Spacing`, `Constants.Elevation`, `Constants.Motion`; colors stay in `Color+Extensions`):
  - Color: extend `Common/Color+Extensions.swift` with semantic roles (surface, surfaceElevated, success/warning/destructive), accent ramps, and gradient definitions. Add new colorsets to `Done Pomodoro/Assets.xcassets` as needed (follow the `BrandPrimary`/`BrandSecondary` pattern; keep asset names collision-free per the lesson from the earlier rename). Every colorset gets light **and** dark variants.
  - Spacing scale + radii + elevation/shadow tiers: add `Constants.Spacing` / `Constants.Elevation`.
  - Motion: `Constants.Motion` — a small set of named animations (e.g. `.snappy`, `.gentle`) so timing is consistent.
  - Typography: refine `Common/Font+Extensions.swift` if the direction calls for it (weights, rounded/serif, sizes).
- **Reusable components** (new files under `Common/DesignSystem/` — auto-added via synchronized groups):
  - `ButtonStyle`s: primary / secondary / destructive — replacing the inline `.borderedProminent`/`.bordered` + hardcoded `.tint(.blue/.green/.red)` scattered through the views.
  - A surface/card `ViewModifier` (`.cardStyle()`) encapsulating background + radius + shadow/material.
  - An app background (gradient/material) applied behind hero screens.
  - Extract the timer ring into its own component (e.g. `TimerRingView`) with the redesigned look (depth, gradient stroke, glow/texture per direction) — driven by the existing `viewModel.progress` and `viewModel.taskColor`.
- **Redesign `WorkSessionView`** using the above. **Preserve exactly**: all `viewModel` bindings (`currentTask`, `progress`, `taskColor`, `isRunning`, `isStartable`, `sessionType`, `sessionTypeLabel`, `timeRemaining.formattedAsTimer`) and the full control-button state machine. Restyle only; do not alter actions or conditions. Keep the success overlay and sheets wired.

### Phase 2 (PR2) — Task management
Redesign `TaskListView`, `TaskRowView`, `ToDoListView`, `DoneListView`: custom row cells (color dot, active-timer indicator, durations), the To-Do/Done segmented control, the prominent Add button, swipe-action and empty-state styling. Harden the provisional Phase-1 tokens against this dense layout; lock the system here. Preserve all `TaskListViewModel` bindings (including the sort persistence shipped earlier and the `taskColor` decode via `Color.fromTaskColorData`).

### Phase 3 (PR3) — Reports
Redesign `ReportsView` (header, filter buttons, segmented chart toggle, summary card), `ReportBarChartView` (Swift Charts `BarMark` styling), and the custom `ReportPieChartView`/`PieChart`/`PieSlice`. Reuse the card/surface and color tokens; keep `displayColor` via `Color.fromTaskColorData`. **Performance check:** render the charts with ~30 tasks and confirm the custom pie chart stays smooth.

### Phase 4 (PR4) — Secondary screens + chrome
`SettingsView`, `TaskEditView` (form + color grid + duration rows), `DurationPickerView`, `AboutView`, `HowItWorksView`, custom `AlertView`, `TaskCompletedOverlayView`, and TabView/tab-bar styling. Apply the system consistently for a cohesive finish. (App icon excluded.)

## Critical files
- Hero / Phase 1: `Modules/Timer/WorkSessionView.swift`, `Common/Color+Extensions.swift`, `Common/Font+Extensions.swift`, `Common/Constants.swift`, `Done Pomodoro/Assets.xcassets/`, plus new `Common/DesignSystem/` (ButtonStyles + card modifier + `TimerRingView`).
- Phase 2: `Modules/TaskManagement/{TaskListView,TaskRowView,ToDoListView,DoneListView}.swift`.
- Phase 3: `Modules/Reports/{ReportsView,ReportBarChartView,ReportPieChartView}.swift`.
- Phase 4: `Modules/Settings/{SettingsView,AboutView,HowItWorksView}.swift`, `Modules/TaskManagement/{TaskEditView,DurationPickerView,AlertView,TaskCompletedOverlayView}.swift`, `Modules/MainTabView.swift`.

## Reuse (don't reinvent)
- Existing token homes: `Color+Extensions`, `Font+Extensions`, `Constants` — extend rather than replace.
- `Color.fromTaskColorData(_:)` / `UIColor.fromArchivedData` (from the color cleanup) for all task-color decoding — already centralized.
- Existing animation patterns already in the codebase (`.spring(response:0.4, dampingFraction:0.7)` overlay, `.easeInOut` ring) as a baseline to formalize into `Constants.Motion`.
- `viewModel.taskColor` and `viewModel.progress` for the ring — already exposed.

## Verification

**The unit suite is NOT the redesign safety net** — it covers logic only and runs no view code. Per redesigned screen:

- **Build + screenshot** (light **and** dark) via SwiftUI Previews / simulator; confirm against the chosen direction.
- **Manual interaction matrix** — exercise every state on-device before merge. For the timer specifically, verify each branch of the control-button state machine:
  - running → Pause
  - startable (task selected) → Start enabled; (no task) → Start disabled
  - paused + work session → Resume / Complete Session / Complete Task / Cancel
  - paused + break session → Resume / Skip Break
  - paused + no current task → only a disabled Start
  - task-switching disabled while a session is running
  - For other screens: task-list swipes (complete/edit/delete, both tabs), empty states, report filters/period/units/chart-toggle.
- **Accessibility (explicit, per screen, not a final sanity check):** Dynamic Type at XL doesn't break layout (watch the 64pt countdown and custom cards); sufficient contrast in both modes; VoiceOver labels on icon-only controls (e.g. the help button) and on the custom ring/charts.
- Run the full unit suite (`xcodebuild test … -only-testing:"Done PomodoroTests"`, currently 57) to confirm **logic** didn't regress. CI re-verifies on each PR.
- Keep each phase a separate PR with green CI before merge (matches the established workflow).

## Notes / risks
- App is **portrait-locked** (Info.plist) — design for portrait only.
- **Light + dark fully supported** — every colorset and effect must be verified in both; glass/gradient/glow directions are the hardest to balance across modes, so screenshot both early.
- Preserve the intricate timer control-button state machine verbatim; it's the highest-risk area to restyle and is invisible to CI.
- **Commit work promptly** — never leave prototype or redesign work uncommitted across a branch switch (it has been lost twice this session). Prototypes live on `spike/design-directions`.
- **Token discipline relies on review** (no automated lint added — issue #9 left open). Watch for hardcoded colors/spacing/`.tint(...)` creeping back into `Modules/`; that's the exact problem being fixed.
- New colorsets must avoid generated-symbol collisions (lesson from `PrimaryColor`→`BrandPrimary`).
- SourceKit in this session throws false "Cannot find type / No such module" diagnostics (Task shadowing, cross-file) — `xcodebuild` is the authority, not the live indexer.

## Decisions log (from plan review)
1. Screenshots from SwiftUI Previews with mock data are fine. → Phase 0 / Pre-step 1.
2. Prototype a dense screen (task list) too; tokens provisional through PR2. → Phase 0 / Phase 1.
3. Replace vague manual pass with explicit test matrix; unit suite is not the view safety net. → Verification.
4. Per-screen "Definition of Done" checklist — **deferred** (not now).
5. Commit prototypes to a throwaway branch. → Phase 0 / Notes.
6. Remove the `Done Pomodoro copy` target as a pre-step. → Pre-step 2.
7. Fully support light + dark. → throughout.
8. Accessibility as explicit per-screen criteria. → Verification.
9. CI lint for hardcoded values — **left open** (no decision); relying on review for now.
10. Tokens namespaced under `Constants`. → Phase 1.
11. App icon — **out of scope.**
12. Chart performance check (~30 tasks). → Phase 3.
13. Commit the plan doc. → done on `docs/redesign-plan` branch.
