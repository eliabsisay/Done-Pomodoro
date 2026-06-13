# Visual Redesign - Next Session Prompt
**Last updated:** 2026-06-12

---

## Copy/paste this to start your next session:

We're modernizing the visual design of "Done Pomodoro," a native SwiftUI iOS app (currently stock/default-component styling). The redesign plan is finalized and committed; we're at the point of starting execution — the pre-steps and Phase 0 prototypes. Nothing visual has been built yet.

> **Before acting:** Review the "Possible next steps" below with me and ask which item I want to start on (or if there's something else). Don't auto-execute.

**Where we left off:** Finalized `docs/redesign-plan.md` after a critical plan review, folded in all 13 review decisions, and committed it on branch `docs/redesign-plan` (commit `0cf8446`). No redesign code exists yet — we're at the pre-steps.

**Context to read first:**
- `/Users/eliabsisay/Library/CloudStorage/OneDrive-Personal/Done - Pomodoro App/Done-Pomodoro/docs/redesign-plan.md` — the full plan (SwiftUI-first, prototype-and-pick, hero-first 4-PR rollout) with a Decisions log at the bottom. **On branch `docs/redesign-plan`** (= main + this doc). Read this first.
- `/Users/eliabsisay/Library/CloudStorage/OneDrive-Personal/Done - Pomodoro App/Done-Pomodoro/CLAUDE.md` — agent brief: build/run, architecture map, gotchas (`Task` shadowing, `AppEvents`, verbose-comment style), conventions.
- `/Users/eliabsisay/Downloads/Pomodoro_App_Project_Handoff.md` — product/PRD context (optional, deep background).

**Key decisions already made:**
- **Method:** SwiftUI-first; iterate via SwiftUI Previews with mock data + light/dark screenshots. Aesthetic is chosen by prototyping (Phase 0), not by picking adjectives.
- **Rollout:** hero-first, one PR per stage — PR1 design system + Timer · PR2 Task list · PR3 Reports · PR4 secondary screens.
- **Light + dark both fully supported. App icon is out of scope. Design tokens namespaced under `Constants`** (`Constants.Spacing/Elevation/Motion`); colors in `Color+Extensions`.
- **Two pre-steps before Phase 0:** (a) validate the render→screenshot loop with a one-view spike; (b) remove the stray `Done Pomodoro copy` Xcode target (accidental duplicate, no shared scheme — cleanest deleted via Xcode UI: right-click target → Delete).
- **Deferred (not now):** per-screen "Definition of Done" checklist; CI lint for hardcoded styling values. Token discipline currently relies on review.
- **Workflow:** every change is a branch → PR → CI-green → merge. Direct push to `main` is blocked by the permission classifier and we kept it that way so CI gates each change. Git identity + the Xcode MCP (`xcrun mcpbridge`, requires Xcode running) are already configured; start sessions from the repo dir. Config dir is `~/.claude-personal`.
- **Repo:** `/Users/eliabsisay/Library/CloudStorage/OneDrive-Personal/Done - Pomodoro App/Done-Pomodoro`. `main` has PRs #12–#17 merged (test suite, CI, sort persistence, color/deprecation cleanup, notification sounds); **57 unit tests green**. Tests cover logic only — they do NOT catch view regressions.

**Possible next steps (review with PM before starting):**
1. **Pre-step 2:** remove the stray `Done Pomodoro copy` target (Xcode UI).
2. **Pre-step 1:** validate the screenshot loop with a one-view spike (render a trivial view, capture light + dark).
3. **Phase 0:** build 2–3 direction prototypes of the **Timer and Task-list** screens as SwiftUI Previews with mock data; screenshot light + dark; present for the pick. Commit to a `spike/design-directions` branch.
4. Open a PR to merge `docs/redesign-plan` into `main` so the plan lives on main.

**Open questions / what the PM needs to bring:**
- Any reference apps / inspiration for the look would sharpen the Phase 0 prototypes (optional but helpful).
- Whether to revisit the two deferred items: per-screen Definition of Done, and a CI lint for hardcoded styling values.
