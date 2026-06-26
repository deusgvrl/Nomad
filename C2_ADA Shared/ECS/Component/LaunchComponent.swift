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

/// Holds the player's airborne lane movement after releasing from a vehicle.
///
/// The player position moves in one straight line along the car-facing lane.
/// Jump height is handled by the player's visual scale animation, so gameplay
/// movement does not inherit a gravity curve or drift to the bottom-right.
final class LaunchComponent: GKComponent {

    // MARK: - Launch Mode

    /// Separates the full forward jump from the shorter failed-latch fall.
    private enum LaunchMode {
        case forwardJump
        case failedLatchFall
    }

    // MARK: - Airborne State

    private(set) var isAirborne = false
    private(set) var currentPosition: CGPoint = .zero
    private(set) var hasHitFloor = false
    private var launchMode: LaunchMode = .forwardJump
    private var linearStartPosition: CGPoint = .zero
    private var linearEndPosition: CGPoint = .zero
    private(set) var linearElapsedTime: TimeInterval = 0
    private(set) var linearDuration: TimeInterval = 0

    // MARK: - Launch Lifecycle

    func launch(
        from position: CGPoint,
        direction: CGVector,
        distance: CGFloat,
        duration: TimeInterval
    ) {
        // MARK: Forward Jump State
        // Start a lane-linear jump. This keeps the player on the same road line
        // as the car instead of mixing forward movement with gravity movement.
        beginLinearMotion(
            from: position,
            direction: direction,
            distance: distance,
            duration: duration,
            mode: .forwardJump
        )
    }

    // MARK: - Failed Latch Fall

    /// Converts a missed latch into a straight floor drop from the current spot.
    ///
    /// This uses a fixed linear endpoint along the car-facing lane, so the
    /// player does not continue the curved jump arc after a failed latch.
    func beginFailedLatchFall(
        from position: CGPoint,
        direction: CGVector,
        distance: CGFloat,
        duration: TimeInterval
    ) {
        // MARK: Failed Latch State
        // A missed latch keeps moving forward on the same lane, but only for a
        // short distance before reporting floor impact to GameScene.
        beginLinearMotion(
            from: position,
            direction: direction,
            distance: distance,
            duration: duration,
            mode: .failedLatchFall
        )
    }

    // MARK: - Lane Movement Update

    func updateLaunch(deltaTime: TimeInterval) -> CGPoint {
        guard isAirborne else { return currentPosition }

        switch launchMode {
        case .forwardJump:
            return updateLinearMotion(deltaTime: deltaTime)
        case .failedLatchFall:
            return updateLinearMotion(deltaTime: deltaTime)
        }
    }

    // MARK: - Linear Motion Setup

    /// Prepares any airborne lane movement from a start point to a forward end point.
    private func beginLinearMotion(
        from position: CGPoint,
        direction: CGVector,
        distance: CGFloat,
        duration: TimeInterval,
        mode: LaunchMode
    ) {
        let safeDuration = max(duration, 0.001)
        let directionLength = max(hypot(direction.dx, direction.dy), 0.001)
        let unitDirection = CGVector(
            dx: direction.dx / directionLength,
            dy: direction.dy / directionLength
        )

        isAirborne = true
        hasHitFloor = false
        launchMode = mode
        currentPosition = position
        linearStartPosition = position
        linearEndPosition = CGPoint(
            x: position.x + unitDirection.dx * distance,
            y: position.y + unitDirection.dy * distance
        )
        linearElapsedTime = 0
        linearDuration = safeDuration
    }

    // MARK: - Linear Motion Update

    /// Moves the player directly along the configured lane without gravity.
    private func updateLinearMotion(deltaTime: TimeInterval) -> CGPoint {
        linearElapsedTime += deltaTime

        let progress = min(max(linearElapsedTime / linearDuration, 0), 1)
        let easedProgress = CGFloat(progress)
        currentPosition = CGPoint(
            x: linearStartPosition.x
                + (linearEndPosition.x - linearStartPosition.x) * easedProgress,
            y: linearStartPosition.y
                + (linearEndPosition.y - linearStartPosition.y) * easedProgress
        )

        if progress >= 1 {
            isAirborne = false
            hasHitFloor = true
        }

        return currentPosition
    }

    // MARK: - Reset

    func reset() {
        // MARK: Lane Jump Reset
        // Clear the active lane movement; the next release will recreate a new
        // forward jump from the player's current car position.
        isAirborne = false
        hasHitFloor = false
        launchMode = .forwardJump
        linearElapsedTime = 0
        linearDuration = 0
    }
}
