//
//  RideAttachmentComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit

// MARK: - Ride Attachment Component

/// Tracks whether the player is currently attached to a vehicle.
///
/// While attached, movement updates should move the vehicle and then place the
/// player on top of it. When released, this component is detached and the player
/// becomes airborne.
final class RideAttachmentComponent: GKComponent {

    // MARK: - Attachment State

    private(set) weak var vehicle: VehicleEntity?

    var isAttached: Bool {
        vehicle != nil
    }

    // MARK: - Attachment Updates

    func attach(to vehicle: VehicleEntity) {
        self.vehicle = vehicle
    }

    func detach() {
        vehicle = nil
    }
}
