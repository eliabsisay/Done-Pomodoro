//
//  HowItWorksView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct HowItWorksView: View {
    // Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    // State to track which step is currently being viewed
    @State private var currentStep = 0
    
    // Define the tutorial steps
    private let steps = [
        // About step (first step merged from AboutView)
        TutorialStep(
            title: "Done Pomodoro",
            description: "A simple, effective productivity tool designed to help you focus better and get more Done.",
            icon: "timer",
            // Additional content specific to the first step
            features: [
                Feature(icon: "brain", title: "Focus Your Mind",
                        description: "Done helps you break work into focused sessions with dedicated breaks to maximize productivity."),
                Feature(icon: "chart.bar", title: "Track Your Progress",
                        description: "Monitor your productivity with detailed reports and analytics on completed tasks and sessions."),
                Feature(icon: "gear", title: "Customize Your Flow",
                        description: "Personalize work durations, break lengths, and notification preferences to match your work style.")
            ]
        ),
        // Original steps from HowItWorksView
       
        TutorialStep(
            title: "Step 1: Choose a Task",
            description: "Select a task you want to work on from your task list, or create a new one with custom work and break durations.",
            icon: "checklist"
        ),
        TutorialStep(
            title: "Step 2: Work Session",
            description: "Start the timer and focus solely on your task until the timer rings. Avoid all distractions during this period.",
            icon: "brain.head.profile"
        ),
        TutorialStep(
            title: "Step 3: Take a Break",
            description: "When the work session ends, take a short break (typically 5 minutes) to rest and recharge before starting the next session.",
            icon: "cup.and.saucer"
        ),
        TutorialStep(
            title: "Step 4: Repeat",
            description: "After completing a set number of work sessions (typically 4), take a longer break (15-30 minutes) before continuing with more sessions.",
            icon: "arrow.triangle.2.circlepath"
        ),
        TutorialStep(
            title: "Step 5: Customize Your Experience",
            description: "Adjust your notification sounds, appearance preferences, and task-specific settings to make Done work perfectly for your workflow.",
            icon: "gear"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? Color.primaryColor : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top)
                
                Spacer()
                
                // Current step content
                if currentStep == 0 {
                    // About view content
                    aboutContent
                } else {
                    // Regular tutorial step content
                    VStack(spacing: 30) {
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 70))
                            .foregroundColor(.primaryColor)
                        
                        Text(steps[currentStep].title)
                            .font(.headingM)
                            .multilineTextAlignment(.center)
                        
                        Text(steps[currentStep].description)
                            .font(.bodyRegular)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Previous")
                            }
                            .padding()
                            .foregroundColor(.primaryColor)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .foregroundColor(.primaryColor)
                        }
                    } else {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Got it!")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.primaryColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarItems(
                trailing: Button("Skip") {
                    dismiss()
                }
            )
        }
    }
    
    // About view content extracted from AboutView.swift
    private var aboutContent: some View {
        VStack(alignment: .center, spacing: 20) {
            // App icon and name
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 50))
                    .foregroundColor(.primaryColor)
                
                VStack(alignment: .leading) {
                    Text("Done Pomodoro")
                        .font(.headingL)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 30)
            
            Spacer().frame(height: 10)
            
            // App description
            Text(steps[0].description)
                .font(.bodyRegular)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer().frame(height: 10)
            
            // Features from AboutView
            VStack(alignment: .leading, spacing: 12) {
                if let features = steps[0].features {
                    ForEach(features, id: \.title) { feature in
                        featureRow(feature: feature)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // Helper function to create feature rows
    private func featureRow(feature: Feature) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: feature.icon)
                .font(.headline)
                .frame(width: 24)
                .foregroundColor(.primaryColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.bodyBold)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Helper struct to define tutorial steps
struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    var features: [Feature]? = nil
}

// Helper struct for features shown in the about screen
struct Feature {
    let icon: String
    let title: String
    let description: String
}

struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        HowItWorksView()
    }
}
