//
//  MovementSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import GameplayKit

// MARK: - Movement System

/// Applies riding movement to both the vehicle and the attached player.
///
/// This system only moves while the player is riding. GameScene decides when
/// movement is allowed; this system only performs the movement.
final class MovementSystem {

    // MARK: - Steering Lifecycle

    func beginSteering(vehicle: VehicleEntity, at location: CGPoint) {
        vehicle.component(ofType: MovementComponent.self)?.beginDrag(at: location)
    }

    // MARK: - Riding Movement

    func updateVehicleAndRider(vehicle: VehicleEntity, player: PlayerEntity, inputPhase: InputPhase) {
        guard case .dragging(_, _, let translation) = inputPhase,
              let movementComponent = vehicle.component(ofType: MovementComponent.self) else {
            return
        }

        // The vehicle calculates its road-width position; the player then follows
        // with its configured ride offset.
        let targetPosition = movementComponent.applyDragTranslation(translation)
        vehicle.setPosition(targetPosition)
        player.place(on: vehicle)
    }

    // MARK: - Steering End

    func endSteering(vehicle: VehicleEntity) {
        vehicle.component(ofType: MovementComponent.self)?.endDrag()
    }
}
