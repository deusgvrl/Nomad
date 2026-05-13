//
//  PlayerState.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Player State

/// Fine-grained state for the player's current action.
///
/// This is separate from `GameState`: the game can be playing while the player is
/// riding, jumping, or attempting to latch.
enum PlayerState: Hashable {
    /// Before the first hold starts the run.
    case idle

    /// Attached to the active vehicle and allowed to steer.
    case riding

    /// Airborne after releasing the hold.
    case jumping

    /// Hold-again check is trying to attach to a vehicle.
    case latching

    /// Missed latch or dropped below the ground line.
    case falling

    /// Hit an obstacle or ended from collision.
    case crashed
}
