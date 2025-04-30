//
//  AlertView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/28/25.
//

import SwiftUI

struct AlertView: View {
    let title: String
    let message: String
    let buttonText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: action) {
                Text(buttonText)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 300)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with dark and light mode
        Group {
            AlertView(
                title: "Cannot Edit Active Task",
                message: "This task is currently in an active session. Please wait until the session completes or cancel the session before editing.",
                buttonText: "OK",
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.light)
            
            AlertView(
                title: "Cannot Edit Active Task",
                message: "This task is currently in an active session. Please wait until the session completes or cancel the session before editing.",
                buttonText: "OK",
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
