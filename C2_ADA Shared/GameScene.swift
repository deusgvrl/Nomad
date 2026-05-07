//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import SpriteKit

final class GameScene: SKScene {

    private let configuration: GameConfiguration
    private let isometricProjector: IsometricProjector
    private let inputSystem = InputSystem()
    private let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem
    private let latchSystem: LatchSystem

    private var flowState: GameFlowState = .waitingToStart
    private var playerEntity: PlayerEntity?
    private var currentVehicleEntity: VehicleEntity?
    private var nextVehicleEntity: VehicleEntity?
    private var gameOverOverlayNode: SKNode?
    private var lastUpdateTime: TimeInterval = 0

    class func newGameScene() -> GameScene {
        let configuration = GameConfiguration.standard
        let scene = GameScene(size: configuration.referenceScreenSize, configuration: configuration)
        scene.scaleMode = .aspectFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }

    init(size: CGSize, configuration: GameConfiguration = .standard) {
        self.configuration = configuration
        self.isometricProjector = IsometricProjector(viewAngleInDegrees: configuration.isometricViewAngleInDegrees)
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: configuration)
        self.latchSystem = LatchSystem(configuration: configuration)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .standard
        self.isometricProjector = IsometricProjector(viewAngleInDegrees: GameConfiguration.standard.isometricViewAngleInDegrees)
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: .standard)
        self.latchSystem = LatchSystem(configuration: .standard)
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = makeDeltaTime(from: currentTime)
        guard let playerEntity else { return }

        if flowState == .jumping {
            let launchResult = launchSystem.update(player: playerEntity, deltaTime: deltaTime)
            if let nextVehicleEntity, latchSystem.canLatch(player: playerEntity, onto: nextVehicleEntity) {
                completeLatch(on: nextVehicleEntity)
            } else if launchResult == .fell {
                enterGameOver()
            }
        }
    }

    private func setUpScene() {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)

        addChild(makeFloorNode())
        addChild(makePlayableBoundsGuide())
        addObstacleLayoutNodes()

        let vehicleEntity = VehicleEntity(configuration: configuration)
        vehicleEntity.setPosition(configuration.currentVehiclePosition)

        let nextVehicleEntity = VehicleEntity(configuration: configuration)
        nextVehicleEntity.setPosition(configuration.nextVehiclePosition)

        let playerEntity = PlayerEntity(configuration: configuration)
        playerEntity.place(on: vehicleEntity)

        addChild(vehicleEntity.node)
        addChild(nextVehicleEntity.node)
        addChild(playerEntity.node)

        self.currentVehicleEntity = vehicleEntity
        self.nextVehicleEntity = nextVehicleEntity
        self.playerEntity = playerEntity
        self.gameOverOverlayNode = nil
        self.flowState = .waitingToStart
    }

    private func handle(_ inputPhase: InputPhase) {
        guard let playerEntity, let currentVehicleEntity else { return }
        playerEntity.recordInput(inputPhase)

        switch (flowState, inputPhase) {
        case (.waitingToStart, .holding(let startLocation)):
            playerEntity.attach(to: currentVehicleEntity)
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)
            flowState = .riding

        case (.riding, .holding(let startLocation)):
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)

        case (.riding, .dragging):
            movementSystem.updateVehicleAndRider(
                vehicle: currentVehicleEntity,
                player: playerEntity,
                inputPhase: inputPhase
            )

        case (.riding, .released):
            movementSystem.endSteering(vehicle: currentVehicleEntity)
            launchSystem.launch(player: playerEntity, toward: nextVehicleEntity)
            flowState = .jumping

        case (.jumping, .holding(let startLocation)):
            if let nextVehicleEntity, latchSystem.attemptLatch(player: playerEntity, onto: nextVehicleEntity) {
                completeLatch(on: nextVehicleEntity, startLocation: startLocation)
            } else {
                enterGameOver()
            }

        case (.jumping, .dragging):
            break

        case (.gameOver, .holding):
            resetRun()

        default:
            break
        }
    }

    private func resetRun() {
        inputSystem.reset()
        lastUpdateTime = 0
        setUpScene()
    }

    private func enterGameOver() {
        guard flowState != .gameOver else { return }

        flowState = .gameOver
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
        showGameOverOverlay()
    }

    private func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }

        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle
        nextVehicleEntity = nil

        if let startLocation {
            movementSystem.beginSteering(vehicle: vehicle, at: startLocation)
        }
        flowState = .riding
    }

    private func makeDeltaTime(from currentTime: TimeInterval) -> TimeInterval {
        defer { lastUpdateTime = currentTime }

        guard lastUpdateTime > 0 else { return 0 }
        return min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
    }

    private func showGameOverOverlay() {
        guard gameOverOverlayNode == nil else { return }

        let overlayNode = SKNode()
        overlayNode.zPosition = ZPosition.gameOverOverlay

        let dimBackground = SKShapeNode(rectOf: configuration.referenceScreenSize)
        dimBackground.fillColor = SKColor.black.withAlphaComponent(0.45)
        dimBackground.strokeColor = .clear
        overlayNode.addChild(dimBackground)

        let panel = SKShapeNode(rectOf: CGSize(width: 250, height: 130), cornerRadius: 8)
        panel.fillColor = SKColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 0.92)
        panel.strokeColor = SKColor(red: 0.90, green: 0.66, blue: 0.34, alpha: 1.0)
        panel.lineWidth = 3
        overlayNode.addChild(panel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 30
        titleLabel.fontColor = SKColor(red: 0.95, green: 0.78, blue: 0.44, alpha: 1.0)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 22)
        panel.addChild(titleLabel)

        let retryLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        retryLabel.text = "Hold to retry"
        retryLabel.fontSize = 17
        retryLabel.fontColor = .white
        retryLabel.verticalAlignmentMode = .center
        retryLabel.position = CGPoint(x: 0, y: -28)
        panel.addChild(retryLabel)

        gameOverOverlayNode = overlayNode
        addChild(overlayNode)
    }

    private func makeFloorNode() -> SKNode {
        let floorNode = SKNode()
        floorNode.zPosition = ZPosition.floor

        let background = SKShapeNode(rectOf: configuration.referenceScreenSize)
        background.fillColor = SKColor(red: 0.84, green: 0.84, blue: 0.86, alpha: 1.0)
        background.strokeColor = .clear
        floorNode.addChild(background)

        floorNode.addChild(makeDiamondGridNode())

        let halfRoadWidth = configuration.roadWidth / 2
        let nearLeft = projectedPoint(horizontalOffset: -halfRoadWidth, depthOffset: 0)
        let nearRight = projectedPoint(horizontalOffset: halfRoadWidth, depthOffset: 0)
        let farRight = projectedPoint(horizontalOffset: halfRoadWidth, depthOffset: configuration.roadDepth)
        let farLeft = projectedPoint(horizontalOffset: -halfRoadWidth, depthOffset: configuration.roadDepth)

        let roadPath = CGMutablePath()
        roadPath.move(to: nearLeft)
        roadPath.addLine(to: nearRight)
        roadPath.addLine(to: farRight)
        roadPath.addLine(to: farLeft)
        roadPath.closeSubpath()

        let road = SKShapeNode(path: roadPath)
        road.fillColor = SKColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0)
        road.strokeColor = .clear
        floorNode.addChild(road)

        let gridPath = CGMutablePath()
        let depthStep = configuration.roadDepth / 5
        for index in 1...4 {
            let depthOffset = CGFloat(index) * depthStep
            gridPath.move(to: projectedPoint(horizontalOffset: -halfRoadWidth, depthOffset: depthOffset))
            gridPath.addLine(to: projectedPoint(horizontalOffset: halfRoadWidth, depthOffset: depthOffset))
        }

        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = SKColor.black.withAlphaComponent(0.08)
        grid.lineWidth = 2
        floorNode.addChild(grid)

        return floorNode
    }

    private func makePlayableBoundsGuide() -> SKNode {
        let bounds = configuration.vehicleXBounds
        let guidePath = CGMutablePath()
        guidePath.move(to: CGPoint(x: bounds.lowerBound, y: -configuration.referenceScreenSize.height / 2))
        guidePath.addLine(to: CGPoint(x: bounds.lowerBound + 340, y: configuration.referenceScreenSize.height / 2))
        guidePath.move(to: CGPoint(x: bounds.upperBound, y: -configuration.referenceScreenSize.height / 2))
        guidePath.addLine(to: CGPoint(x: bounds.upperBound + 340, y: configuration.referenceScreenSize.height / 2))

        let guide = SKShapeNode(path: guidePath)
        guide.strokeColor = SKColor.black.withAlphaComponent(0.08)
        guide.lineWidth = 1
        guide.zPosition = ZPosition.overlay
        return guide
    }

    private func addObstacleLayoutNodes() {
        for position in configuration.obstaclePositions {
            let obstacle = makeIsometricObstacleNode()
            obstacle.position = position
            addChild(obstacle)
        }
    }

    private func makeDiamondGridNode() -> SKNode {
        let gridPath = CGMutablePath()
        let spacing: CGFloat = 44
        let width = configuration.referenceScreenSize.width
        let height = configuration.referenceScreenSize.height
        let diagonalExtent = width + height

        var offset = -diagonalExtent
        while offset <= diagonalExtent {
            gridPath.move(to: CGPoint(x: offset, y: -height / 2))
            gridPath.addLine(to: CGPoint(x: offset + height, y: height / 2))

            gridPath.move(to: CGPoint(x: offset, y: height / 2))
            gridPath.addLine(to: CGPoint(x: offset + height, y: -height / 2))
            offset += spacing
        }

        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = SKColor.black.withAlphaComponent(0.10)
        grid.lineWidth = 1
        return grid
    }

    private func makeIsometricObstacleNode() -> SKNode {
        let obstacleNode = SKNode()
        let size = configuration.obstacleSize
        let topHeight = size.width * 0.45

        let shaft = SKShapeNode(rectOf: CGSize(width: size.width * 0.48, height: size.height * 0.68))
        shaft.fillColor = SKColor(red: 0.74, green: 0.74, blue: 0.76, alpha: 1.0)
        shaft.strokeColor = .clear
        shaft.position = CGPoint(x: 0, y: -size.height * 0.08)
        obstacleNode.addChild(shaft)

        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: 0, y: size.height * 0.48))
        topPath.addLine(to: CGPoint(x: size.width * 0.32, y: size.height * 0.48 - topHeight))
        topPath.addLine(to: CGPoint(x: 0, y: size.height * 0.48 - topHeight * 1.9))
        topPath.addLine(to: CGPoint(x: -size.width * 0.32, y: size.height * 0.48 - topHeight))
        topPath.closeSubpath()

        let top = SKShapeNode(path: topPath)
        top.fillColor = SKColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0)
        top.strokeColor = .clear
        obstacleNode.addChild(top)

        obstacleNode.zPosition = ZPosition.obstacle
        return obstacleNode
    }

    private func projectedPoint(horizontalOffset: CGFloat, depthOffset: CGFloat) -> CGPoint {
        isometricProjector.project(
            horizontalOffset: horizontalOffset,
            depthOffset: depthOffset,
            from: configuration.roadStartCenterPosition
        )
    }
}

#if os(iOS) || os(tvOS)
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.begin(at: touch.location(in: self)))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.move(to: touch.location(in: self)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.end(at: touch.location(in: self)))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.end(at: touch.location(in: self)))
    }
}
#endif
