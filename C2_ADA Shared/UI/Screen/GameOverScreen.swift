//
//  GameOverScreen.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 20/05/26.
//

import SpriteKit
import UIKit

// MARK: - Game Over Screen

/// SpriteKit overlay that draws the Game Over result UI.
///
/// This is a screen-style node, not a separate `SKScene`. It sits above the
/// active gameplay scene so the background, car, player, and road remain visible
/// behind the dark overlay.
final class GameOverScreen: SKNode {

    // MARK: - Button Actions

    /// Called when the Try Again asset is tapped.
    var onTryAgain: (() -> Void)?

    /// Called when the Home text is tapped.
    var onHome: (() -> Void)?

    // MARK: - Dependencies

    private let configuration: GameConfiguration
    private let scoreResult: ScoreResult

    // MARK: - Touch Targets

    private var retryButtonNode: SKNode?
    private var homeButtonNode: SKNode?

    // MARK: - Initialization

    /// Builds the overlay immediately so GameScene can add and fade it in as
    /// one complete screen node.
    init(scoreResult: ScoreResult, configuration: GameConfiguration) {
        self.scoreResult = scoreResult
        self.configuration = configuration
        super.init()

        name = "gameOverOverlay"
        zPosition = RenderLayer.gameOverOverlay
        alpha = 0

        buildScreen()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Presentation

    /// Fades the overlay in after GameScene adds it to the active scene.
    func present() {
        run(SKAction.fadeIn(withDuration: 0.12))
    }

    // MARK: - Touch Handling

    /// Handles Game Over button taps and returns whether the touch was consumed.
    func handleTouch(at location: CGPoint) -> Bool {
        // MARK: Screen-Space Touch Conversion
        // GameScene sends scene coordinates, while this screen tests child
        // frames in its own coordinate space.
        let screenLocation = parent?.convert(location, to: self) ?? location

        // MARK: Home Priority
        // Home sits close to the Try Again asset. Check it first so taps on the
        // underlined text do not accidentally hit the larger Try Again frame.
        if isTouch(screenLocation, inside: homeButtonNode, xInset: -16, yInset: -10) {
            onHome?()
            return true
        }

        if isTouch(screenLocation, inside: retryButtonNode, xInset: -18, yInset: -10) {
            onTryAgain?()
            return true
        }

        return false
    }

    /// Uses accumulated frames so nested label/sprite nodes remain tappable even
    /// when they are grouped inside parent button nodes.
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

private extension GameOverScreen {

    /// Adds each visual piece in the same order as the reference mockup.
    func buildScreen() {
        addChild(makeDimLayer())
        addChild(makeTitle())

        if scoreResult.isNewHighScore {
            addNewHighScoreContent()
        } else {
            addRegularHighScoreContent()
        }

        let retryButton = makeTryAgainButton()
        addChild(retryButton)
        retryButtonNode = retryButton

        let homeButton = makeHomeButton()
        addChild(homeButton)
        homeButtonNode = homeButton
    }

    // MARK: - Overlay Background

    /// Darkens gameplay using the requested brown overlay at 70% transparency.
    func makeDimLayer() -> SKNode {
        let dimBackground = SKShapeNode(rectOf: configuration.referenceScreenSize)
        dimBackground.name = "gameOverDimLayer"
        dimBackground.fillColor = gameOverOverlayBrown.withAlphaComponent(0.70)
        dimBackground.strokeColor = .clear
        dimBackground.zPosition = 0
        return dimBackground
    }

    // MARK: - Title

    /// Creates the shared `GAME OVER` title used by both result layouts.
    func makeTitle() -> SKLabelNode {
        let titleLabel = makeLabel(
            text: "GAME OVER",
            fontName: configuration.primaryFontName,
            fontSize: 58,
            color: gameOverTitleColor
        )
        titleLabel.name = "gameOverTitle"
        titleLabel.position = CGPoint(x: 0, y: 190)
        return titleLabel
    }

    // MARK: - New Highscore Layout

    /// Adds the crown, new-highscore label, and large score stack.
    func addNewHighScoreContent() {
        let crownNode = makeCrownNode()
        crownNode.position = CGPoint(x: 0, y: 104)
        addChild(crownNode)

        let newHighScoreLabel = makeLabel(
            text: "NEW HIGHSCORE",
            fontName: configuration.secondaryFontName,
            fontSize: 25,
            color: gameOverSecondaryTextColor
        )
        newHighScoreLabel.name = "gameOverNewHighScoreLabel"
        newHighScoreLabel.position = CGPoint(x: 0, y: 52)
        addChild(newHighScoreLabel)

        let scoreNode = makePrimaryScoreNode(scoreResult.distanceMeters)
        scoreNode.position = CGPoint(x: 0, y: -30)
        addChild(scoreNode)
    }

    // MARK: - Regular Highscore Layout

    /// Adds the normal result score plus saved highscore text.
    func addRegularHighScoreContent() {
        let scoreNode = makePrimaryScoreNode(scoreResult.distanceMeters)
        scoreNode.position = CGPoint(x: 0, y: 70)
        addChild(scoreNode)

        let highScoreTitleLabel = makeLabel(
            text: "YOUR HIGHSCORE",
            fontName: configuration.secondaryFontName,
            fontSize: 20,
            color: gameOverHighScoreTextColor
        )
        highScoreTitleLabel.name = "gameOverHighScoreTitle"
        highScoreTitleLabel.position = CGPoint(x: 0, y: -42)
        addChild(highScoreTitleLabel)

        let highScoreValueLabel = makeLabel(
            text: "\(scoreResult.highScoreMeters)m",
            fontName: configuration.secondaryFontName,
            fontSize: 25,
            color: gameOverHighScoreTextColor
        )
        highScoreValueLabel.name = "gameOverHighScoreValue"
        highScoreValueLabel.position = CGPoint(x: 0, y: -74)
        addChild(highScoreValueLabel)
    }

    // MARK: - Crown Symbol

    /// Uses the SF Symbol crown rendered into an orange SpriteKit texture.
    func makeCrownNode() -> SKNode {
        let crownTexture = makeTintedSymbolTexture(
            systemName: "crown",
            pointSize: 46,
            color: gameOverSecondaryTextColor.uiColor
        )
        let crownNode = SKSpriteNode(texture: crownTexture)
        crownNode.name = "gameOverCrown"
        crownNode.size = CGSize(width: 52, height: 42)
        return crownNode
    }

    /// Renders an SF Symbol with a baked-in tint because SpriteKit textures do
    /// not automatically honor UIKit template rendering after conversion.
    func makeTintedSymbolTexture(
        systemName: String,
        pointSize: CGFloat,
        color: UIColor
    ) -> SKTexture? {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        guard let symbolImage = UIImage(
            systemName: systemName,
            withConfiguration: symbolConfiguration
        )?.withRenderingMode(.alwaysTemplate) else {
            return nil
        }

        let imageSize = CGSize(width: pointSize * 1.3, height: pointSize * 1.1)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let renderedImage = renderer.image { _ in
            color.set()

            let drawRect = CGRect(
                x: (imageSize.width - symbolImage.size.width) / 2,
                y: (imageSize.height - symbolImage.size.height) / 2,
                width: symbolImage.size.width,
                height: symbolImage.size.height
            )
            symbolImage.draw(in: drawRect)
        }

        return SKTexture(image: renderedImage)
    }

    // MARK: - Score Typography

    /// Builds the large meter score with a smaller trailing `m`.
    func makePrimaryScoreNode(_ meters: Int) -> SKNode {
        let scoreNode = SKNode()
        scoreNode.name = "gameOverScore"

        let scoreLabel = makeLabel(
            text: "\(meters)",
            fontName: configuration.primaryFontName,
            fontSize: 104,
            color: gameOverScoreColor
        )
        scoreLabel.name = "gameOverScoreNumber"
        scoreLabel.position = .zero
        scoreNode.addChild(scoreLabel)

        let metersLabel = makeLabel(
            text: "m",
            fontName: configuration.primaryFontName,
            fontSize: 32,
            color: gameOverScoreColor
        )
        metersLabel.name = "gameOverScoreMeters"
        metersLabel.horizontalAlignmentMode = .left
        metersLabel.position = CGPoint(x: scoreLabel.frame.maxX + 6, y: -28)
        scoreNode.addChild(metersLabel)

        return scoreNode
    }

    // MARK: - Try Again Button

    /// Uses the imported wooden button asset as the retry touch target.
    func makeTryAgainButton() -> SKSpriteNode {
        let buttonNode = SKSpriteNode(imageNamed: NomadAsset.tryAgainButton.rawValue)
        buttonNode.name = "gameOverRetryButton"
        buttonNode.position = CGPoint(x: 0, y: -178)
        buttonNode.size = configuration.gameOverTryAgainButtonSize
        buttonNode.zPosition = 2
        return buttonNode
    }

    // MARK: - Home Button

    /// Creates the underlined Home text touch target.
    func makeHomeButton() -> SKNode {
        let homeNode = SKNode()
        homeNode.name = "gameOverHomeButton"
        homeNode.position = CGPoint(x: 0, y: -252)
        homeNode.zPosition = 3

        let homeLabel = makeLabel(
            text: "Home",
            fontName: configuration.secondaryFontName,
            fontSize: 20,
            color: gameOverSecondaryTextColor
        )
        homeLabel.name = "gameOverHomeLabel"
        homeNode.addChild(homeLabel)

        let underlineY = homeLabel.frame.minY - 2
        let underlinePath = CGMutablePath()
        underlinePath.move(to: CGPoint(x: homeLabel.frame.minX, y: underlineY))
        underlinePath.addLine(to: CGPoint(x: homeLabel.frame.maxX, y: underlineY))

        let underlineNode = SKShapeNode(path: underlinePath)
        underlineNode.name = "gameOverHomeUnderline"
        underlineNode.strokeColor = gameOverSecondaryTextColor
        underlineNode.lineWidth = 1
        homeNode.addChild(underlineNode)

        return homeNode
    }

    // MARK: - Label Factory

    /// Centralizes common label defaults for the Game Over screen.
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

// MARK: - Game Over Colors

private extension GameOverScreen {

    var gameOverTitleColor: SKColor {
        SKColor(hex: 0xE28B40)
    }

    var gameOverScoreColor: SKColor {
        SKColor(hex: 0xF6A74C)
    }

    var gameOverSecondaryTextColor: SKColor {
        SKColor(hex: 0xF6A74C)
    }

    var gameOverHighScoreTextColor: SKColor {
        SKColor(hex: 0xE28B40)
    }

    var gameOverOverlayBrown: SKColor {
        SKColor(hex: 0x49270E)
    }
}

// MARK: - SpriteKit Color Bridge

private extension SKColor {

    // MARK: - Hex Initialization

    /// Creates SpriteKit colors from the design palette's hex values.
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    // MARK: - UIKit Conversion

    /// Bridges SpriteKit color into UIKit for SF Symbol rendering.
    var uiColor: UIColor {
        self
    }
}
