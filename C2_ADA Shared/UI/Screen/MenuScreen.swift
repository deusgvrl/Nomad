//
//  MenuScreen.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 11/05/26.
//

import SpriteKit

final class MenuScreen: SKNode {

    // MARK: - Callback

    var onStartTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?

    // MARK: - Dependencies

    /// Shared haptics wrapper for menu buttons and the nested Settings screen.
    private let hapticsController: HapticsController

    /// Shared audio wrapper passed into Settings so its Sound toggle persists.
    private let audioController: AudioController

    // MARK: - UI Nodes

    private let backgroundNode =
    SKSpriteNode(imageNamed: "BG HOME")

    private let logoNode =
    SKSpriteNode(imageNamed: "LOGO")

    private let startButton =
    SKSpriteNode(imageNamed: "START BUTTON")

    private let settingsButton =
    SKSpriteNode(imageNamed: "SETTINGS BUTTON")
    
    private let settingsScreen: SettingsScreen

    // MARK: - Initialization

    init(
        sceneSize: CGSize,
        hapticsController: HapticsController = .shared,
        audioController: AudioController = .shared
    ) {
        self.hapticsController = hapticsController
        self.audioController = audioController
        settingsScreen = SettingsScreen(
            sceneSize: sceneSize,
            hapticsController: hapticsController,
            audioController: audioController
        )
        super.init()

        
        name = "menuScreen"
        zPosition = RenderLayer.menu

        setupBackground(sceneSize: sceneSize)
        setupLogo(sceneSize: sceneSize)
        setupButtons(sceneSize: sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension MenuScreen {

    func setupBackground(sceneSize: CGSize) {
        backgroundNode.size = sceneSize
        backgroundNode.position = .zero
        backgroundNode.zPosition = -2

        addChild(backgroundNode)

        // Radial Gradient Overlay (Berada di belakang UI)
        let gradientNode = SKSpriteNode(color: .clear, size: sceneSize)
        gradientNode.zPosition = -1 // Di atas backgroundNode tapi di belakang logo/tombol

        UIGraphicsBeginImageContext(sceneSize)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let colors = [
            ColorHelper.fromHex(0x49270E, alpha: 0.3).cgColor,  // Center: Warm Brown Tint
            ColorHelper.fromHex(0x3D200B, alpha: 1.5).cgColor,  // Mid: Rich Chocolate
            ColorHelper.fromHex(0x2b170c, alpha: 0.6).cgColor // Edges: Deep Warm Brown (not black)
        ] as CFArray
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Transisi yang lebih seimbang di seluruh layar
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.5, 1.0])
        
        let center = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        let radius = max(sceneSize.width, sceneSize.height) * 1.0 // Radius penuh untuk transisi smooth
        
        context.drawRadialGradient(
            gradient!,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: .drawsAfterEndLocation
        )
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            gradientNode.texture = SKTexture(image: image)
        }
        
        addChild(gradientNode)
    }

    func setupLogo(sceneSize: CGSize) {
        SpriteNodeHelper.resize(
            node: logoNode,
            width: sceneSize.width * 0.90
        )

        logoNode.position = CGPoint(
            x: 0,
            y: sceneSize.height * 0.28
        )

        addChild(logoNode)
    }

    func setupButtons(sceneSize: CGSize) {
        addChild(settingsScreen)
        setupStartButton(sceneSize: sceneSize)
        setupSettingsButton(sceneSize: sceneSize)
    }

    func setupStartButton(sceneSize: CGSize) {
        startButton.name = "startButton"

        SpriteNodeHelper.resize(
            node: startButton,
            width: sceneSize.width * 0.75
        )

        startButton.position = CGPoint(
            x: 0,
            y: -sceneSize.height * 0.20
        )

        addChild(startButton)
    }

    func setupSettingsButton(sceneSize: CGSize) {
        settingsButton.name = "settingsButton"
        
        SpriteNodeHelper.resize(
            node: settingsButton,
            width: sceneSize.width * 0.45
        )

        settingsButton.position = CGPoint(
            x: 0,
            y: -sceneSize.height * 0.30
        )

        addChild(settingsButton)
    }
}

// MARK: - Public Interaction

extension MenuScreen {
    func handleTouch(at location: CGPoint) {
        // Jika settings sedang tampil,
            // semua touch diarahkan ke settings overlay
        if !settingsScreen.isHidden {

            _ = settingsScreen.handleTouch(at: location)
            return
        }
        
        guard let tappedNode =
                atPoint(location) as? SKSpriteNode else {
            return
        }

        switch tappedNode.name {
        case "startButton":
            hapticsController.playLightButtonTap()
            animateButton(startButton)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.hide()
                self?.onStartTapped?()
            }

        case "settingsButton":

            hapticsController.playLightButtonTap()
            animateButton(settingsButton)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

                guard let scene = self.scene else {
                    return
                }

                self.settingsScreen.show(in: scene)
            }

        default:
            break
        }
    }

    func show(in scene: SKScene, animated: Bool = true) {
        // MARK: Menu Presentation
        // Home returns from Game Over should appear immediately so the rebuilt
        // gameplay scene does not flash behind the fading menu.
        alpha = animated ? 0 : 1
        scene.addChild(self)

        guard animated else { return }
        run(
            SKAction.fadeIn(withDuration: 0.25)
        )
    }

    func hide() {
        run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ])
        )
    }
}

// MARK: - Animation

private extension MenuScreen {
    func animateButton(_ button: SKSpriteNode) {
        let press = SKAction.scale(
            to: 0.92,
            duration: 0.05
        )
        
        let release = SKAction.scale(
            to: 1.0,
            duration: 0.05
        )
        
        button.run(
            SKAction.sequence([press, release])
        )
    }
}
