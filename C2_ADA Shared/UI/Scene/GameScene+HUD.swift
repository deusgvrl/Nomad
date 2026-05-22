//
//  GameScene+HUD.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 21/05/26.
//

import SpriteKit

// MARK: - GameScene HUD Extension

/// HUD behavior for `GameScene`.
///
/// This extension owns the fixed-screen distance counter and pause entry flow.
/// Keeping it outside `GameScene.swift` makes the main scene easier to scan
/// while still letting the scene call small, readable HUD entry points.
extension GameScene {

    // MARK: - HUD Setup

    /// Builds the fixed screen HUD above the moving world.
    ///
    /// The HUD is a direct scene child, not part of `worldNode` or
    /// `gameplayNode`, so the distance label and pause button stay pinned to the
    /// top corners while the road scrolls underneath.
    func setUpHUD() {
        removeExistingHUDIfNeeded()

        let hudNode = SKNode()
        hudNode.name = HUDNodeName.hud
        hudNode.position = .zero
        hudNode.zPosition = RenderLayer.hud
        addChild(hudNode)

        setUpDistanceCounter(in: hudNode)
        setUpPauseButton(in: hudNode)
        refreshDistanceHUD()
    }

    // MARK: - Distance Score Update

    /// Advances the final distance counter and refreshes the top-left HUD.
    func updateDistanceScore(_ deltaTime: TimeInterval) {
        guard gameState == .playing else {
            return
        }

        // MARK: Live Distance Count
        // The HUD and Game Over result read from the same score system, so the
        // number players see while driving is the exact number saved/compared
        // when the run ends.
        distanceScoreSystem.updateDistance(
            deltaTime: deltaTime,
            metersPerSecond: configuration.distanceMetersPerSecond
        )
        refreshDistanceHUD()
    }

    // MARK: - Pause Touch Routing

    /// Checks whether a scene touch hit the top-right pause button.
    ///
    /// This runs before gameplay input so tapping the HUD never accidentally
    /// starts steering, jumping, or latching.
    func handlePauseButtonTouch(at location: CGPoint) -> Bool {
        guard gameState != .paused,
              gameState != .gameOver,
              isTouch(location, inside: pauseButtonNode, xInset: -12, yInset: -12) else {
            return false
        }

        enterPause()
        return true
    }

    /// Sends scene-space touches to the pause overlay while gameplay is paused.
    func handlePauseTouch(at location: CGPoint) {
        _ = pauseScreen?.handleTouch(at: location)
    }
}

// MARK: - HUD Construction

private extension GameScene {

    // MARK: - Distance Counter

    /// Creates the top-left meter counter shown in the attached reference.
    ///
    /// Both the number and the trailing `m` intentionally use
    /// `configuration.primaryFontName`, which is registered before this method
    /// runs in `setUpScene()`.
    func setUpDistanceCounter(in hudNode: SKNode) {
        let distanceScoreNode = SKNode()
        distanceScoreNode.name = HUDNodeName.distanceScore
        distanceScoreNode.position = CGPoint(
            x: -size.width / 2 + 34,
            y: size.height / 2 - 84
        )
        hudNode.addChild(distanceScoreNode)

        let distanceNumberLabel = SKLabelNode(fontNamed: configuration.primaryFontName)
        distanceNumberLabel.name = HUDNodeName.distanceNumber
        distanceNumberLabel.fontSize = 46
        distanceNumberLabel.fontColor = hudTextColor
        distanceNumberLabel.horizontalAlignmentMode = .left
        distanceNumberLabel.verticalAlignmentMode = .center
        distanceNumberLabel.position = .zero
        distanceScoreNode.addChild(distanceNumberLabel)

        let distanceMetersLabel = SKLabelNode(fontNamed: configuration.primaryFontName)
        distanceMetersLabel.name = HUDNodeName.distanceMeters
        distanceMetersLabel.fontSize = 20
        distanceMetersLabel.fontColor = hudTextColor
        distanceMetersLabel.horizontalAlignmentMode = .left
        distanceMetersLabel.verticalAlignmentMode = .center
        distanceScoreNode.addChild(distanceMetersLabel)
    }

    /// Updates the label text and repositions `m` after the number width changes.
    ///
    /// The number can grow from `0` to multiple digits during a run, so the meter
    /// suffix is laid out from the current label frame every time the HUD
    /// refreshes.
    func refreshDistanceHUD() {
        guard let distanceNumberLabel,
              let distanceMetersLabel else {
            return
        }

        distanceNumberLabel.text = "\(distanceScoreSystem.currentDistanceMeters)"
        distanceMetersLabel.text = "m"
        distanceMetersLabel.position = CGPoint(
            x: distanceNumberLabel.frame.maxX + 4,
            y: -12
        )
    }

