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

        zPosition = 10000
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
            x: -8,
            y: 50
        )

        addChild(settingsBlock)
    }

    func setupCloseButton(sceneSize: CGSize) {

        closeButton.name = "closeSettings"

        // Samakan lebar dengan settingsBlock (1.05 * sceneSize.width)
        // SpriteNodeHelper.resize otomatis menjaga aspek rasio
        SpriteNodeHelper.resize(
            node: closeButton,
            width: sceneSize.width * 0.75
        )
        closeButton.size.height *= 0.8

        // Posisi di paling bawah layar. 
        // Dihitung relatif terhadap contentNode agar tetap sejajar secara horizontal (x: 0)
        // y: -sceneSize.height * 0.45 menempatkannya di dekat tepi bawah layar
        closeButton.position = CGPoint(
            x: 6,
            y: -sceneSize.height * 0.43 - settingsBlock.position.y
        )

        closeButton.zPosition = 10

        contentNode.addChild(closeButton)
    }

    func setupContent() {

        // Sinkron dengan posisi panel
        contentNode.position = settingsBlock.position
        contentNode.zPosition = 5

        let labelColor = SKColor(red: 0.38, green: 0.22, blue: 0.15, alpha: 1.0)
        let labelX: CGFloat = -115
        let toggleX: CGFloat = 85
        let musicY: CGFloat = -15
        let hapticsY: CGFloat = -75

        // MARK: Music Label

        let musicLabelNode = makeLabel(
            text: "Music",
            fontName: GameConfiguration.standard.secondaryFontName,
            fontSize: 24,
            color: labelColor
        )
        musicLabelNode.horizontalAlignmentMode = .left
        musicLabelNode.position = CGPoint(x: labelX, y: musicY)
        
        // Copy properties to private node
        musicLabel.text = musicLabelNode.text
        musicLabel.fontName = musicLabelNode.fontName
        musicLabel.fontSize = musicLabelNode.fontSize
        musicLabel.fontColor = musicLabelNode.fontColor
        musicLabel.horizontalAlignmentMode = musicLabelNode.horizontalAlignmentMode
        musicLabel.position = musicLabelNode.position
        musicLabel.zPosition = 1

        contentNode.addChild(musicLabel)

        // MARK: Music Toggle

        musicToggle.position = CGPoint(
            x: toggleX,
            y: musicY + 8
        )
        musicToggle.zPosition = 1

        contentNode.addChild(musicToggle)

        // MARK: Haptics Label

        let hapticsLabelNode = makeLabel(
            text: "Haptics",
            fontName: GameConfiguration.standard.secondaryFontName,
            fontSize: 24,
            color: labelColor
        )
        hapticsLabelNode.horizontalAlignmentMode = .left
        hapticsLabelNode.position = CGPoint(x: labelX, y: hapticsY)

        // Copy properties to private node
        hapticsLabel.text = hapticsLabelNode.text
        hapticsLabel.fontName = hapticsLabelNode.fontName
        hapticsLabel.fontSize = hapticsLabelNode.fontSize
        hapticsLabel.fontColor = hapticsLabelNode.fontColor
        hapticsLabel.horizontalAlignmentMode = hapticsLabelNode.horizontalAlignmentMode
        hapticsLabel.position = hapticsLabelNode.position
        hapticsLabel.zPosition = 1

        contentNode.addChild(hapticsLabel)

        // MARK: Haptics Toggle

        hapticsToggle.position = CGPoint(
            x: toggleX,
            y: hapticsY + 8
        )
        hapticsToggle.zPosition = 1

        contentNode.addChild(hapticsToggle)
    }

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

        let tappedNode = atPoint(location)

        switch tappedNode.name {

        case "closeSettings":

            animateButton(closeButton)
            self.hide()

        default:
            break
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
