//
//  ColorArchiveTests.swift
//  Done PomodoroTests
//
//  Tests for the centralized task-color archive/unarchive helpers in
//  Color+Extensions. The most important guarantee here is BACKWARD
//  COMPATIBILITY: data written by the old deprecated path must still decode
//  with the new `unarchivedObject(ofClass:from:)`-based reader, so existing
//  users' stored task colors are not silently lost.
//

import XCTest
import SwiftUI
import UIKit
@testable import Done_Pomodoro

final class ColorArchiveTests: XCTestCase {

    // MARK: - Helpers

    /// Extracts RGBA components for tolerant comparison (avoids color-space
    /// equality pitfalls with `UIColor ==`).
    private func rgba(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    private func assertSameColor(_ lhs: UIColor, _ rhs: UIColor,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let (r1, g1, b1, a1) = rgba(lhs)
        let (r2, g2, b2, a2) = rgba(rhs)
        XCTAssertEqual(r1, r2, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(g1, g2, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(b1, b2, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(a1, a2, accuracy: 0.001, file: file, line: line)
    }

    // MARK: - Backward Compatibility (the critical case)

    func testNewDecoderReadsDataWrittenByOldArchiverPath() throws {
        let original = UIColor.systemOrange

        // 🗄 Exactly how the app wrote task colors before this refactor.
        let legacyData = try NSKeyedArchiver.archivedData(withRootObject: original,
                                                          requiringSecureCoding: false)

        // 🔓 The new, non-deprecated reader must still decode it.
        let decoded = try XCTUnwrap(UIColor.fromArchivedData(legacyData),
                                    "Legacy-archived color data must still decode")
        assertSameColor(original, decoded)
    }

    // MARK: - Round Trip Through the Helpers

    func testUIColorArchiveRoundTrip() throws {
        let original = UIColor.systemBlue
        let data = try XCTUnwrap(original.archivedData())
        let decoded = try XCTUnwrap(UIColor.fromArchivedData(data))
        assertSameColor(original, decoded)
    }

    func testColorTaskDataRoundTrip() throws {
        // Color → Data → Color, comparing at the UIColor level.
        let data = try XCTUnwrap(Color.red.taskColorData())
        let decoded = try XCTUnwrap(UIColor.fromArchivedData(data))
        assertSameColor(UIColor(Color.red), decoded)
    }

    // MARK: - Fallback Behavior

    func testFromTaskColorDataReturnsFallbackForNil() {
        let result = Color.fromTaskColorData(nil, fallback: .secondaryColor)
        XCTAssertEqual(result, Color.secondaryColor)
    }

    func testFromTaskColorDataReturnsFallbackForGarbageData() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        let result = Color.fromTaskColorData(garbage, fallback: .secondaryColor)
        XCTAssertEqual(result, Color.secondaryColor)
    }

    func testFromTaskColorDataDefaultFallbackIsPrimary() {
        XCTAssertEqual(Color.fromTaskColorData(nil), Color.primaryColor)
    }

    func testFromArchivedDataReturnsNilForNil() {
        XCTAssertNil(UIColor.fromArchivedData(nil))
    }

    func testFromArchivedDataReturnsNilForGarbage() {
        XCTAssertNil(UIColor.fromArchivedData(Data([0xDE, 0xAD, 0xBE, 0xEF])))
    }
}
