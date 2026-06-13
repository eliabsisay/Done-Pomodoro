//
//  Color+Extensions.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/1/25.
//

import Foundation
import SwiftUI
import UIKit

/// Easy access to custom color assets using dot syntax.
extension Color {
    static let primaryColor = Color("BrandPrimary")
    static let secondaryColor = Color("BrandSecondary")
    static let accentColor = Color("AccentColor")
    static let backgroundColor = Color("BackgroundColor")
    static let textColor = Color("TextColor")
}

// MARK: - Task Color Archiving

/// Task colors are stored in Core Data as an archived `UIColor` (Binary Data).
/// These helpers are the single, non-deprecated home for that encode/decode —
/// previously the unarchiving logic was duplicated across five views and used
/// the deprecated `unarchiveTopLevelObjectWithData` API.
extension UIColor {

    /// Decodes archived task-color `Data` into a `UIColor`.
    /// Returns `nil` when the data is missing or can't be decoded.
    /// Uses the modern secure unarchiver, which still reads data written by the
    /// old `archivedData(withRootObject:requiringSecureCoding:false)` path.
    static func fromArchivedData(_ data: Data?) -> UIColor? {
        guard let data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
    }

    /// Archives this color to `Data` for Core Data storage.
    func archivedData() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
}

extension Color {

    /// Builds a SwiftUI `Color` from a task's archived color `Data`,
    /// falling back to `fallback` when the data is missing or undecodable.
    static func fromTaskColorData(_ data: Data?, fallback: Color = .primaryColor) -> Color {
        guard let uiColor = UIColor.fromArchivedData(data) else { return fallback }
        return Color(uiColor)
    }

    /// Archives this color to task-color `Data` for storage.
    func taskColorData() -> Data? {
        UIColor(self).archivedData()
    }
}
