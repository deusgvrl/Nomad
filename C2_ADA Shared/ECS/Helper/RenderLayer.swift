//
//  RenderLayer.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 20/05/26.
//

import CoreGraphics

// MARK: - Render Layer

/// Shared SpriteKit draw-order layers for gameplay and UI.
///
/// `RenderLayer` replaces the older `ZPosition` name because the purpose is to
/// decide which objects render above others. The numeric values are unchanged
/// so floor, walls, vehicles, player, obstacles, and overlays keep their order.
enum RenderLayer {

    // MARK: - World Layers

    static let floor: CGFloat = 10
    static let leftWall: CGFloat = 20
    static let vehicle: CGFloat = 40
    static let player: CGFloat = 45
    static let rightWall: CGFloat = 100
    static let obstacle: CGFloat = 150

    // MARK: - UI Layers

    static let overlay: CGFloat = 100
    static let hud: CGFloat = 180
    static let pauseOverlay: CGFloat = 190
    static let gameOverOverlay: CGFloat = 200
}
