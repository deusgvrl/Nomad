//
//  PauseScreen.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 21/05/26.
//

import SpriteKit

final class PauseScreen: SKNode {

    // MARK: - Callback

    var onResume: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onHomeTapped: (() -> Void)?

    // MARK: - Dependencies

    let resumeGameState: GameState
    private let configuration: GameConfiguration

    /// Shared haptics wrapper used by the Resume button.
    private let hapticsController: HapticsController

    // MARK: - Touch Targets

    private let dimNode = SKShapeNode()
    private let pauseBlock = SKSpriteNode(imageNamed: "PAUSED BLOCK")
    private let resumeButton = SKSpriteNode(imageNamed: "RESUME BUTTON")
    private let settingsButton = SKSpriteNode(imageNamed: "PAUSED SETTINGS BUTTON")
    private let homeButton = SKSpriteNode(imageNamed: "HOME BUTTON")

    // MARK: - Init

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
        zPosition = RenderLayer.pause
        alpha = 0

        setupDim()
        setupPanel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

// MARK: - Setup

private extension PauseScreen {

    func setupDim() {
        dimNode.path = CGPath(
            rect: CGRect(
                x: -configuration.referenceScreenSize.width / 2,
                y: -configuration.referenceScreenSize.height / 2,
                width: configuration.referenceScreenSize.width,
                height: configuration.referenceScreenSize.height
            ),
            transform: nil
        )

        // Menggunakan warna dim yang sudah ada
        dimNode.fillColor = ColorHelper.fromHex(0x49270E, alpha: 0.58)
        dimNode.strokeColor = .clear
        dimNode.zPosition = 0
        addChild(dimNode)
    }

    func setupPanel() {
        // 1. Pause Block
        SpriteNodeHelper.resize(
            node: pauseBlock,
            width: configuration.referenceScreenSize.width * 1.05
        )
        pauseBlock.position = CGPoint(x: -10, y: 30)
        pauseBlock.zPosition = 1
        addChild(pauseBlock)

        // 2. Resume Button
        resumeButton.name = "resumeButton"
        SpriteNodeHelper.resize(
            node: resumeButton,
            width: pauseBlock.size.width * 0.96
        )
        // diletakkan di dalam block bagian atas sedikit
        resumeButton.position = CGPoint(x: 5, y: -10)
        resumeButton.zPosition = 2
        pauseBlock.addChild(resumeButton)

        // 3. Settings Button (Dikecilkan agar muat berdampingan)
        settingsButton.name = "pauseSettingsButton"
        SpriteNodeHelper.resize(
            node: settingsButton,
            width: pauseBlock.size.width * 0.35
        )
        // diletakkan di bawah resume button, sebelah kanan
        settingsButton.position = CGPoint(x: 75, y: -75)
        settingsButton.zPosition = 2
        pauseBlock.addChild(settingsButton)

        // 4. Home Button (Sprite-based)
        homeButton.name = "pauseHomeButton"
        SpriteNodeHelper.resize(
            node: homeButton,
            width: pauseBlock.size.width * 0.35
        )
        // diletakkan di sebelah kiri settings button
        homeButton.position = CGPoint(x: -60, y: -75)
        homeButton.zPosition = 2
        pauseBlock.addChild(homeButton)
    }
}

// MARK: - Public Methods

extension PauseScreen {

    func present() {
        run(SKAction.fadeIn(withDuration: 0.12))
    }

    func dismiss(completion: @escaping () -> Void) {
        run(SKAction.fadeOut(withDuration: 0.10), completion: completion)
    }

    func handleTouch(at location: CGPoint) -> Bool {
        // Konversi lokasi sentuhan ke koordinat pauseBlock (tempat button berada)
        let pointInBlock = convert(location, to: pauseBlock)

        // MARK: - Hitbox Detection
        
        // Resume Button
        if isPointInHitbox(pointInBlock, node: resumeButton, widthMult: 0.8, heightMult: 0.6) {
            animateButton(resumeButton)
            onResume?()
            return true
        }

        // Settings Button
        if isPointInHitbox(pointInBlock, node: settingsButton, widthMult: 0.8, heightMult: 0.6) {
            animateButton(settingsButton)
            onSettingsTapped?()
            return true
        }

        // Home Button Hitbox
        if isPointInHitbox(pointInBlock, node: homeButton, widthMult: 0.8, heightMult: 0.6) {
            animateButton(homeButton)
            onHomeTapped?()
            return true
        }

        return false
    }

    private func isPointInHitbox(_ point: CGPoint, node: SKSpriteNode, widthMult: CGFloat, heightMult: CGFloat) -> Bool {
        let hitboxWidth = node.size.width * widthMult
        let hitboxHeight = node.size.height * heightMult
        
        let hitboxRect = CGRect(
            x: node.position.x - hitboxWidth / 2,
            y: node.position.y - hitboxHeight / 2,
            width: hitboxWidth,
            height: hitboxHeight
        )
        
        return hitboxRect.contains(point)
    }

    private func animateButton(_ node: SKNode) {
        let press = SKAction.scale(to: 0.95, duration: 0.05)
        let release = SKAction.scale(to: 1.0, duration: 0.05)
        node.run(SKAction.sequence([press, release]))
    }

    private func animateLabel(_ node: SKLabelNode) {
        let press = SKAction.scale(to: 0.9, duration: 0.05)
        let release = SKAction.scale(to: 1.0, duration: 0.05)
        node.run(SKAction.sequence([press, release]))
    }
}
