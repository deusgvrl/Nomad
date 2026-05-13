//
//  LatchSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import SpriteKit

// MARK: - Latch System

/// Checks whether an airborne player can attach back onto a vehicle.
///
/// For this first backend version, latching uses frame intersection with a
/// generous inset. Later, this can become a more precise latch zone on the
/// vehicle sprite.
final class LatchSystem {

    // MARK: - Dependencies

    private let configuration: GameConfiguration

    init(configuration: GameConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Latch Attempt

    func attemptLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        guard canLatch(player: player, onto: vehicle) else { return false }

        player.attach(to: vehicle)
        return true
    }

    // MARK: - Latch Detection

    func canLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        let playerFrame = player.node.calculateAccumulatedFrame()
        // Expanding the vehicle frame makes early prototype latching more forgiving.
        let vehicleFrame = vehicle.node.calculateAccumulatedFrame().insetBy(
            dx: -configuration.latchDistance,
            dy: -configuration.latchDistance
        )

        return playerFrame.intersects(vehicleFrame)
    }
}
