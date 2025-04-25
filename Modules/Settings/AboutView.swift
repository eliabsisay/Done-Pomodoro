//
//  AboutView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct AboutView: View {
    // Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                // App logo
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryColor)
                    .padding(.top, 40)
                
                // App name
                Text("Done Pomodoro")
                    .font(.headingL)
                
                // App version
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 5)
                
                // App description
                VStack(alignment: .leading, spacing: 15) {
                    descriptionSection(
                        icon: "brain",
                        title: "About Done",
                        description: "Done is an intuitive Pomodoro timer app designed to help you boost productivity through structured work intervals and scheduled breaks."
                    )
                    
                    descriptionSection(
                        icon: "chart.bar",
                        title: "Our Mission",
                        description: "We believe in creating simple tools that respect your time and attention. Done works completely offline with no distractions, helping you focus on what matters most."
                    )
                    
                    descriptionSection(
                        icon: "gear",
                        title: "Privacy",
                        description: "Done operates fully offline. All your task data and settings are stored locally on your device. We collect no data and have no access to your usage patterns or personal information."
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Copyright
                Text("© 2025 Eliab Sisay. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .padding()
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
    
    // Helper function to create consistent description sections
    private func descriptionSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 30)
                .foregroundColor(.primaryColor)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.bodyBold)
                
                Text(description)
                    .font(.bodyRegular)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
