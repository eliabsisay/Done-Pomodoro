//  MainTabView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var tabSwitchObserver: NSObjectProtocol? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                WorkSessionView()
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }
            .tag(0)
            
            NavigationView {
                TaskListView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(1)  // Add a tag
            
            NavigationView {
                ReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.bar")
            }
            .tag(2)  // Add a tag
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)  // Add a tag
        }
        .onAppear {
            // Create the observer once and store it
            if tabSwitchObserver == nil {
                tabSwitchObserver = NotificationCenter.default.addObserver(
                    forName: Notification.Name("SwitchToTimerTab"),
                    object: nil,
                    queue: .main
                ) { _ in
                    selectedTab = 0 // Switch to Timer tab
                    print("🔄 Switching to Timer tab")
                }
            }
        }
        .onDisappear {
            // Clean up the observer if the view disappears
            if let observer = tabSwitchObserver {
                NotificationCenter.default.removeObserver(observer)
                tabSwitchObserver = nil
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
