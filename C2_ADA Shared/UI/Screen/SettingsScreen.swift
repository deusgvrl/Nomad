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

    private let closeButton = SKShapeNode()
    private let closeLabel = SKLabelNode(fontNamed: "Great Lakes NF")

    // MARK: - Labels

    private let musicLabel = SKLabelNode(
        fontNamed: "Great Lakes NF"
    )

    private let hapticsLabel = SKLabelNode(
        fontNamed: "Great Lakes NF"
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

        setupCloseButton()
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

        dimNode.fillColor = SKColor(red: 0.76, green: 0.55, blue: 0.35, alpha: 1.0)
        dimNode.strokeColor = .clear
        dimNode.alpha = 1.0 // Tidak transparan (tebal)
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

    func setupCloseButton() {

        closeButton.name = "closeSettings"

        // Membuat bentuk persegi panjang tumpul (rounded rect) seperti tombol
        let btnWidth: CGFloat = 140
        let btnHeight: CGFloat = 44
        
        closeButton.path = CGPath(
            roundedRect: CGRect(
                x: -btnWidth / 2,
                y: -btnHeight / 2,
                width: btnWidth,
                height: btnHeight
            ),
            cornerWidth: 8,
            cornerHeight: 8,
            transform: nil
        )
        

        closeButton.fillColor = SKColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1.0)
        closeButton.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1.0)
        closeButton.lineWidth = 3

        closeButton.position = CGPoint(
            x: 8,
            y: -160
        )

        closeButton.zPosition = 10

        // Label CLOSE
        closeLabel.name = "closeSettings"
        closeLabel.text = "CLOSE"
        closeLabel.fontSize = 22
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 1
        
        // Agar sentuhan pada label tembus ke tombol di bawahnya
        closeLabel.isUserInteractionEnabled = false
        
        closeButton.addChild(closeLabel)
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

        musicLabel.text = "Music"

        musicLabel.fontSize = 24
        musicLabel.fontColor = labelColor
        musicLabel.horizontalAlignmentMode = .left
        musicLabel.zPosition = 1

        musicLabel.position = CGPoint(
            x: labelX,
            y: musicY
        )

        contentNode.addChild(musicLabel)

        // MARK: Music Toggle

        musicToggle.position = CGPoint(
            x: toggleX,
            y: musicY + 8
        )
        musicToggle.zPosition = 1

        contentNode.addChild(musicToggle)

        // MARK: Haptics Label

        hapticsLabel.text = "Haptics"

        hapticsLabel.fontSize = 24
        hapticsLabel.fontColor = labelColor
        hapticsLabel.horizontalAlignmentMode = .left
        hapticsLabel.zPosition = 1

        hapticsLabel.position = CGPoint(
            x: labelX,
            y: hapticsY
        )

        contentNode.addChild(hapticsLabel)

        // MARK: Haptics Toggle

        hapticsToggle.position = CGPoint(
            x: toggleX,
            y: hapticsY + 8
        )
        hapticsToggle.zPosition = 1

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
