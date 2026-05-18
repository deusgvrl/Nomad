//
//  ZPosition.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics

// MARK: - Z Position

/// Shared SpriteKit draw layers.
///
/// Higher numbers render above lower numbers. Keeping them here avoids random
/// zPosition values throughout the scene.
enum ZPosition {
    // MARK: - World Layers

    static let floor: CGFloat = 10
    static let leftWall: CGFloat = 20
    static let vehicle: CGFloat = 40
    static let player: CGFloat = 45
    static let rightWall: CGFloat = 100
    static let obstacle: CGFloat = 150

    // MARK: - UI Layers

    static let overlay: CGFloat = 100
    static let gameOverOverlay: CGFloat = 200
}
