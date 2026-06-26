//
//  ColorHelper.swift
//  C2_ADA Shared
//

import SpriteKit

enum ColorHelper {
    /// Mengonversi nilai Hex integer (misal: 0xF6A74C) menjadi SKColor.
    static func fromHex(_ hex: Int, alpha: CGFloat = 1.0) -> SKColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        return SKColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
