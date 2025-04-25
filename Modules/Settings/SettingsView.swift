//
//  SettingsView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//


import SwiftUI

struct SettingsView: View {
    // View model for handling settings logic
    @StateObject private var viewModel = SettingsViewModel()
    
    // Environment object to control dark mode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            // MARK: - Appearance Section
            Section(header: Text("Appearance")) {
                Picker("Appearance Mode", selection: $viewModel.appearanceMode) {
                    Text("System").tag(Constants.AppearanceMode.system)
                    Text("Light").tag(Constants.AppearanceMode.light)
                    Text("Dark").tag(Constants.AppearanceMode.dark)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // MARK: - Behavior Section
            Section(header: Text("Behavior")) {
                Toggle("Prevent Screen Sleep", isOn: $viewModel.preventSleep)
                    .tint(.primaryColor)
            }
            
            // MARK: - Sounds Section
            Section(header: Text("Sounds")) {
                Picker("Work Session Complete", selection: $viewModel.workCompletedSound) {
                    ForEach(viewModel.availableSounds, id: \.self) { sound in
                        Text(sound.capitalized).tag(sound)
                    }
                }
                
                Picker("Break Complete", selection: $viewModel.breakCompletedSound) {
                    ForEach(viewModel.availableSounds, id: \.self) { sound in
                        Text(sound.capitalized).tag(sound)
                    }
                }
            }
            
            // MARK: - About Section
            Section(header: Text("About")) {
                Button(action: {
                    viewModel.requestAppReview()
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Rate the App")
                    }
                }
                
                Button(action: {
                    viewModel.showingAboutSheet = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.primaryColor)
                        Text("About Us")
                    }
                }
                
                Button(action: {
                    viewModel.showingTutorialSheet = true
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.primaryColor)
                        Text("How it Works")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $viewModel.showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $viewModel.showingTutorialSheet) {
            HowItWorksView()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
