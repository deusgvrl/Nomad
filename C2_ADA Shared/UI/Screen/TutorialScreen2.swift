//
//  TutorialScreen2.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 25/05/26.
//

import SpriteKit

final class TutorialScreen2: SKNode {

    // MARK: - Callback
    var onDismissed: (() -> Void)?

    // MARK: - UI Nodes
    private let dimNode = SKShapeNode()
    private let leftArrow = SKShapeNode()
    private let rightArrow = SKShapeNode()
    private let steerLabel = SKLabelNode(
        fontNamed: GameConfiguration.standard.primaryFontName
    )
    
    private weak var targetNode: SKNode?

    // MARK: - Initialization
    init(sceneSize: CGSize, targetNode: SKNode? = nil) {
        self.targetNode = targetNode
        super.init()
        name = "tutorialScreen2"
        zPosition = RenderLayer.dimmed

        setupDim(sceneSize: sceneSize)
        setupArrows()
        setupLabel()

        alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
private extension TutorialScreen2 {
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
            let scenePos = scene.convert(target.position, from: parent)
            holePos = CGPoint(x: scenePos.x - 3, y: scenePos.y + 25)
        } else {
            let config = GameConfiguration.standard
            holePos = CGPoint(x: config.currentVehiclePosition.x - 3, y: config.currentVehiclePosition.y + 25)
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

    func createArrowPath() -> CGPath {
        let path = CGMutablePath()
        // Menggambar panah sederhana
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 15))
        path.addLine(to: CGPoint(x: 20, y: 5))
        path.addLine(to: CGPoint(x: 45, y: 5))
        path.addLine(to: CGPoint(x: 45, y: -5))
        path.addLine(to: CGPoint(x: 20, y: -5))
        path.addLine(to: CGPoint(x: 20, y: -15))
        path.closeSubpath()
        return path
    }

    func setupArrows() {
        let config = GameConfiguration.standard
        let visualCenterY = config.currentVehiclePosition.y + 60
        let arrowPath = createArrowPath()
        
        // Setup Left Arrow
        leftArrow.path = arrowPath
        leftArrow.strokeColor = ColorHelper.fromHex(0xF6A74C)
        leftArrow.fillColor = ColorHelper.fromHex(0xF6A74C)
        leftArrow.position = CGPoint(x: -60, y: visualCenterY + 40)
        
        // Setup Right Arrow (Mirror)
        rightArrow.path = arrowPath
        rightArrow.strokeColor = ColorHelper.fromHex(0xF6A74C)
        rightArrow.fillColor = ColorHelper.fromHex(0xF6A74C)
        rightArrow.zRotation = .pi // Putar 180 derajat
        rightArrow.position = CGPoint(x: 60, y: visualCenterY + 40)
        
        addChild(leftArrow)
        addChild(rightArrow)
        
        animateArrows()
    }

    func setupLabel() {
        steerLabel.text = "DRAG LEFT & RIGHT TO STEER"
        steerLabel.fontSize = 32
        steerLabel.fontColor = ColorHelper.fromHex(0xF6A74C)
        steerLabel.horizontalAlignmentMode = .center
        steerLabel.verticalAlignmentMode = .center
        
        let config = GameConfiguration.standard
        let visualCenterY = config.currentVehiclePosition.y + 35
        steerLabel.position = CGPoint(x: 0, y: visualCenterY + 150)
        steerLabel.zPosition = 1

        addChild(steerLabel)
        animateLabel()
    }

    func animateArrows() {
        let moveDist: CGFloat = 20
        let duration: TimeInterval = 0.6
        
        let moveLeft = SKAction.moveBy(x: -moveDist, y: 0, duration: duration)
        let moveBackLeft = SKAction.moveBy(x: moveDist, y: 0, duration: duration)
        leftArrow.run(SKAction.repeatForever(SKAction.sequence([moveLeft, moveBackLeft])))
        
        let moveRight = SKAction.moveBy(x: moveDist, y: 0, duration: duration)
        let moveBackRight = SKAction.moveBy(x: -moveDist, y: 0, duration: duration)
        rightArrow.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveBackRight])))
    }

    func animateLabel() {
        let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 0.6)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        steerLabel.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }
}

// MARK: - Public Methods
extension TutorialScreen2 {
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

    func dismiss() {
        hide()
        onDismissed?()
    }
    
    func update() {
        if let scene = scene {
            updateDimPath(sceneSize: scene.size)
        }
    }
}
