# Visual Redesign - Next Session Prompt
**Last updated:** 2026-06-14 (after PR1 build)

---

## Copy/paste this to start your next session:

We're modernizing the visual design of "Done Pomodoro," a native SwiftUI iOS app. The plan, pre-steps, Phase 0 (direction pick), and **PR1 (design system + Timer)** are done and CI-green. We paused **mid on-device verification of PR1**.

> **Before acting:** Pick up the on-device verification of PR1 (timer state matrix + light mode) and review with me whether to merge **PR #22**, or move on. Don't auto-execute.

**Where we left off:** PR1 is built, pushed, and **CI-green as PR #22** (branch `feature/redesign-pr1-design-system-timer`). I was verifying it on my **physical iPhone** (device signing is now set up — Apple ID added, dev cert created). Still to confirm before merging #22:
- **Light mode** on device (the simulator wouldn't render the app in light — a trait quirk; I confirmed light works on device, just hadn't eyeballed the redesign in light yet).
- The full **timer control-button state matrix**: running→Pause; paused·work → Resume / Complete Session / Complete Task / Cancel; paused·break → Resume / Skip Break; complete-task → success overlay → "pick a task"; task chip locked while running; "?" sheet. Behavior must match pre-redesign exactly (PR1 was restyle-only).

**Chosen direction (locked):** **"Calm Glass · Neutral + task-accent"** — a calm, restrained take on **iOS 26 Liquid Glass**: translucent glass surfaces + a thin gradient ring with a gentle glow, spacious layouts, both modes equal, subtle depth. Near-neutral glass where **each task's own color is the accent** (`taskColor` / `Color.fromTaskColorData`). SF Rounded; no serif. Primary button = a **subtle** (0.32-opacity) task-color glass wash.

**Context to read first:**
- `docs/redesign-plan.md` — full plan + "Status — 2026-06-14" section + Decisions log. On `main`.
- `CLAUDE.md` — agent brief. **Correction:** its "synchronized groups auto-add files" claim is only true for `Done Pomodoro/`, `Done PomodoroTests/`, `Done PomodoroUITests/`. `Common/`, `Modules/`, etc. are **regular groups** — new app-target files must go under `Done Pomodoro/...` (that's why the design system lives in `Done Pomodoro/DesignSystem/`, not `Common/DesignSystem/`).
- PR1 code (on the `feature/redesign-pr1-design-system-timer` branch / PR #22):
  - `Common/Constants.swift` — `Spacing` / `Radius` / `Elevation` / `Motion` tokens.
  - `Common/Color+Extensions.swift` + `SurfaceBackground` colorset — `surfaceBackground` (auto-generated symbol; don't redeclare), `textPrimary/Secondary`.
  - `Done Pomodoro/DesignSystem/{GlassSurfaces,DSButtonStyles,TimerRingView}.swift` — `.appBackground()`, `.glassCard()`, DS button styles, ring.
  - `Modules/Timer/WorkSessionView.swift` — restyled timer (bindings + state machine preserved verbatim).

**Key state / decisions already made:**
- **Minimum is now iOS 26** (raised from 18.2, PR #21) for true Liquid Glass `glassEffect`. Dropped iOS 18–25. CI selects newest Xcode + an iOS-26 sim (works on GitHub `macos-15`).
- **CI design-lint** (`scripts/design-lint.sh`) is **advisory now → FLIP TO BLOCKING at PR2** (set `DESIGN_LINT_BLOCKING: "true"` in `.github/workflows/ci.yml`). Baseline is content-keyed; refresh it (`--update-baseline`) as each screen is cleaned (currently **23** entries, down from 28 after the Timer).
- **Tooling gotchas:** `ImageRenderer` cannot render Liquid Glass (errors out) or `ScrollView` — capture real glass via the **simulator** (`xcrun simctl io booted screenshot`). The sim wouldn't show the app in light mode (trait quirk); light works on device.
- Throwaway Phase-0 prototypes on `spike/design-directions` (`DDCalmGlass.swift`, winning variant `.neutralAccent`); screenshot-loop spike on `spike/screenshot-loop`.
- Workflow: branch → PR → CI-green → merge; direct push to `main` is blocked. Start sessions from the repo dir; Xcode MCP needs Xcode running.

**Possible next steps (review with me before starting):**
1. Finish **on-device verification of PR1** and **merge #22**.
2. **PR2 — Task management:** redesign `TaskListView` / `TaskRowView` / `ToDoListView` / `DoneListView` onto the system (custom glass row cells with color dot + active-timer indicator + durations, the To-Do/Done segmented control, the Add button, swipe actions, empty states). **Harden the provisional Phase-1 tokens against this dense layout and lock the system here.** Preserve all `TaskListViewModel` bindings (incl. sort persistence and `taskColor` decode). **Flip design-lint to blocking.**
3. Then PR3 (Reports), PR4 (secondary screens + tab bar — still default-styled).

**Open questions:**
- Any tweaks to the Timer from the on-device pass (glass contrast, ring weight, button feel) before PR2.
- The app's tab bar is still stock — confirm it's in scope for PR4 (it is, per the plan).
