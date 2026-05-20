//
//  LaunchComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation
import GameplayKit

// MARK: - Launch Component

/// Holds the player's airborne physics values after releasing from a vehicle.
///
/// This is intentionally small: it stores only position and velocity. The
/// `LaunchSystem` decides when to start the jump and reports when the player has
/// fallen below the prototype ground line.
final class LaunchComponent: GKComponent {

    // MARK: - Airborne State

    private(set) var isAirborne = false
    private(set) var currentPosition: CGPoint = .zero
    private var horizontalVelocity: CGFloat = 0
    private var verticalVelocity: CGFloat = 0
    private var forwardYVelocity: CGFloat = 0

    // MARK: - Launch Lifecycle

    func launch(from position: CGPoint, horizontalVelocity: CGFloat, verticalVelocity: CGFloat, forwardYVelocity: CGFloat) {
        // MARK: Dev Jump State
        // Store the same simple velocity state used on `dev` so release starts
        // a normal jump arc instead of steering toward a preselected fall spot.
        isAirborne = true
        currentPosition = position
        self.horizontalVelocity = horizontalVelocity
        self.verticalVelocity = verticalVelocity
        self.forwardYVelocity = forwardYVelocity
    }

    // MARK: - Physics Update

    func update(deltaTime: TimeInterval, gravity: CGFloat) -> CGPoint {
        guard isAirborne else { return currentPosition }

        let elapsedTime = CGFloat(deltaTime)
        
        verticalVelocity -= gravity * elapsedTime
        
        currentPosition = CGPoint(
            x: currentPosition.x + horizontalVelocity * elapsedTime,
            y: currentPosition.y + (verticalVelocity + forwardYVelocity) * elapsedTime
        )
        return currentPosition
    }

    // MARK: - Reset

    func reset() {
        // MARK: Dev Jump Reset
        // Clear only the active jump velocities; the next release will recreate
        // the same dev jump arc from the player's current position.
        isAirborne = false
        horizontalVelocity = 0
        verticalVelocity = 0
        forwardYVelocity = 0
    }
}
