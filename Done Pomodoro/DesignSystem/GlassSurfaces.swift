//
//  GlassSurfaces.swift
//  Done Pomodoro — Design System
//
//  The surface layer for the "Calm Glass · Neutral + task-accent" redesign:
//  a calm neutral app background with a subtle accent bloom (subtle depth), and
//  a reusable Liquid Glass card. Uses the real iOS 26 `glassEffect` API — the
//  app's minimum is iOS 26, so no availability gating is needed.
//

import SwiftUI

// MARK: - App background

/// Calm neutral base + one soft, low-opacity bloom tinted by `accent` (usually
/// the current task's color). Deliberately restrained — depth as a whisper, not
/// a gradient mesh. Apply to a screen's root container.
struct AppBackground: ViewModifier {
    var accent: Color
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                Color.surfaceBackground
                GeometryReader { geo in
                    Circle()
                        .fill(accent)
                        .frame(width: geo.size.width * 1.15)
                        .blur(radius: 130)
                        .opacity(scheme == .dark ? 0.16 : 0.10)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.30)
                }
            }
            .ignoresSafeArea()
        )
    }
}

// MARK: - Glass card

/// Wraps content in a Liquid Glass surface with a rounded-rect shape. Pad the
/// content first, then apply: `someView.padding(.lg).glassCard()`.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content.glassEffect(
            .regular,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
}

extension View {
    /// Calm neutral screen background with an optional accent bloom.
    func appBackground(accent: Color = .clear) -> some View {
        modifier(AppBackground(accent: accent))
    }

    /// Liquid Glass card surface (default radius = `Constants.Radius.md`).
    func glassCard(cornerRadius: CGFloat = Constants.Radius.md) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
