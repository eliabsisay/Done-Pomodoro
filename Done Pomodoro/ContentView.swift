//
//  ContentView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 3/31/25.
//
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Pomodoro Timer")
                    .font(.largeTitle)
                Text("App is being set up...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Pomodoro Timer")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
