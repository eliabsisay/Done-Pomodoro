//
//  TimerInterval+Extensions.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/10/25.
//

import Foundation
import SwiftUI

extension TimeInterval {
    /// Formats the time interval as a MM:SS countdown string.
    var formattedAsTimer: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

