//
//  IsometricProjector.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation

// MARK: - Isometric Projector

/// Converts road-style offsets into centered SpriteKit scene points.
///
/// This helper is useful when future systems need consistent isometric math for
/// floor tiles, wall placement, obstacle placement, or treadmill movement.
struct IsometricProjector {

    // MARK: - Configuration

    let viewAngleInDegrees: CGFloat

    // MARK: - Projection

    func project(horizontalOffset: CGFloat, depthOffset: CGFloat, from origin: CGPoint) -> CGPoint {
        let radians = Double(viewAngleInDegrees) * Double.pi / 180
        return CGPoint(
            x: origin.x + horizontalOffset + depthOffset * CGFloat(cos(radians)),
            y: origin.y + depthOffset * CGFloat(sin(radians))
        )
    }
}
