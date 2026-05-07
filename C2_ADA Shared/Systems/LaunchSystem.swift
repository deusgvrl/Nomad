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

final class LaunchSystem {

    enum UpdateResult {
        case airborne
        case fell
    }

    private let configuration: GameConfiguration

    init(configuration: GameConfiguration) {
        self.configuration = configuration
    }

    func launch(player: PlayerEntity, toward vehicle: VehicleEntity?) {
        player.detachFromVehicle()
        let targetXPosition = vehicle?.node.position.x ?? player.node.position.x
        let horizontalVelocity = (targetXPosition - player.node.position.x) / CGFloat(configuration.jumpTravelDuration)
        player.component(ofType: LaunchComponent.self)?.launch(
            from: player.node.position,
            horizontalVelocity: horizontalVelocity,
            verticalVelocity: configuration.launchVelocity
        )
    }

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
}
