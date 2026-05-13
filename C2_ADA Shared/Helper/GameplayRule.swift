//
//  GameplayRule.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Gameplay Rule

/// Names the main rules from the game design notes.
///
/// This gives future code, tests, or tutorial UI a stable place to reference
/// "what rule is being explained" without writing loose strings everywhere.
enum GameplayRule {
    // MARK: Input Rules

    case holdToStart
    case dragToSteer
    case releaseToJump
    case holdToLatch

    // MARK: Failure Rules

    case missLatchGameOver
    case obstacleCollisionGameOver

    // MARK: Scoring Rules

    case scoreBeatsHighscore
}
