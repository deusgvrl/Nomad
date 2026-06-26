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
    
    private weak var targetNode: SKNode?

    // MARK: - Initialization

    init(sceneSize: CGSize, targetNode: SKNode? = nil) {
        self.targetNode = targetNode
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
        dimNode.strokeColor = .clear
        dimNode.fillColor = ColorHelper.fromHex(0x49270E)
        dimNode.alpha = 0.70

        addChild(dimNode)
        updateDimPath(sceneSize: sceneSize)
    }

    func updateDimPath(sceneSize: CGSize) {
        let screenRect = CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height)
        let path = UIBezierPath(rect: screenRect)

        let holePos: CGPoint
        if let target = targetNode, let parent = target.parent, let scene = scene {
            // Convert target position to scene space
            let scenePos = scene.convert(target.position, from: parent)
            // Match the offset in GameScene for targetTutorialHighlightNode
            holePos = CGPoint(
                x: scenePos.x - 2,
                y: scenePos.y + 35
            )
        } else {
            holePos = .zero
        }

        let radius: CGFloat = 85
        let holeRect = CGRect(
            x: holePos.x - radius,
            y: holePos.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        let holePath = UIBezierPath(ovalIn: holeRect)
        path.append(holePath.reversing())

        dimNode.path = path.cgPath
    }

    func setupLabel() {
        pressHoldLabel.text = "PRESS & HOLD TO LATCH"
        pressHoldLabel.fontSize = 28
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
    
    func update() {
        if let scene = scene {
            updateDimPath(sceneSize: scene.size)
        }
    }
}
