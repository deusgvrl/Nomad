//
//  GameState.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

// MARK: - Game State

/// High-level run state for the whole game.
///
/// Use this to answer "what mode is the run in?" rather than "what is the
/// player doing?"
enum GameState: Hashable {
    /// The scene is loaded and waiting for the first hold.
    case waitingToStart

    /// The active run is in progress.
    case playing

    /// Reserved for a future pause menu.
    case paused

    /// Reserved for the later game-over branch.
    case gameOver
}
