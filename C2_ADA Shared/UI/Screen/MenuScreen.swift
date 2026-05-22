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

    // MARK: - UI Nodes

    private let backgroundNode =
    SKSpriteNode(imageNamed: "BACKGROUND")

    private let logoNode =
    SKSpriteNode(imageNamed: "LOGO")

    private let startButton =
    SKSpriteNode(imageNamed: "START BUTTON")

    private let settingsButton =
    SKSpriteNode(imageNamed: "SETTINGS BUTTON")
    
    private let settingsScreen: SettingsScreen

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        settingsScreen = SettingsScreen(sceneSize: sceneSize)
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

        // Dark Overlay
        let dim = SKShapeNode(rectOf: sceneSize)

        dim.fillColor = .black
        dim.strokeColor = .clear
        dim.alpha = 0.35
        dim.zPosition = -1

        addChild(dim)
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
            animateButton(startButton)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.hide()
                self.onStartTapped?()
            }

        case "settingsButton":

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
