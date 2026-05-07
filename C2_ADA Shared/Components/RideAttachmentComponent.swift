//
//  RideAttachmentComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit

final class RideAttachmentComponent: GKComponent {

    private(set) weak var vehicle: VehicleEntity?

    var isAttached: Bool {
        vehicle != nil
    }

    func attach(to vehicle: VehicleEntity) {
        self.vehicle = vehicle
    }

    func detach() {
        vehicle = nil
    }
}
