//
//  UIApplication+Extensions.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 6/8/25.
//

import UIKit

extension UIApplication {
    /// Ends editing across the app, dismissing the keyboard.
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

