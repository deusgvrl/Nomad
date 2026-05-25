//
//  TutorialScreen3.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 25/05/26.
//

import SpriteKit

final class TutorialScreen3: SKNode {

    // MARK: - Callback

    var onReleaseStarted: (() -> Void)?

    // MARK: - UI Nodes
    
    private let dimNode = SKShapeNode()
    private let tutorialCircle = SKShapeNode()
    private let releaseJumpLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.primaryFontName
    )
    
    private weak var targetNode: SKNode?

    // MARK: - Initialization

    init(sceneSize: CGSize, targetNode: SKNode? = nil) {
        self.targetNode = targetNode
        super.init()
        name = "tutorialScreen3"
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

private extension TutorialScreen3 {
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

    func setupTutorialCircle() {
        let radius: CGFloat = 65
        tutorialCircle.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        tutorialCircle.strokeColor = ColorHelper.fromHex(0xF6A74C)
        tutorialCircle.lineWidth = 4
        tutorialCircle.fillColor = .clear
        
        // Initial position
        updateCirclePosition()
        
        addChild(tutorialCircle)
        animateCircle()
    }

    func setupLabel() {
        releaseJumpLabel.text = "RELEASE TO JUMP"
        releaseJumpLabel.fontSize = 40
        releaseJumpLabel.fontColor = ColorHelper.fromHex(0xF6A74C)
        releaseJumpLabel.horizontalAlignmentMode = .center
        releaseJumpLabel.verticalAlignmentMode = .center
        
        let config = GameConfiguration.standard
        let visualCenterY = config.currentVehiclePosition.y + 35
        
        releaseJumpLabel.position = CGPoint(x: 0, y: visualCenterY + 150)
        releaseJumpLabel.zPosition = 1

        addChild(releaseJumpLabel)
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

        releaseJumpLabel.run(
            SKAction.repeatForever(
                SKAction.sequence([fadeOut, fadeIn])
            )
        )
    }
    
    func updateCirclePosition() {
        if let target = targetNode {
            // Menyesuaikan titik tengah agar pas di mobil
            tutorialCircle.position = CGPoint(
                x: target.position.x - 3,
                y: target.position.y + 25
            )
        } else {
            let config = GameConfiguration.standard
            tutorialCircle.position = CGPoint(
                x: config.currentVehiclePosition.x - 3,
                y: config.currentVehiclePosition.y + 25
            )
        }
    }
}

// MARK: - Public Methods

extension TutorialScreen3 {
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

    func beginRelease() {
        hide()
        onReleaseStarted?()
    }
    
    func update() {
        updateCirclePosition()
    }
}
