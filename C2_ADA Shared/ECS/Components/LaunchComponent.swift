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

    // MARK: - Launch Lifecycle

    func launch(from position: CGPoint, horizontalVelocity: CGFloat, verticalVelocity: CGFloat) {
        isAirborne = true
        currentPosition = position
        self.horizontalVelocity = horizontalVelocity
        self.verticalVelocity = verticalVelocity
    }

    // MARK: - Physics Update

    func update(deltaTime: TimeInterval, gravity: CGFloat) -> CGPoint {
        guard isAirborne else { return currentPosition }

        let elapsedTime = CGFloat(deltaTime)
        verticalVelocity -= gravity * elapsedTime
        currentPosition = CGPoint(
            x: currentPosition.x + horizontalVelocity * elapsedTime,
            y: currentPosition.y + verticalVelocity * elapsedTime
        )
        return currentPosition
    }

    // MARK: - Reset

    func reset() {
        isAirborne = false
        horizontalVelocity = 0
        verticalVelocity = 0
    }
}
