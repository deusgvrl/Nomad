//
//  LatchSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import SpriteKit

final class LatchSystem {

    private let configuration: GameConfiguration

    init(configuration: GameConfiguration) {
        self.configuration = configuration
    }

    func attemptLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        guard canLatch(player: player, onto: vehicle) else { return false }

        player.attach(to: vehicle)
        return true
    }

    func canLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        let playerFrame = player.node.calculateAccumulatedFrame()
        let vehicleFrame = vehicle.node.calculateAccumulatedFrame().insetBy(
            dx: -configuration.latchDistance,
            dy: -configuration.latchDistance
        )

        return playerFrame.intersects(vehicleFrame)
    }
}
