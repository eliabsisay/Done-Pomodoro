//
//  MainTabView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                WorkSessionView()
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }
            
            NavigationView {
                TaskListView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