    // MARK: - Pause Button

    /// Creates the top-right pause button from the imported asset catalog image.
    ///
    /// The node keeps the same `pauseButton` name used by touch routing, so the
    /// button behavior stays stable while the visual comes from `PAUSE BUTTON`.
    func setUpPauseButton(in hudNode: SKNode) {
        let pauseButtonNode = SKSpriteNode(imageNamed: NomadAsset.pauseButton.rawValue)
        pauseButtonNode.name = HUDNodeName.pauseButton
        pauseButtonNode.position = CGPoint(
            x: size.width / 2 - 44,
            y: size.height / 2 - 76
        )
        pauseButtonNode.size = CGSize(width: 52, height: 52)
        pauseButtonNode.zPosition = 1
        hudNode.addChild(pauseButtonNode)
    }

    // MARK: - HUD Reset

    /// Removes a previous HUD before rebuilding, keeping retry/setup idempotent.
    func removeExistingHUDIfNeeded() {
        hudNode?.removeFromParent()
    }
}

// MARK: - Pause Flow

private extension GameScene {

    // MARK: - Pause State

    /// Freezes gameplay and presents the replaceable pause overlay.
    func enterPause() {
        let resumeState = gameState
        gameState = .paused
        setGameplayNodesPaused(true)
        showPauseScreen(resumeState: resumeState)
    }

    /// Restores the run state stored by the pause overlay.
    func resumeGameFromPause(using screen: PauseScreen?) {
        guard gameState == .paused else { return }

        let resumeState = screen?.resumeGameState ?? .playing
        screen?.dismiss { [weak screen] in
            screen?.removeFromParent()
        }

        setGameplayNodesPaused(false)
        spawnSystem?.resetFrameTiming()
        lastUpdateTime = 0
        gameState = resumeState
    }

    /// Pauses only gameplay containers so HUD and overlays remain interactive.
    func setGameplayNodesPaused(_ isPaused: Bool) {
        worldNode.isPaused = isPaused
        gameplayNode.isPaused = isPaused
    }

    // MARK: - Pause Overlay

    /// Shows a simple placeholder that your friend's final pause UI can replace.
    func showPauseScreen(resumeState: GameState) {
        guard pauseScreen == nil else { return }

        let screen = PauseScreen(
            configuration: configuration,
            resumeGameState: resumeState
        )
        screen.onResume = { [weak self, weak screen] in
            self?.resumeGameFromPause(using: screen)
        }

        addChild(screen)
        screen.present()
    }

    // MARK: - Touch Helpers

    /// Uses accumulated frames so grouped nodes have one forgiving touch target.
    func isTouch(
        _ location: CGPoint,
        inside node: SKNode?,
        xInset: CGFloat,
        yInset: CGFloat
    ) -> Bool {
        guard let node else { return false }

        return node.calculateAccumulatedFrame()
            .insetBy(dx: xInset, dy: yInset)
            .contains(location)
    }
}

// MARK: - HUD Node Lookup

private extension GameScene {

    var hudNode: SKNode? {
        childNode(withName: HUDNodeName.hud)
    }

    var distanceNumberLabel: SKLabelNode? {
        hudNode?.childNode(withName: recursiveNodeName(HUDNodeName.distanceNumber)) as? SKLabelNode
    }

    var distanceMetersLabel: SKLabelNode? {
        hudNode?.childNode(withName: recursiveNodeName(HUDNodeName.distanceMeters)) as? SKLabelNode
    }

    var pauseButtonNode: SKNode? {
        hudNode?.childNode(withName: HUDNodeName.pauseButton)
    }

    var pauseScreen: PauseScreen? {
        childNode(withName: HUDNodeName.pauseOverlay) as? PauseScreen
    }

    func recursiveNodeName(_ name: String) -> String {
        "//\(name)"
    }
}

// MARK: - HUD Constants

private enum HUDNodeName {
    static let hud = "gameHUD"
    static let distanceScore = "distanceScoreHUD"
    static let distanceNumber = "distanceScoreNumber"
    static let distanceMeters = "distanceScoreMeters"
    static let pauseButton = "pauseButton"
    static let pauseOverlay = "pauseOverlay"
}

private extension GameScene {

    /// Shared HUD color sampled to match the dark brown/orange UI reference.
    var hudTextColor: SKColor {
        SKColor(red: 0.56, green: 0.28, blue: 0.09, alpha: 1.0)
    }
}
