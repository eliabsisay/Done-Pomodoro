//
//  TaskCompletedOverlayView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 5/2/25.
//

import SwiftUI

/// Reusable overlay view for task completion
struct TaskCompletedOverlayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
            Text("Task Completed!")
                .font(.title2.weight(.semibold))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .transition(.scale.combined(with: .opacity))
    }
}
#Preview {
    TaskCompletedOverlayView()
}
