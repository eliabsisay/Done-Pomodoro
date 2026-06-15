//
//  DSButtonStyles.swift
//  Done Pomodoro — Design System
//
//  Reusable Liquid Glass button styles that replace the inline
//  `.borderedProminent` / `.bordered` + hardcoded `.tint(.blue/.green/.red)`
//  scattered through the views. Three roles: primary (the main action, tinted
//  by the current task's color), secondary (neutral glass), and destructive
//  (red-tinted). iOS 26 `glassEffect` — no availability gating needed.
//

import SwiftUI

/// Shared label treatment so all three roles size and animate identically.
private struct DSGlassButton: View {
    let configuration: ButtonStyle.Configuration
    let tint: Color?

    var body: some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.Spacing.lg)
            .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Constants.Motion.snappy, value: configuration.isPressed)
    }
}

/// Primary action — a SUBTLE wash of the current task's color (pass `taskColor`).
/// Faint by design: it ties the main action to the active task while keeping the
/// calm/neutral direction (the saturated color lives in the ring, not the button).
struct DSPrimaryButtonStyle: ButtonStyle {
    var tint: Color?
    func makeBody(configuration: Configuration) -> some View {
        DSGlassButton(configuration: configuration, tint: tint?.opacity(0.32))
    }
}

/// Secondary action — neutral glass, no tint.
struct DSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        DSGlassButton(configuration: configuration, tint: nil)
    }
}

/// Destructive action — red-tinted glass.
struct DSDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        DSGlassButton(configuration: configuration, tint: .red)
    }
}

// Dot-syntax accessors: `.buttonStyle(.dsPrimary(tint: viewModel.taskColor))`.
extension ButtonStyle where Self == DSPrimaryButtonStyle {
    static func dsPrimary(tint: Color? = nil) -> DSPrimaryButtonStyle { .init(tint: tint) }
}
extension ButtonStyle where Self == DSSecondaryButtonStyle {
    static var dsSecondary: DSSecondaryButtonStyle { .init() }
}
extension ButtonStyle where Self == DSDestructiveButtonStyle {
    static var dsDestructive: DSDestructiveButtonStyle { .init() }
}
