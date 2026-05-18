//
//  GameConfiguration.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation

// MARK: - Game Configuration

/// Central tuning values for the movement prototype.
///
/// Keeping these numbers here makes the scene easier to adjust without hunting
/// through systems. When the real art arrives, most placement changes should
/// happen in this file first.
struct GameConfiguration {

    // MARK: - Standard Prototype Values

    static let standard = GameConfiguration(
        // iPhone 17 portrait reference size in points.
        referenceScreenSize: CGSize(width: 402, height: 874),
        // Middle third reference from the early control plan.
        playableWidthFraction: 1.0 / 3.0,
        // Visual road angle used for the isometric road direction.
        isometricViewAngleInDegrees: 60,
        // Shallow white guide line angle from the hi-fi grid prototype.
        // This is separate from the 60-degree isometric road/art angle.
        movementAxisAngleInDegrees: 16,
        // Rough canyon/wall limits measured from the hi-fi grid prototype.
        // These are offsets from `currentVehiclePosition` along the movement axis.
        movementAxisXOffsetBounds: -55...265,
        showsMovementBoundsGuide: false,
        dragSensitivity: 1.0,
        // Width of the gray road band. Movement clamps inside this width.
        roadWidth: 380,
        // Bottom-center x location of the road before projecting forward.
        roadBottomCenterXPosition: -212,
        // First playable vehicle slot from the lo-fi reference.
        currentVehiclePosition: CGPoint(x: -115, y: -170),
        obstaclePositions: [
            CGPoint(x: 45, y: 125),
            CGPoint(x: 130, y: -20),
            CGPoint(x: -95, y: -360)
        ],
        // The car is back to the earlier movement-prototype size, while the
        // player is larger so the rider reads clearly on top of the vehicle.
        playerRideOffset: CGVector(dx: -12, dy: 6),
        vehicleSize: CGSize(width: 104, height: 104),
        playerSize: CGSize(width: 52, height: 84),
        obstacleSize: CGSize(width: 36, height: 92),
        launchForwardAngleInDegrees: 60,
        launchVelocity: 360,
        launchForwardThrust: 180,
        launchGravity: 920,
        latchDistance: 52,
        groundYPosition: -345,
        maximumDeltaTime: 1.0 / 30.0
    )

    // MARK: - Screen And Road

    let referenceScreenSize: CGSize
    let playableWidthFraction: CGFloat
    let isometricViewAngleInDegrees: CGFloat
    let movementAxisAngleInDegrees: CGFloat
    let movementAxisXOffsetBounds: ClosedRange<CGFloat>
    let showsMovementBoundsGuide: Bool
    let dragSensitivity: CGFloat
    let roadWidth: CGFloat
    let roadBottomCenterXPosition: CGFloat

    // MARK: - Entity Placement

    let currentVehiclePosition: CGPoint
    let obstaclePositions: [CGPoint]
    let playerRideOffset: CGVector
    let vehicleSize: CGSize
    let playerSize: CGSize
    let obstacleSize: CGSize

    // MARK: - Launch And Latch

    let launchForwardAngleInDegrees: CGFloat
    let launchVelocity: CGFloat
    let launchForwardThrust: CGFloat
    let launchGravity: CGFloat
    let latchDistance: CGFloat
    let groundYPosition: CGFloat
    let maximumDeltaTime: TimeInterval

    // MARK: - Derived Bounds

    var playableXBounds: ClosedRange<CGFloat> {
        let halfPlayableWidth = referenceScreenSize.width * playableWidthFraction / 2
        return -halfPlayableWidth...halfPlayableWidth
    }

    /// Bottom-center point of the road in the centered SpriteKit scene.
    var roadStartCenterPosition: CGPoint {
        CGPoint(
            x: roadBottomCenterXPosition,
            y: -referenceScreenSize.height / 2
        )
    }

    /// SpriteKit-space slope for the shallow movement line.
    ///
    /// Positive screen degrees tilt visually down to the right, while SpriteKit
    /// uses positive Y upward, so the stored slope is negative.
    var movementAxisSlope: CGFloat {
        let radians = Double(movementAxisAngleInDegrees) * Double.pi / 180
        return -CGFloat(tan(radians))
    }

    func movementAxisPosition(xOffset: CGFloat) -> CGPoint {
        CGPoint(
            x: currentVehiclePosition.x + xOffset,
            y: currentVehiclePosition.y + xOffset * movementAxisSlope
        )
    }

    var movementAxisStartPosition: CGPoint {
        movementAxisPosition(xOffset: movementAxisXOffsetBounds.lowerBound)
    }

    var movementAxisEndPosition: CGPoint {
        movementAxisPosition(xOffset: movementAxisXOffsetBounds.upperBound)
    }
}
