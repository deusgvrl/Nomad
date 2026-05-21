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
        dimNode.alpha = 0.925
        
        addChild(dimNode)
    }

    func setupLabel() {
        // Menggunakan helper makeLabel dengan font primary dari registry
        let label = makeLabel(
            text: "HOLD TO START",
            fontName: GameConfiguration.standard.primaryFontName,
            fontSize: 45,
            color: SKColor(red: 246/255, green: 167/255, blue: 76/255, alpha: 1.0)
        )

        label.position = CGPoint(x: 0, y: -40)

        // Update referensi holdLabel
        holdLabel.removeFromParent() // Hapus default jika ada
        holdLabel.text = label.text
        holdLabel.fontName = label.fontName
        holdLabel.fontSize = label.fontSize
        holdLabel.fontColor = label.fontColor
        holdLabel.position = label.position

        addChild(holdLabel)
        animateLabel()
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
