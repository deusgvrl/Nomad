//
//  EntityKind.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Entity Kind

/// Shared labels for the main kinds of game objects in Nomad.
///
/// This is not wired into every entity yet, but it gives future systems a clear
/// vocabulary for filtering objects like players, vehicles, obstacles, and FX.
enum EntityKind {
    // MARK: Core Gameplay

    case player
    case vehicle
    case obstacle
    case background

    // MARK: Feedback Objects

    case effect
    case particle
}
