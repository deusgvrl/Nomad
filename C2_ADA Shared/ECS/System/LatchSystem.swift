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
        // MARK: Front-Only Latch Filter
        // Vehicles are sorted by forward distance along the 60-degree road line,
        // so a latch can only happen on cars that are actually in front.
        let frontVehicles = vehicles.compactMap { vehicle -> (vehicle: VehicleEntity, forwardDistance: CGFloat)? in
            guard let forwardDistance = forwardDistanceFromPlayer(to: vehicle, player: player),
                  forwardDistance >= 0 else {
                return nil
            }

            return (vehicle, forwardDistance)
        }
        .sorted { $0.forwardDistance < $1.forwardDistance }

        for (vehicle, _) in frontVehicles {
            if canLatch(player: player, onto: vehicle) {
                player.attach(to: vehicle)
                return vehicle
            }
        }

        return nil
    }

    // MARK: - Latch Detection

    func canLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
        guard let playerParent = player.node.parent,
              let vehicleFrame = vehicleFrame(for: vehicle, in: playerParent) else {
            return false
        }

        let playerFrame = player.node.calculateAccumulatedFrame()
        let expandedVehicleFrame = vehicleFrame.insetBy(
            dx: -configuration.latchDistance,
            dy: -configuration.latchDistance
        )

        return playerFrame.intersects(expandedVehicleFrame)
    }

    // MARK: - Forward Direction Check

    func forwardDistanceFromPlayer(to vehicle: VehicleEntity, player: PlayerEntity) -> CGFloat? {
        guard let playerParent = player.node.parent,
              let vehicleFrame = vehicleFrame(for: vehicle, in: playerParent) else {
            return nil
        }

        let playerFrame = player.node.calculateAccumulatedFrame()
        let deltaToVehicle = CGVector(
            dx: vehicleFrame.midX - playerFrame.midX,
            dy: vehicleFrame.midY - playerFrame.midY
        )
        let roadForward = configuration.jumpForwardUnitVector

        return (deltaToVehicle.dx * roadForward.dx) + (deltaToVehicle.dy * roadForward.dy)
    }

    // MARK: - Frame Conversion

    func vehicleFrame(for vehicle: VehicleEntity, in playerParent: SKNode) -> CGRect? {
        guard let vehicleParent = vehicle.node.parent else { return nil }

        let localVehicleFrame = vehicle.node.calculateAccumulatedFrame()
        guard vehicleParent !== playerParent else {
            return localVehicleFrame
        }

        return vehicleParent.convert(localVehicleFrame, to: playerParent)
    }
}
