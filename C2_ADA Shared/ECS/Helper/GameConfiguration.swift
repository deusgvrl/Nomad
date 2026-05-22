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
        movementAxisXOffsetBounds: -55...305,
        showsMovementBoundsGuide: false,
        dragSensitivity: 1.0,
        // Width of the gray road band. Movement clamps inside this width.
        roadWidth: 380,
        // Bottom-center x location of the road before projecting forward.
        roadBottomCenterXPosition: -212,
        // First playable vehicle slot from the lo-fi reference.
        currentVehiclePosition: CGPoint(x: -115, y: -70),
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
        // MARK: Game Typography
        // Primary typeface for major whole-game display text.
        primaryFontName: "GreatLakesNF",
        // Secondary typeface for supporting whole-game labels and buttons.
        secondaryFontName: "Estandar-Regular",
        // MARK: Forward Jump
        // The player jump position follows this road-forward lane angle as a
        // straight line; the sprite animation supplies the jump-height illusion.
        launchForwardAngleInDegrees: 60,
        launchVelocity: 320,
        launchForwardThrust: 50,
        launchGravity: 1100,
        latchDistance: 52,
        groundYPosition: -280,
        maximumDeltaTime: 1.0 / 30.0,
        // MARK: Distance Scoring
        // Final distance counter speed used by the in-game HUD and the Game
        // Over score result. 30 m/s is about 108 km/h, which reads much closer
        // to a fast vehicle than the earlier placeholder rocket-speed value.
        distanceMetersPerSecond: 30,
        // Jump forward distance is projected through the 60-degree road angle.
        // Keeping this compact stops missed jumps from gliding too far ahead.
        jumpForwardDistance: 50,
        // Slower lane travel gives the player more readable time to latch.
        jumpForwardDuration: 0.85,
        playerFallSettleDuration: 0.18,
        // Try Again is scaled from the imported wooden-button asset while
        // preserving its wide aspect ratio from the design reference.
        gameOverTryAgainButtonSize: CGSize(width: 300, height: 140)
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

    // MARK: - Game Typography

    // MARK: Primary Typeface
    /// Main display font for large game-wide headings, scores, and branded UI.
    let primaryFontName: String

    // MARK: Secondary Typeface
    /// Supporting font for smaller game-wide labels, helper text, and buttons.
    let secondaryFontName: String

    // MARK: - Launch And Latch

    /// Road-forward direction used by linear player jumps and failed-latch falls.
    let launchForwardAngleInDegrees: CGFloat
    /// Legacy prototype tuning kept for compatibility with older tuning passes.
    let launchVelocity: CGFloat
    /// Legacy prototype thrust kept for compatibility with older tuning passes.
    let launchForwardThrust: CGFloat
    /// Legacy prototype gravity kept for compatibility with older tuning passes.
    let launchGravity: CGFloat
    let latchDistance: CGFloat
    let groundYPosition: CGFloat
    let maximumDeltaTime: TimeInterval

    // MARK: - Distance Scoring

    /// Meters added every second while the run is actively playing.
    let distanceMetersPerSecond: CGFloat

    // MARK: - Game Over Prototype

    let jumpForwardDistance: CGFloat
    let jumpForwardDuration: TimeInterval
    let playerFallSettleDuration: TimeInterval
    let gameOverTryAgainButtonSize: CGSize

    // MARK: - Derived Bounds

    var playableXBounds: ClosedRange<CGFloat> {
        let halfPlayableWidth = referenceScreenSize.width * playableWidthFraction / 2
        return -halfPlayableWidth...halfPlayableWidth
    }

    /// Size used only for movement clamping.
    ///
    /// `CAR IDLE` has transparent padding around the visible vehicle, so using
    /// the full sprite size stops the car too early near the phone edge.
    var vehicleMovementBoundsSize: CGSize {
        CGSize(width: vehicleSize.width * 0.55, height: vehicleSize.height)
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

    // MARK: - Jump Forward Line

    /// Unit vector for the 60-degree road-forward jump direction.
    ///
    /// SpriteKit uses positive Y upward, so this projects the player up-right
    /// along the road instead of along the shallow steering line.
    var jumpForwardUnitVector: CGVector {
        let radians = Double(launchForwardAngleInDegrees) * Double.pi / 180
        return CGVector(
            dx: CGFloat(cos(radians)),
            dy: CGFloat(sin(radians))
        )
    }

    /// Target point for failed jumps, derived from the linear 60-degree road
    /// direction so the player lands in front instead of drifting sideways.
    func jumpForwardLandingPosition(from startPosition: CGPoint) -> CGPoint {
        CGPoint(
            x: startPosition.x + jumpForwardUnitVector.dx * jumpForwardDistance,
            y: startPosition.y + jumpForwardUnitVector.dy * jumpForwardDistance
        )
    }
}
