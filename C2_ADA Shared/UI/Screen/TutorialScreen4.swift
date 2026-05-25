//
//  TutorialScreen4.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 25/05/26.
//

import SpriteKit

final class TutorialScreen4: SKNode {

    // MARK: - Callback

    var onHoldStarted: (() -> Void)?

    // MARK: - UI Nodes
    
    private let dimNode = SKShapeNode()
    private let pressHoldLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.primaryFontName
    )

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        super.init()
        name = "tutorialScreen4"
        zPosition = RenderLayer.dimmed

        setupDim(sceneSize: sceneSize)
        setupLabel()

        alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension TutorialScreen4 {
    func setupDim(sceneSize: CGSize) {
        dimNode.path = CGPath(
            rect: CGRect(
                origin: CGPoint(
                    x: -sceneSize.width / 2,
                    y: -sceneSize.height / 2
                ),
                size: sceneSize
            ),
            transform: nil
        )

        dimNode.strokeColor = .clear
        dimNode.fillColor = ColorHelper.fromHex(0x49270E)
        dimNode.alpha = 0.70
        
        addChild(dimNode)
    }

    func setupLabel() {
        pressHoldLabel.text = "PRESS & HOLD TO LATCH"
        pressHoldLabel.fontSize = 28 // Ukuran diperkecil
        pressHoldLabel.fontColor = ColorHelper.fromHex(0xF6A74C)
        pressHoldLabel.horizontalAlignmentMode = .center
        pressHoldLabel.verticalAlignmentMode = .center
        
        // Posisi label di tengah atas
        pressHoldLabel.position = CGPoint(x: 0, y: 200)
        pressHoldLabel.zPosition = 1

        addChild(pressHoldLabel)
        animateLabel()
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

extension TutorialScreen4 {
    func show(in scene: SKScene) {
        scene.addChild(self)
        run(SKAction.fadeIn(withDuration: 0.25))
    }

    func hide() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }

    func beginHold() {
        hide()
        onHoldStarted?()
    }
}
