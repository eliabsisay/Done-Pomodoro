//
//  TimerRingView.swift
//  Done Pomodoro — Design System
//
//  The redesigned timer ring: a THIN gradient ring with a GENTLE glow, built
//  from the current task's color (the only chromatic accent in this neutral
//  direction). Driven by the same inputs as before — `progress` (elapsed
//  fraction, 0…1) and the task `color` — so it's a drop-in for the old inline
//  ZStack of two Circles in WorkSessionView. Behavior preserved: the ring trims
//  from full down to empty as `progress` rises (`trim(0, 1 - progress)`).
//

import SwiftUI

struct TimerRingView: View {
    /// Elapsed fraction, 0 (just started) … 1 (done). Matches `viewModel.progress`.
    var progress: CGFloat
    /// The current task's color (`viewModel.taskColor`).
    var color: Color
    var lineWidth: CGFloat = 9

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        // Subtle two-stop gradient from the same hue reads as a soft glow sweep.
        let stops = [color.opacity(0.55), color]

        ZStack {
            // Track — faint neutral, not the brand/track color of the old ring.
            Circle()
                .stroke(Color.primary.opacity(scheme == .dark ? 0.12 : 0.09),
                        lineWidth: lineWidth)

            // Progress — remaining time, thin gradient stroke + gentle glow.
            Circle()
                .trim(from: 0, to: 1 - progress)
                .stroke(
                    AngularGradient(colors: stops + [stops[0]], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 9)
                .animation(Constants.Motion.gentle, value: progress)
        }
    }
}
