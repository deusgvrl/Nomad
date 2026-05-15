//
//  ScreenState.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Screen State

/// Planned app-level screens.
///
/// This is not fully wired yet, but it gives the project shared names for future
/// SwiftUI/UIKit screens around the SpriteKit game.
enum ScreenState: Hashable {
    /// Main menu or entry screen.
    case home

    /// Options screen.
    case settings

    /// Active gameplay screen.
    case play

    /// Pause overlay.
    case paused

    /// Failure/game-over screen.
    case fail

    /// Result screen when the high score is beaten.
    case newHighscore
}
