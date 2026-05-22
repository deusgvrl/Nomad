//
//  SettingsScreen.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 21/05/26.
//

import SpriteKit

final class SettingsScreen: SKNode {

    // MARK: - Callback

    var onMusicChanged: ((Bool) -> Void)?
    var onHapticsChanged: ((Bool) -> Void)?
    var onClosed: (() -> Void)?

    // MARK: - Dependencies

    /// Shared haptics wrapper used for settings buttons and toggle state.
    ///
    /// Settings owns the Haptics toggle, so it also mirrors the saved haptics
    /// preference and forwards changes back into the controller.
    private let hapticsController: HapticsController

    // MARK: - Overlay Nodes

    private let dimNode = SKShapeNode()

    private let settingsBlock =
    SKSpriteNode(imageNamed: "SETTINGS BLOCK")

    // Container khusus isi settings
    // supaya layout tidak ikut kacau oleh scaling asset
    private let contentNode = SKNode()

    private let closeButton = SKSpriteNode(imageNamed: "BACK BUTTON")

    // MARK: - Labels

    private let musicLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.secondaryFontName
    )

    private let hapticsLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.secondaryFontName
    )

    // MARK: - Toggles

    private let musicToggle = ToggleSwitchNode()

    private let hapticsToggle = ToggleSwitchNode()

    // MARK: - Init

    init(
        sceneSize: CGSize,
        hapticsController: HapticsController = .shared, dimAlpha: CGFloat = 0.85
    ) {
        self.hapticsController = hapticsController
        super.init()

        name = "settingsScreen"

        zPosition = RenderLayer.settings
        alpha = 0
        isHidden = true

        setupDim(sceneSize: sceneSize, alpha: dimAlpha)
        setupBlock(sceneSize: sceneSize)

        addChild(contentNode)

        setupCloseButton(sceneSize: sceneSize)
        setupContent()
        syncStoredPreferences()
        setupCallbacks()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension SettingsScreen {

    func setupDim(sceneSize: CGSize, alpha: CGFloat) {

        dimNode.path = CGPath(
            rect: CGRect(
                x: -sceneSize.width / 2,
                y: -sceneSize.height / 2,
                width: sceneSize.width,
                height: sceneSize.height
            ),
            transform: nil
        )

        dimNode.fillColor = .black
        dimNode.strokeColor = .clear
        dimNode.alpha = alpha
        dimNode.zPosition = -1

        addChild(dimNode)
    }

    func setupBlock(sceneSize: CGSize) {

        SpriteNodeHelper.resize(
            node: settingsBlock,
            width: sceneSize.width * 1.05
        )

        // Naikkan ke atas dan geser sedikit saja ke kiri
        settingsBlock.position = CGPoint(
            x: -6,
            y: 50
        )

        addChild(settingsBlock)
    }

    func setupCloseButton(sceneSize: CGSize) {

        closeButton.name = "closeSettings"

        // Perkecil button agar pas di dalam block
        SpriteNodeHelper.resize(
            node: closeButton,
            width: settingsBlock.size.width * 1
        )

        // Letakkan di bagian bawah relatif terhadap contentNode
        closeButton.position = CGPoint(
            x: 8,
            y: -5
        )

        closeButton.zPosition = 10
        closeButton.setScale(1.0)

        contentNode.addChild(closeButton)
    }

    func setupContent() {

        // Sinkron dengan posisi panel
        contentNode.position = settingsBlock.position
        contentNode.zPosition = 5

        let labelColor = ColorHelper.fromHex(0x934f23)
        // labelX & toggleX: (-) ke kiri, (+) ke kanan
        let labelX: CGFloat = -115
        let toggleX: CGFloat = 75

        // musicY & hapticsY: (+) naik ke atas, (-) turun ke bawah
        let musicY: CGFloat = 23
        let hapticsY: CGFloat = -23        
        // Skala pengecil untuk toggle (lebih kecil lagi)
        let toggleScale: CGFloat = 0.50

        // MARK: Music Label
        musicLabel.text = "Music"
        musicLabel.fontSize = 24
        musicLabel.fontColor = labelColor
        musicLabel.horizontalAlignmentMode = .left
        musicLabel.position = CGPoint(x: labelX, y: musicY)
        musicLabel.zPosition = 1
        contentNode.addChild(musicLabel)

        // MARK: Music Toggle
        musicToggle.position = CGPoint(x: toggleX, y: musicY + 8)
        musicToggle.zPosition = 20
        musicToggle.setScale(toggleScale)
        contentNode.addChild(musicToggle)

        // MARK: Haptics Label
        hapticsLabel.text = "Haptics"
        hapticsLabel.fontSize = 24
        hapticsLabel.fontColor = labelColor
        hapticsLabel.horizontalAlignmentMode = .left
        hapticsLabel.position = CGPoint(x: labelX, y: hapticsY)
        hapticsLabel.zPosition = 1
        contentNode.addChild(hapticsLabel)

        // MARK: Haptics Toggle
        hapticsToggle.position = CGPoint(x: toggleX, y: hapticsY + 8)
        hapticsToggle.zPosition = 20
        hapticsToggle.setScale(toggleScale)
        contentNode.addChild(hapticsToggle)
    }

    func setupCallbacks() {

        musicToggle.onToggleChanged = {
            [weak self] isOn in

            self?.hapticsController.playLightButtonTap()
            self?.onMusicChanged?(isOn)
        }

        hapticsToggle.onToggleChanged = {
            [weak self] isOn in

            // MARK: Haptics Toggle Feedback
            // Play the tap before applying the new value. That lets the player
            // feel the "turn off" tap while haptics are still enabled, and the
            // controller will no-op if haptics were already disabled.
            self?.hapticsController.playLightButtonTap()
            self?.hapticsController.setHapticsEnabled(isOn)
            self?.onHapticsChanged?(isOn)
        }
    }

    // MARK: - Stored Preferences

    /// Mirrors persisted settings into the visible toggles without firing their
    /// callbacks during setup.
    func syncStoredPreferences() {
        hapticsToggle.setIsOn(
            hapticsController.isHapticsEnabled,
            animated: false
        )
    }
}

// MARK: - Public Functions

extension SettingsScreen {

    func show(in scene: SKScene) {

        isHidden = false
        closeButton.setScale(1.0)
        closeButton.removeAllActions()

        if parent == nil {
            scene.addChild(self)
        }

        run(
            SKAction.fadeIn(withDuration: 0.1)
        )
    }

    func hide() {
        run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.run { 
                    self.isHidden = true
                    self.removeFromParent()
                }
            ])
        )
    }

    func handleTouch(at location: CGPoint) -> Bool {
        // Konversi lokasi sentuhan ke koordinat contentNode
        let pointInContent = convert(location, to: contentNode)

        // MARK: - Manual Hitbox Close Button
        // Sesuaikan nilai ini (0.0 - 1.0) untuk mempersempit area sentuh.
        let hitboxWidth = closeButton.size.width * 0.55
        let hitboxHeight = closeButton.size.height * 0.125

        let hitboxRect = CGRect(
            x: closeButton.position.x - hitboxWidth / 2 - 15,
            y: closeButton.position.y - hitboxHeight / 2 - 100,
            width: hitboxWidth,
            height: hitboxHeight
        )

        // MARK: - Debug Hitbox
        /*
        contentNode.childNode(withName: "debugHitbox")?.removeFromParent()
        let debugNode = SKShapeNode(rect: hitboxRect)
        debugNode.name = "debugHitbox"
        debugNode.strokeColor = .red
        debugNode.lineWidth = 2
        debugNode.zPosition = 999
        contentNode.addChild(debugNode)
        */
         
    
        // Deteksi sentuhan tepat di area tombol
        if hitboxRect.contains(pointInContent) {
            
            // Animasi tekan sebelum menutup
            let scaleDown = SKAction.scale(to: 0.92, duration: 0.05)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.05)
            let close = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.hide() 
                self.onClosed?()
                hapticsController.playLightButtonTap()
            }

            closeButton.run(SKAction.sequence([scaleDown, scaleUp, close]))
            return true
        }

        return false
    }
}

// MARK: - Animation

private extension SettingsScreen {

    func animateButton(_ node: SKNode) {

        let press = SKAction.scale(
            to: 0.95,
            duration: 0.05
        )

        let release = SKAction.scale(
            to: 1.0,
            duration: 0.05
        )

        node.run(
            SKAction.sequence([
                press,
                release
            ])
        )
    }
}
