//
//  LaunchSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation
import GameplayKit
import SpriteKit

// MARK: - Launch System

/// Handles the player's jump arc after release.
///
/// The player detaches from the car, moves forward in the isometric direction,
/// and falls under gravity. If the y position drops below the ground line, this
/// system reports `.fell`; `GameScene` decides what to do with that result.
final class LaunchSystem {

    // MARK: - Update Result

    enum UpdateResult {
        case airborne
        case fell
    }

    // MARK: - Dependencies

    private let configuration: GameConfiguration

    init(configuration: GameConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Launch Start

    func launch(player: PlayerEntity, landingTargetPosition: CGPoint? = nil) {
        player.detachFromVehicle()
        player.component(ofType: LaunchComponent.self)?.launch(
            from: player.node.position,
            horizontalVelocity: launchForwardXVelocity(
                from: player.node.position,
                to: landingTargetPosition
            ),
            verticalVelocity: configuration.launchVelocity,
            forwardYVelocity: configuration.launchForwardThrust,
            landingTargetPosition: landingTargetPosition
        )
    }

    // MARK: - Launch Update

    func update(player: PlayerEntity, deltaTime: TimeInterval) -> UpdateResult {
        guard let launchComponent = player.component(ofType: LaunchComponent.self),
              launchComponent.isAirborne else {
            return .airborne
        }

        let position = launchComponent.update(
            deltaTime: deltaTime,
            gravity: configuration.launchGravity
        )
        player.node.position = position

        if let landingTargetPosition = launchComponent.landingTargetPosition,
           launchComponent.isDescending,
           position.y <= landingTargetPosition.y {
            player.node.position = landingTargetPosition
            return .fell
        }

        return position.y <= configuration.groundYPosition ? .fell : .airborne
    }

    // MARK: - Isometric Forward Motion

    private func launchForwardXVelocity(
        from startPosition: CGPoint,
        to landingTargetPosition: CGPoint?
    ) -> CGFloat {
        guard let landingTargetPosition else {
            return defaultLaunchForwardXVelocity
        }

        // MARK: Fall Targeting
        // The fall branch should visibly land in front of the active car.
        // Calculating X velocity from the target prevents off-screen drift and
        // removes the old game-over snap-back.
        let targetAirTime = estimatedAirTime(
            from: startPosition,
            to: landingTargetPosition
        )
        return (landingTargetPosition.x - startPosition.x) / targetAirTime
    }

    private var defaultLaunchForwardXVelocity: CGFloat {
        let radians = Double(configuration.launchForwardAngleInDegrees) * Double.pi / 180
        return configuration.launchVelocity / CGFloat(tan(radians))
    }

    private func estimatedAirTime(
        from startPosition: CGPoint,
        to landingTargetPosition: CGPoint
    ) -> CGFloat {
        let initialYVelocity = configuration.launchVelocity + configuration.launchForwardThrust
        let targetYDelta = landingTargetPosition.y - startPosition.y
        let gravity = configuration.launchGravity
        let discriminant = max(0, (initialYVelocity * initialYVelocity) - (2 * gravity * targetYDelta))
        let descendingTime = (initialYVelocity + discriminant.squareRoot()) / gravity

        return max(descendingTime, CGFloat(configuration.maximumDeltaTime))
    }
}
