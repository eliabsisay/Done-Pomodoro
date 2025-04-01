//
//  Done_PomodoroApp.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 3/31/25.
//

import SwiftUI

@main
struct Done_PomodoroApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
