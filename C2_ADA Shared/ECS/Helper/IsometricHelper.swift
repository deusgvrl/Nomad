//
//  IsometricHelper.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 11/05/26.
//
import CoreGraphics

struct IsometricHelper {

    // Set ukuran tile
    static let tileWidth:CGFloat = 44.0
    static let tileHeight:CGFloat = 76.0

    // Ubah input koordinat Row & Col (Grid) menjadi posisi Layar (X, Y) untuk atur posisi tilenya.
    static func getScreenPosition(row:Int, col:Int) -> CGPoint {
        let x = CGFloat(col - row) * (tileWidth / 2)
        let y = CGFloat(col + row) * (tileHeight / 2)
        return CGPoint(x: -x, y: y)
    }

    // MARK: - Tile Render Layer
    // Mengatur urutan layer (depth) tile pada tampilan isometric (makin jauh makin dalam).
    static func getTileRenderLayer(row: Int, col: Int) -> CGFloat {
        return CGFloat(-(row + col))
    }
}
