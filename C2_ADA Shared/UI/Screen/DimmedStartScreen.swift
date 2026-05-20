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
    private let holdLabel = SKLabelNode(fontNamed: "Great Lakes Nf Bold")

    // MARK: - Initialization

    init(sceneSize: CGSize) {
        super.init()
        name = "dimmedStartScreen"
        zPosition = 10000

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
        dimNode.fillColor = SKColor(
            red: 40/255,
            green: 18/255,
            blue: 5/255,
            alpha: 1.0
        )
        dimNode.alpha = 0.78
        
        addChild(dimNode)
    }

    func setupLabel() {
        holdLabel.text = "HOLD TO START"
        holdLabel.fontName = "Great Lakes Nf Bold"
        holdLabel.fontSize = 34
        holdLabel.fontColor = SKColor(
            red: 246/255,
            green: 167/255,
            blue: 76/255,
            alpha: 1.0
        )
        
        holdLabel.position = CGPoint(x: 0, y: -40)
        
        addChild(holdLabel)
        animateLabel()
    }

    func animateLabel() {
        let fadeOut = SKAction.fadeAlpha(to: 0.35, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)

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
