//
//  ObstacleState.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Obstacle State

/// Planned lifecycle states for obstacles.
///
/// The current prototype draws static obstacle placeholders. These states are
/// ready for the later treadmill/spawner work.
enum ObstacleState: Hashable {
    /// Created but not yet fully active.
    case spawning

    /// Can collide with the player/vehicle.
    case active

    /// Safely passed by the player.
    case passed

    /// Hit by the player or vehicle.
    case collided

    /// Removed from the active scene.
    case despawned
}
