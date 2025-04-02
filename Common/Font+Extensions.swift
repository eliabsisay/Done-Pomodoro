//
//  Font+Extensions.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/1/25.
//

import Foundation
import SwiftUI

/// Reusable font styles for consistent typography across the app.
extension Font {
    
    // Headings
    static let headingXL = Font.system(size: 34, weight: .bold, design: .monospaced )
    static let headingL = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headingM = Font.system(size: 22, weight: .semibold, design: .rounded)

    // Body text
    static let bodyRegular = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .bold, design: .default)
    
    // Captions & footnotes
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let footnote = Font.system(size: 11, weight: .light, design: .default)
}
