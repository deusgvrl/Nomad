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

    init(sceneSize: CGSize) {
        super.init()

        name = "settingsScreen"

        zPosition = RenderLayer.settings
        alpha = 0
        isHidden = true

        setupDim(sceneSize: sceneSize)
        setupBlock(sceneSize: sceneSize)

        addChild(contentNode)

        setupCloseButton(sceneSize: sceneSize)
        setupContent()
        setupCallbacks()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension SettingsScreen {

    func setupDim(sceneSize: CGSize) {

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
        dimNode.alpha = 0.85
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

            self?.onMusicChanged?(isOn)
        }

        hapticsToggle.onToggleChanged = {
            [weak self] isOn in

            self?.onHapticsChanged?(isOn)
        }
    }
}

// MARK: - Public Functions

extension SettingsScreen {

    func show(in scene: SKScene) {

        isHidden = false

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

                SKAction.fadeOut(
                    withDuration: 0.2
                ),

                SKAction.run {
                    self.isHidden = true
                }
            ])
        )
    }

    func handleTouch(at location: CGPoint) {

        // Konversi lokasi sentuhan ke koordinat contentNode
        let pointInContent = convert(
            location,
            to: contentNode
        )

        // MARK: - Manual Hitbox Close Button
        // Diperkecil agar area transparan asset
        // tidak ikut terdeteksi sebagai sentuhan.

        let hitboxWidth =
        closeButton.size.width * 0.55

        let hitboxHeight =
        closeButton.size.height * 0.12

        let hitboxRect = CGRect(
            x: closeButton.position.x - hitboxWidth / 2 - 10,
            y: closeButton.position.y - hitboxHeight / 2 - 100,
            width: hitboxWidth,
            height: hitboxHeight
        )

        // DEBUG HITBOX
        // Uncomment jika ingin melihat area sentuh asli

        /*
        contentNode
            .childNode(withName: "debugHitbox")?
            .removeFromParent()

        let debugNode = SKShapeNode(
            rect: hitboxRect
        )

        debugNode.name = "debugHitbox"
        debugNode.strokeColor = .red
        debugNode.lineWidth = 2
        debugNode.zPosition = 999

        contentNode.addChild(debugNode)
        */

        // Deteksi hanya jika sentuhan
        // benar-benar di area tombol

        if hitboxRect.contains(pointInContent) {

            animateButton(closeButton)

            hide()

            return
        }
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
