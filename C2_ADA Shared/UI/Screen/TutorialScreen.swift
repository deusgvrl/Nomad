//
//  TutorialScreen.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 25/05/26.
//

import SpriteKit

final class TutorialScreen: SKNode {

    // MARK: - Callback

    var onHoldStarted: (() -> Void)?

    // MARK: - UI Nodes
    
    private let dimNode = SKShapeNode()
    private let tutorialCircle = SKShapeNode()
    private let pressHoldLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.primaryFontName
    )

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        super.init()
        name = "tutorialScreen"
        zPosition = RenderLayer.dimmed

        setupDim(sceneSize: sceneSize)
        setupTutorialCircle()
        setupLabel()

        alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension TutorialScreen {
    func setupDim(sceneSize: CGSize) {
        let screenRect = CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height)
        let path = UIBezierPath(rect: screenRect)
        
        // Hole rect (Circle area)
        let config = GameConfiguration.standard
        let visualCenter = CGPoint(
            x: config.currentVehiclePosition.x - 3,
            y: config.currentVehiclePosition.y + 25
        )
        let radius: CGFloat = 80
        let holeRect = CGRect(
            x: visualCenter.x - radius,
            y: visualCenter.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        
        // Menambahkan lingkaran dengan arah terbalik untuk membuat lubang
        let holePath = UIBezierPath(ovalIn: holeRect)
        path.append(holePath.reversing())

        dimNode.path = path.cgPath
        dimNode.strokeColor = .clear
        dimNode.fillColor = ColorHelper.fromHex(0x49270E)
        dimNode.alpha = 0.70
        
        addChild(dimNode)
    }

    func setupTutorialCircle() {
        let config = GameConfiguration.standard
        
        // Menyesuaikan titik tengah agar pas di antara kendaraan dan pemain
        let visualCenter = CGPoint(
            x: config.currentVehiclePosition.x - 3,
            y: config.currentVehiclePosition.y + 25
        )
        
        let radius: CGFloat = 65
        tutorialCircle.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        tutorialCircle.strokeColor = ColorHelper.fromHex(0xF6A74C)
        tutorialCircle.lineWidth = 4
        tutorialCircle.fillColor = .clear
        tutorialCircle.position = visualCenter
        
        addChild(tutorialCircle)
        animateCircle()
    }

    func setupLabel() {
        pressHoldLabel.text = "PRESS & HOLD"
        pressHoldLabel.fontSize = 40
        pressHoldLabel.fontColor = ColorHelper.fromHex(0xF6A74C)
        pressHoldLabel.horizontalAlignmentMode = .center
        pressHoldLabel.verticalAlignmentMode = .center
        
        let config = GameConfiguration.standard
        let visualCenterY = config.currentVehiclePosition.y + 35
        
        pressHoldLabel.position = CGPoint(x: 0, y: visualCenterY + 150)
        pressHoldLabel.zPosition = 1

        addChild(pressHoldLabel)
        animateLabel()
    }

    func animateCircle() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.6)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
        tutorialCircle.run(
            SKAction.repeatForever(
                SKAction.sequence([scaleUp, scaleDown])
            )
        )
    }

    func animateLabel() {
        let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 0.6)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.6)

        pressHoldLabel.run(
            SKAction.repeatForever(
                SKAction.sequence([fadeOut, fadeIn])
            )
        )
    }
}

// MARK: - Public Methods

extension TutorialScreen {
    func show(in scene: SKScene) {
        scene.addChild(self)
        
        run(
            SKAction.fadeIn(withDuration: 0.25)
        )
    }

    func hide() {
        run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ])
        )
    }

    func beginHold() {
        hide()
        onHoldStarted?()
    }
}
