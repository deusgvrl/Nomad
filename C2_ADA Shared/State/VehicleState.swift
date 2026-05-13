//
//  VehicleState.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Vehicle State

/// Planned visual/gameplay states for vehicle variants.
///
/// These states map to the art notes: normal vehicle, person popping out, hit
/// frames, latch target, and crash/despawn behavior.
enum VehicleState: Hashable {
    // MARK: Ride States

    case normal
    case controlled

    // MARK: Character Animation States

    case personPoppingOut
    case personHitting1
    case personHitting2

    // MARK: Launch And Latch States

    case forcedLaunch
    case latchTarget
    case latched

    // MARK: End States

    case crashed
    case despawned
}
