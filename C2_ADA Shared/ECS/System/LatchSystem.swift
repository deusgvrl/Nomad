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

    func attemptLatch(player: PlayerEntity, onto vehicles: [VehicleEntity]) -> VehicleEntity? {
        // MARK: Dev Latch Attempt
        // Match `dev`: check spawned vehicles in their current order and latch
        // to the first vehicle whose expanded frame intersects the player.
        for vehicle in vehicles {
            if canLatch(player: player, onto: vehicle) {
                player.attach(to: vehicle)
                return vehicle
            }
        }

        return nil
    }

    // MARK: - Latch Detection

    func canLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        // MARK: Dev Frame Latch
        // Match `dev`: compare the player frame against the vehicle frame,
        // converting parent coordinate spaces when the vehicle lives in worldNode.
        let localPlayerFrame = player.node.calculateAccumulatedFrame()
        let localVehicleFrame = vehicle.node.calculateAccumulatedFrame().insetBy(
            dx: -configuration.latchDistance,
            dy: -configuration.latchDistance
        )

        guard let playerParent = player.node.parent,
              let vehicleParent = vehicle.node.parent,
              playerParent !== vehicleParent else {
            return localPlayerFrame.intersects(localVehicleFrame)
        }

        let convertedVehicleFrame = vehicleParent.convert(localVehicleFrame, to: playerParent)
        return localPlayerFrame.intersects(convertedVehicleFrame)
    }
}
