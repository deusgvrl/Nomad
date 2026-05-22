//
//  DimmedStartScreen.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 20/05/26.
//

import SpriteKit

final class DimmedStartScreen: SKNode {

    // MARK: - Callback

    var onHoldStarted: (() -> Void)?

    // MARK: - UI Nodes
    
    private let dimNode = SKShapeNode()
    private let holdLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.primaryFontName
    )

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        super.init()
        name = "dimmedStartScreen"
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

private extension DimmedStartScreen {
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
        dimNode.fillColor = ColorHelper.fromHex(0x281205)
        dimNode.alpha = 0.925
        
        addChild(dimNode)
    }

    func setupLabel() {
        holdLabel.text = "HOLD TO START"
        holdLabel.fontSize = 45
        holdLabel.fontColor = ColorHelper.fromHex(0xF6A74C)
        holdLabel.horizontalAlignmentMode = .center
        holdLabel.verticalAlignmentMode = .center
        holdLabel.position = CGPoint(x: 0, y: -40)
        holdLabel.zPosition = 1

        addChild(holdLabel)
        animateLabel()
    }

    func animateLabel() {
        let fadeOut = SKAction.fadeAlpha(to: 0.35, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)

        holdLabel.run(
            SKAction.repeatForever(
                SKAction.sequence([fadeOut, fadeIn])
            )
        )
    }
}

// MARK: - Public Methods

extension DimmedStartScreen {
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
