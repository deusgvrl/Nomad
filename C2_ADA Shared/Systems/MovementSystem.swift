//
//  MovementSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import GameplayKit

final class MovementSystem {

    func beginSteering(vehicle: VehicleEntity, at location: CGPoint) {
        vehicle.component(ofType: MovementComponent.self)?.beginDrag(at: location)
    }

    func updateVehicleAndRider(vehicle: VehicleEntity, player: PlayerEntity, inputPhase: InputPhase) {
        guard case .dragging(_, _, let translation) = inputPhase,
              let movementComponent = vehicle.component(ofType: MovementComponent.self) else {
            return
        }

        let targetXPosition = movementComponent.applyDragTranslation(translation)
        vehicle.setXPosition(targetXPosition)
        player.place(on: vehicle)
    }

    func endSteering(vehicle: VehicleEntity) {
        vehicle.component(ofType: MovementComponent.self)?.endDrag()
    }
}
