//
//  GameScene+GameOver.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 20/05/26.
//

import GameplayKit
import SpriteKit

// MARK: - GameScene Game Over Extension

/// Game Over behavior for `GameScene`.
///
/// This file is not a separate `SKScene`. It is an extension of the same
/// `GameScene` class from `GameScene.swift`, split into another file so the main
/// scene file can focus on setup, input, update, collision, and movement.
///
/// Methods in this extension can be called from other files only when they are
/// internal/default access. Private helpers stay local to this file.
extension GameScene {

    // MARK: - Game Over Entry

    /// Ends the run, stops movement, finishes score, settles the player, and
    /// presents the Game Over overlay.
    func enterGameOver(playerEndState: PlayerState = .crashed) {
        guard gameState != .gameOver else { return }

        gameState = .gameOver
        playerState = playerEndState

        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }

        playerEntity?.component(ofType: LaunchComponent.self)?.reset()

        let scoreResult = distanceScoreSystem.finishRun()
        settlePlayerInFrontOfVehicle { [weak self] in
            self?.showGameOverScreen(scoreResult: scoreResult)
        }
    }

    // MARK: - Game Over Touch Routing

    /// Lets the overlay consume retry/home taps while gameplay input is paused.
    func handleGameOverTouch(at location: CGPoint) {
        _ = gameOverScreen?.handleTouch(at: location)
    }
}

// MARK: - Fall Landing

private extension GameScene {

    /// Moves a failed jump into a readable on-screen spot before the overlay
    /// fades in, avoiding the old off-screen drift.
    func settlePlayerInFrontOfVehicle(completion: @escaping () -> Void) {
        guard let playerEntity, let currentVehicleEntity else {
            completion()
            return
        }

        let landingPosition = fallLandingPosition(
            for: playerEntity,
            vehicle: currentVehicleEntity
        )

        playerEntity.node.removeAllActions()
        playerEntity.node.zPosition = RenderLayer.player

        let settleAction = SKAction.move(
            to: landingPosition,
            duration: configuration.playerFallSettleDuration
        )
        settleAction.timingMode = .easeOut
        playerEntity.node.run(settleAction, completion: completion)
    }

    /// Projects the failed jump from the player's current position along the
    /// configured 60-degree road-forward direction.
    func fallLandingPosition(for player: PlayerEntity, vehicle _: VehicleEntity) -> CGPoint {
        let playerPosition = player.node.position
        let proposedPosition = configuration.jumpForwardLandingPosition(from: playerPosition)

        return clampedPlayerPosition(proposedPosition)
    }

    /// Keeps the settled player visible even if the failed jump lands near a
    /// phone edge.
    func clampedPlayerPosition(_ position: CGPoint) -> CGPoint {
        let halfPlayerWidth = configuration.playerSize.width / 2
        let halfPlayerHeight = configuration.playerSize.height / 2
        let xBounds = (-size.width / 2 + halfPlayerWidth)...(size.width / 2 - halfPlayerWidth)
        let yBounds = (-size.height / 2 + halfPlayerHeight)...(size.height / 2 - halfPlayerHeight)

        return CGPoint(
            x: min(max(position.x, xBounds.lowerBound), xBounds.upperBound),
            y: min(max(position.y, yBounds.lowerBound), yBounds.upperBound)
        )
    }
}

// MARK: - Overlay Presentation

private extension GameScene {

    /// Builds and displays the Game Over screen overlay on top of gameplay.
    func showGameOverScreen(scoreResult: ScoreResult) {
        guard gameOverScreen == nil else { return }

        let screen = GameOverScreen(
            scoreResult: scoreResult,
            configuration: configuration
        )

        // MARK: Try Again Callback
        // Retry resets the full scene and clears this overlay through setup.
        screen.onTryAgain = { [weak self] in
            self?.setUpScene()
        }

        // MARK: Home Callback
        // The Home screen flow does not exist yet, so this remains intentionally
        // parked until the menu/home navigation is implemented.
        screen.onHome = {
            // FIXME: Navigate to the Home Menu once the Home Menu screen exists.
        }

        gameOverScreen = screen
        addChild(screen)
        screen.present()
    }
}
