//
//  PauseScreen.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 21/05/26.
//

import SpriteKit

// MARK: - Pause Screen

/// Temporary SpriteKit pause overlay for `GameScene`.
///
/// This screen is intentionally small and replaceable. It gives this branch a
/// real pause state and a visible resume path, while the final pause UI can
/// later keep the same `onResume` callback and replace the layout internals.
final class PauseScreen: SKNode {

    // MARK: - Button Actions

    /// Called when the placeholder Resume button is tapped.
    var onResume: (() -> Void)?

    // MARK: - Dependencies

    /// Game state that should be restored when this pause screen resumes.
    let resumeGameState: GameState

    private let configuration: GameConfiguration

    /// Shared haptics wrapper used by the Resume button.
    private let hapticsController: HapticsController

    // MARK: - Touch Targets

    private var resumeButtonNode: SKNode?

    // MARK: - Initialization

    init(
        configuration: GameConfiguration,
        resumeGameState: GameState,
        hapticsController: HapticsController = .shared
    ) {
        self.configuration = configuration
        self.resumeGameState = resumeGameState
        self.hapticsController = hapticsController
        super.init()

        name = "pauseOverlay"
        zPosition = RenderLayer.pauseOverlay
        alpha = 0

        buildScreen()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Presentation

    /// Fades the pause overlay in after `GameScene` adds it to the scene.
    func present() {
        run(SKAction.fadeIn(withDuration: 0.12))
    }

    /// Fades the overlay out before `GameScene` removes it.
    func dismiss(completion: @escaping () -> Void) {
        run(SKAction.fadeOut(withDuration: 0.10), completion: completion)
    }

    // MARK: - Touch Handling

    /// Handles placeholder pause UI touches and reports whether they were used.
    func handleTouch(at location: CGPoint) -> Bool {
        // MARK: Screen-Space Touch Conversion
        // GameScene sends scene coordinates. Convert them into this overlay's
        // local space before testing button frames.
        let screenLocation = parent?.convert(location, to: self) ?? location

        if isTouch(screenLocation, inside: resumeButtonNode, xInset: -16, yInset: -12) {
            hapticsController.playLightButtonTap()
            onResume?()
            return true
        }

        return false
    }

    /// Uses accumulated frames so the whole grouped button remains tappable.
    private func isTouch(
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

// MARK: - Screen Construction

private extension PauseScreen {

    /// Adds a dim layer, title, and one resume button for temporary testing.
    func buildScreen() {
        addChild(makeDimLayer())
        addChild(makePanel())
    }

    // MARK: - Dim Layer

    /// Darkens gameplay while leaving the paused road visible underneath.
    func makeDimLayer() -> SKNode {
        let dimLayer = SKShapeNode(rectOf: configuration.referenceScreenSize)
        dimLayer.name = "pauseDimLayer"
        dimLayer.fillColor = pauseDimColor
        dimLayer.strokeColor = .clear
        dimLayer.zPosition = 0
        return dimLayer
    }

    // MARK: - Panel

    /// Builds the temporary content group that future pause UI can replace.
    func makePanel() -> SKNode {
        let panelNode = SKNode()
        panelNode.name = "pausePanel"
        panelNode.zPosition = 1

        let backgroundNode = SKShapeNode(rectOf: CGSize(width: 246, height: 150), cornerRadius: 8)
        backgroundNode.name = "pausePanelBackground"
        backgroundNode.fillColor = pausePanelColor
        backgroundNode.strokeColor = pauseAccentColor
        backgroundNode.lineWidth = 3
        panelNode.addChild(backgroundNode)

        let titleLabel = makeLabel(
            text: "PAUSED",
            fontName: configuration.primaryFontName,
            fontSize: 44,
            color: pauseAccentColor
        )
        titleLabel.name = "pauseTitle"
        titleLabel.position = CGPoint(x: 0, y: 32)
        panelNode.addChild(titleLabel)

        let resumeButton = makeResumeButton()
        panelNode.addChild(resumeButton)
        resumeButtonNode = resumeButton

        return panelNode
    }

    // MARK: - Resume Button

    /// Temporary resume control so pause can be tested before final UI lands.
    func makeResumeButton() -> SKNode {
        let buttonNode = SKNode()
        buttonNode.name = "pauseResumeButton"
        buttonNode.position = CGPoint(x: 0, y: -42)

        let backgroundNode = SKShapeNode(rectOf: CGSize(width: 142, height: 42), cornerRadius: 7)
        backgroundNode.name = "pauseResumeButtonBackground"
        backgroundNode.fillColor = pauseAccentColor
        backgroundNode.strokeColor = pauseAccentColor.withAlphaComponent(0.75)
        backgroundNode.lineWidth = 2
        buttonNode.addChild(backgroundNode)

        let labelNode = makeLabel(
            text: "Resume",
            fontName: configuration.secondaryFontName,
            fontSize: 20,
            color: pauseButtonTextColor
        )
        labelNode.name = "pauseResumeButtonLabel"
        buttonNode.addChild(labelNode)

        return buttonNode
    }

    // MARK: - Label Factory

    /// Keeps placeholder labels consistent and easy to swap later.
    func makeLabel(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        color: SKColor
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        return label
    }
}

// MARK: - Pause Colors

private extension PauseScreen {

    var pauseDimColor: SKColor {
        SKColor(red: 0.29, green: 0.15, blue: 0.05, alpha: 0.58)
    }

    var pausePanelColor: SKColor {
        SKColor(red: 0.18, green: 0.10, blue: 0.04, alpha: 0.92)
    }

    var pauseAccentColor: SKColor {
        SKColor(red: 0.96, green: 0.55, blue: 0.20, alpha: 1.0)
    }

    var pauseButtonTextColor: SKColor {
        SKColor(red: 0.23, green: 0.11, blue: 0.03, alpha: 1.0)
    }
}
