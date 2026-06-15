# Visual Redesign - Next Session Prompt
**Last updated:** 2026-06-14

---

## Copy/paste this to start your next session:

We're modernizing the visual design of "Done Pomodoro," a native SwiftUI iOS app (currently stock/default-component styling). The plan, all pre-steps, and Phase 0 (direction pick) are **done**. The next stage is **PR1 — design system foundation + Timer screen**.

> **Before acting:** PR1 carries a gating decision — adopting true iOS 26 Liquid Glass means raising the minimum deployment target **18.2 → 26** (drops iOS 18–25 users) and needing an iOS 26 simulator in CI. Get my explicit go/no-go on that before writing PR1 code. Don't auto-execute.

**Where we left off:** Completed the pre-steps and a two-round Phase 0 prototype-and-pick. **Chosen direction: "Calm Glass · Neutral + task-accent"** — a calm, restrained take on **Apple's iOS 26 Liquid Glass**: translucent glass surfaces + a **thin** gradient ring with a **gentle** glow, spacious layouts, **both light & dark first-class**, subtle depth. The winning palette is **near-neutral glass where each task's own color is the only accent** (drives ring / dots / highlights — maps onto the existing `taskColor` / `Color.fromTaskColorData`). **SF Rounded** type; serif rejected.

**Context to read first:**
- `docs/redesign-plan.md` — the full plan + a **"Status — 2026-06-14"** section and Decisions log (now on `main`). Read this first.
- `CLAUDE.md` — agent brief: build/run, architecture map, gotchas (`Task` shadowing, `AppEvents`, verbose-comment style), conventions.
- Branch **`spike/design-directions`** — throwaway Phase-0 prototypes (test target, mock data): `DDCalmGlass.swift` (the winning skeleton + 4 palettes), `DDMockData.swift`, `DDRenderTests.swift`, and the renders in `__DDRenders__/`. The winning look is the `.neutralAccent` variant.
- `~/Downloads/Pomodoro_App_Project_Handoff.md` — product/PRD context (optional, deep background).

**Key decisions already made:**
- **Direction locked:** Calm Glass · Neutral + task-accent (see above). Graduate the `DDCalmGlass` neutral skeleton into a real `Common/DesignSystem/` + tokens, using native `glassEffect` instead of the prototype's approximated translucent fills.
- **iOS 26 Liquid Glass adopted** → PR1 raises `IPHONEOS_DEPLOYMENT_TARGET` 18.2 → 26. Tradeoff: drops iOS 18–25. Confirm before building; verify CI has an iOS 26 sim.
- **Method:** SwiftUI-first; iterate via SwiftUI Previews + light/dark screenshots. `ImageRenderer` can't render `ScrollView` or composite real glass — capture true Liquid Glass via the simulator.
- **Rollout:** hero-first, one PR per stage — PR1 design system + Timer · PR2 Task list · PR3 Reports · PR4 secondary screens. Tokens namespaced under `Constants` (`Constants.Spacing/Elevation/Motion`); colors in `Color+Extensions`. App icon out of scope.
- **CI design-lint shipped** (`scripts/design-lint.sh`, PR #19) — flags hardcoded styling values in `Modules/` against a baseline. **Advisory now; flip to blocking at PR2.** Per-screen "Definition of Done" checklist still deferred.
- **Workflow:** every change is a branch → PR → CI-green → merge. Direct push to `main` is blocked (CI gates each change). Git identity + the Xcode MCP (`xcrun mcpbridge`, requires Xcode running) configured; start sessions from the repo dir. Config dir is `~/.claude-personal`.
- **Repo:** `/Users/eliabsisay/Library/CloudStorage/OneDrive-Personal/Done - Pomodoro App/Done-Pomodoro`. `main` has the redesign pre-steps merged (#18 stray-target removal, #19 design-lint) + the plan doc (#20). **57 unit tests green**; they cover logic only — they do NOT catch view regressions.

**Possible next steps (review with me before starting):**
1. **Confirm the iOS 26 / deployment-target raise** (gates everything below).
2. **PR1 — Design system foundation:** port the Calm Glass neutral skeleton into `Common/DesignSystem/` (glass card modifier, button styles, `TimerRingView`) + tokens (`Constants.Spacing/Elevation/Motion`, semantic colors), using native `glassEffect`.
3. **PR1 — Timer screen:** redesign `WorkSessionView` on the new system, preserving every `viewModel` binding and the control-button state machine verbatim.
4. Verify on the iOS 26 simulator (light + dark, Dynamic Type, the full timer state matrix) before opening the PR.

**Open questions / what the PM needs to bring:**
- Final go/no-go on dropping iOS 18–25 (the deployment-target raise for true Liquid Glass).
- Whether to keep `glassEffect` everywhere or reserve it for hero surfaces (perf on the dense task list, checked in PR2).
