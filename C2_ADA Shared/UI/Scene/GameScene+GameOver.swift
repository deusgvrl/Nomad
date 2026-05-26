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

    /// Ends the run, stops movement, finishes score, and presents the Game Over overlay.
    ///
    /// Falling keeps the final physics impact position. Crashes can still run a
    /// short readability settle before the overlay appears.
    func enterGameOver(playerEndState: PlayerState = .crashed) {
        guard gameState != .gameOver else { return }

        gameState = .gameOver
        playerState = playerEndState
        
        playerEntity?.playDeadVisual()

        // MARK: Game Over Haptics Stop
        // Game Over freezes gameplay and overlays buttons, so any active rage
        // pulse must end before the result screen appears.
        hapticsController.stopRagePulse()

        if let currentVehicleEntity {
            currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.stopRageHaptics()
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }

        playerEntity?.component(ofType: LaunchComponent.self)?.reset()

        let scoreResult = distanceScoreSystem.finishRun()
        guard playerEndState != .falling else {
            showGameOverScreen(scoreResult: scoreResult)
            return
        }

        settlePlayerForCrash { [weak self] in
            self?.showGameOverScreen(scoreResult: scoreResult)
        }
    }

    // MARK: - Game Over Touch Routing

    /// Lets the overlay consume retry/home taps while gameplay input is paused.
    func handleGameOverTouch(at location: CGPoint) {
        _ = gameOverScreen?.handleTouch(at: location)
    }

    // MARK: - Fall Game Over Entry

    /// Handles missed-jump lane impact before showing Game Over.
    ///
    /// The live jump path comes from `LaunchSystem`; this helper only cleans up
    /// the final impact frame so the player does not receive another settle
    /// movement when the overlay appears.
    func enterFallGameOver() {
        resetGameOverTiming()
        cleanUpFallImpactPresentation()
        enterGameOver(playerEndState: .falling)
    }
}

// MARK: - Crash Settling

private extension GameScene {

    /// Moves crash endings into a readable on-screen spot before the overlay
    /// fades in, while fall endings keep their floor-impact position.
    func settlePlayerForCrash(completion: @escaping () -> Void) {
        guard let playerEntity, let currentVehicleEntity else {
            completion()
            return
        }

        let landingPosition = crashLandingPosition(
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

    /// Projects crash presentation from the player's current position along the
    /// configured 60-degree road-forward direction.
    func crashLandingPosition(for player: PlayerEntity, vehicle _: VehicleEntity) -> CGPoint {
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
            configuration: configuration,
            hapticsController: hapticsController
        )

        // MARK: Try Again Callback
        // Retry resets the full scene and clears this overlay through setup.
        screen.onTryAgain = { [weak self] in
            self?.setUpScene(skipsMenu: true)
        }

        // MARK: Home Callback
        // Home rebuilds the scene and presents `MenuScreen` immediately so the
        // gameplay scene does not briefly flash between overlays.
        screen.onHome = { [weak self] in
            self?.setUpScene(showsMenuImmediately: true)
        }

        gameOverScreen = screen
        addChild(screen)
        screen.present()
    }
}
