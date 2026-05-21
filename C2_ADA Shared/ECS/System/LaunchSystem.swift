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

/// Handles the player's jump path after release.
///
/// The player detaches from the car and moves forward on the same car-facing
/// lane. If the jump finishes without a latch, this system reports `.fell`;
/// `GameScene` decides how to present the Game Over result.
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

    func launch(player: PlayerEntity) {
        // MARK: Lane Jump Launch
        // Release only detaches the rider and starts a straight lane jump. The
        // visual scale animation supplies jump height without changing the path.
        player.detachFromVehicle()
        player.component(ofType: LaunchComponent.self)?.launch(
            from: player.node.position,
            direction: configuration.jumpForwardUnitVector,
            distance: configuration.jumpForwardDistance,
            duration: configuration.jumpForwardDuration
        )
    }

    // MARK: - Launch Update

    func update(player: PlayerEntity, deltaTime: TimeInterval) -> UpdateResult {
        guard let launchComponent = player.component(ofType: LaunchComponent.self),
              launchComponent.isAirborne else {
            return .airborne
        }

        let position = launchComponent.updateLaunch(deltaTime: deltaTime)
        player.node.position = position

        // MARK: Lane End Check
        // The component reports floor impact when the forward lane movement
        // ends. This replaces the old gravity ground-line check so there is no
        // curved fall after a missed latch.
        return launchComponent.hasHitFloor ? .fell : .airborne
    }

    // MARK: - Jump Timing
    // Jump duration now lives in `GameConfiguration` so latch speed can be tuned
    // directly without touching the lane-linear movement code.
}
