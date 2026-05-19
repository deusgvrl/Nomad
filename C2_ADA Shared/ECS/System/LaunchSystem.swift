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

    func launch(player: PlayerEntity) {
        player.detachFromVehicle()
        player.component(ofType: LaunchComponent.self)?.launch(
            from: player.node.position,
            horizontalVelocity: launchForwardXVelocity,
            verticalVelocity: configuration.launchVelocity,
            forwardYVelocity: configuration.launchForwardThrust
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

        return position.y <= configuration.groundYPosition ? .fell : .airborne
    }

    // MARK: - Isometric Forward Motion

    private var launchForwardXVelocity: CGFloat {
        let radians = Double(configuration.launchForwardAngleInDegrees) * Double.pi / 180
        
        return configuration.launchVelocity / CGFloat(tan(radians))
    }
}
