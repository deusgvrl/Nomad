//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import Foundation
import SpriteKit

// MARK: - Game Scene

/// Main SpriteKit scene for the Nomad movement prototype.
///
/// This scene wires the ECS objects together:
/// - `InputSystem` cleans touch input.
/// - `MovementSystem` moves the car/player while riding.
/// - `LaunchSystem` moves the player while airborne.
/// - `LatchSystem` decides whether hold-again succeeds.
final class GameScene: SKScene {

    // MARK: - Dependencies

    private let configuration: GameConfiguration
    private let inputSystem = InputSystem()
    private let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem
    private let latchSystem: LatchSystem

    // MARK: - Runtime State

    private var gameState: GameState = .waitingToStart
    private var playerState: PlayerState = .idle
    private var playerEntity: PlayerEntity?
    private var currentVehicleEntity: VehicleEntity?
    private var gameOverOverlayNode: SKNode?
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Scene Factory

    /// Creates the scene with a centered anchor point.
    ///
    /// `anchorPoint = (0.5, 0.5)` means the middle of the screen is `(0, 0)`.
    /// That makes placement easier because negative y is lower screen and
    /// positive y is upper screen.
    class func newGameScene() -> GameScene {
        let configuration = GameConfiguration.standard
        let scene = GameScene(size: configuration.referenceScreenSize, configuration: configuration)
        scene.scaleMode = .aspectFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }

    // MARK: - Initialization

    init(size: CGSize, configuration: GameConfiguration = .standard) {
        self.configuration = configuration
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: configuration)
        self.latchSystem = LatchSystem(configuration: configuration)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .standard
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: .standard)
        self.latchSystem = LatchSystem(configuration: .standard)
        super.init(coder: aDecoder)
    }

    // MARK: - SpriteKit Lifecycle

    override func didMove(to view: SKView) {
        setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = makeDeltaTime(from: currentTime)
        guard let playerEntity else { return }

        // While jumping, SpriteKit's frame loop updates the player's arc.
        // Drag input is ignored until the player latches again.
        if playerState == .jumping {
            let launchResult = launchSystem.update(player: playerEntity, deltaTime: deltaTime)
            if launchResult == .fell {
                pausePlayerAfterFall()
            }
        }
    }

    // MARK: - Scene Setup

    private func setUpScene() {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)

        addChild(makeFloorNode())
        addChild(makePlayableBoundsGuide())
        addObstacleLayoutNodes()

        // V1 uses one active vehicle slot only. Later treadmill spawning can
        // replace this same slot with new vehicle assets.
        let vehicleEntity = VehicleEntity(configuration: configuration)
        vehicleEntity.setPosition(configuration.currentVehiclePosition)

        let playerEntity = PlayerEntity(configuration: configuration)
        playerEntity.place(on: vehicleEntity)

        addChild(vehicleEntity.node)
        addChild(playerEntity.node)

        self.currentVehicleEntity = vehicleEntity
        self.playerEntity = playerEntity
        self.gameOverOverlayNode = nil
        self.gameState = .waitingToStart
        self.playerState = .idle
    }

    // MARK: - Input State Machine

    /// Applies the player action rules:
    /// hold starts riding, drag steers while riding, release jumps, hold while
    /// jumping tries to latch.
    private func handle(_ inputPhase: InputPhase) {
        guard let playerEntity, let currentVehicleEntity else { return }
        playerEntity.recordInput(inputPhase)

        switch inputPhase {
        case .holding(let startLocation) where gameState == .waitingToStart:
            // First hold begins the run and attaches the player to the car.
            playerEntity.attach(to: currentVehicleEntity)
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)
            gameState = .playing
            playerState = .riding

        case .holding(let startLocation) where gameState == .playing && playerState == .riding:
            // A new hold while already riding resets the drag starting point.
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)

        case .dragging where gameState == .playing && playerState == .riding:
            // Dragging only works while riding. The movement system keeps the
            // vehicle and player inside the road-width band.
            movementSystem.updateVehicleAndRider(
                vehicle: currentVehicleEntity,
                player: playerEntity,
                inputPhase: inputPhase
            )

        case .released where gameState == .playing && playerState == .riding:
            // Releasing detaches the player and starts the forward jump arc.
            movementSystem.endSteering(vehicle: currentVehicleEntity)
            launchSystem.launch(player: playerEntity)
            playerState = .jumping

        case .holding(let startLocation) where gameState == .playing && playerState == .jumping:
            // Holding again while airborne attempts to latch. For this movement
            // branch, a miss only parks the player in falling state. The actual
            // game-over result is kept below for a future focused branch.
            playerState = .latching
            if latchSystem.attemptLatch(player: playerEntity, onto: currentVehicleEntity) {
                completeLatch(on: currentVehicleEntity, startLocation: startLocation)
            } else {
                pausePlayerAfterFall()
            }

        case .dragging where gameState == .playing && playerState == .jumping:
            // Airborne drag is intentionally ignored by the current design.
            break

        default:
            break
        }
    }

    // MARK: - Run Reset

    private func resetRun() {
        inputSystem.reset()
        lastUpdateTime = 0
        setUpScene()
    }

    // MARK: - Temporary Fall Handling

    /// Movement-focused placeholder for missed jumps and falls.
    ///
    /// This branch should stay focused on player/vehicle movement, so falling no
    /// longer triggers the game-over overlay. The old game-over functions are
    /// kept below, disconnected, for the later game-over branch.
    private func pausePlayerAfterFall() {
        playerState = .falling
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
    }

    // MARK: - Parked Game Over Logic

    /// Parked for a future game-over branch.
    ///
    /// Kept intentionally so the popup work is not lost, but this movement branch
    /// should not call it.
    private func enterGameOver(playerEndState: PlayerState = .crashed) {
        guard gameState != .gameOver else { return }

        gameState = .gameOver
        playerState = playerEndState
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
        showGameOverOverlay()
    }

    // MARK: - Latch Completion

    private func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }

        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle

        if let startLocation {
            movementSystem.beginSteering(vehicle: vehicle, at: startLocation)
        }
        gameState = .playing
        playerState = .riding
    }

    // MARK: - Delta Time

    /// Caps delta time so a simulator pause does not create a giant jump update.
    private func makeDeltaTime(from currentTime: TimeInterval) -> TimeInterval {
        defer { lastUpdateTime = currentTime }

        guard lastUpdateTime > 0 else { return 0 }
        return min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
    }

    // MARK: - Parked Game Over UI

    /// Parked popup UI for the later game-over branch.
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

    // MARK: - Road And Background

    private func makeFloorNode() -> SKNode {
        let floorNode = SKNode()
        floorNode.zPosition = ZPosition.floor

        let background = SKShapeNode(rectOf: configuration.referenceScreenSize)
        background.fillColor = SKColor(red: 0.84, green: 0.84, blue: 0.86, alpha: 1.0)
        background.strokeColor = .clear
        floorNode.addChild(background)

        floorNode.addChild(makeDiamondGridNode())

        let road = SKShapeNode(path: makeRoadPath())
        road.fillColor = SKColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0)
        road.strokeColor = .clear
        floorNode.addChild(road)

        let gridPath = CGMutablePath()
        let halfRoadWidth = configuration.roadWidth / 2
        for index in 1...4 {
            // Cross lines are drawn with the same road coordinate helper as
            // movement, keeping the visuals and controls aligned.
            let forwardOffset = roadLength * CGFloat(index) / 5
            gridPath.move(to: roadPoint(forwardOffset: forwardOffset, roadWidthOffset: -halfRoadWidth))
            gridPath.addLine(to: roadPoint(forwardOffset: forwardOffset, roadWidthOffset: halfRoadWidth))
        }

        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = SKColor.black.withAlphaComponent(0.08)
        grid.lineWidth = 2
        floorNode.addChild(grid)

        return floorNode
    }

    // MARK: - Road Shape

    private func makeRoadPath() -> CGPath {
        let halfRoadWidth = configuration.roadWidth / 2

        let roadPath = CGMutablePath()
        roadPath.move(to: roadPoint(forwardOffset: 0, roadWidthOffset: -halfRoadWidth))
        roadPath.addLine(to: roadPoint(forwardOffset: 0, roadWidthOffset: halfRoadWidth))
        roadPath.addLine(to: roadPoint(forwardOffset: roadLength, roadWidthOffset: halfRoadWidth))
        roadPath.addLine(to: roadPoint(forwardOffset: roadLength, roadWidthOffset: -halfRoadWidth))
        roadPath.closeSubpath()
        return roadPath
    }

    // MARK: - Playable Bounds Guide

    private func makePlayableBoundsGuide() -> SKNode {
        let halfRoadWidth = configuration.roadWidth / 2
        let vehicleInset = configuration.vehicleSize.width / 2
        let leftVehicleLimit = -halfRoadWidth + vehicleInset
        let rightVehicleLimit = halfRoadWidth - vehicleInset
        let guidePath = CGMutablePath()
        guidePath.move(to: roadPoint(forwardOffset: 0, roadWidthOffset: leftVehicleLimit))
        guidePath.addLine(to: roadPoint(forwardOffset: roadLength, roadWidthOffset: leftVehicleLimit))
        guidePath.move(to: roadPoint(forwardOffset: 0, roadWidthOffset: rightVehicleLimit))
        guidePath.addLine(to: roadPoint(forwardOffset: roadLength, roadWidthOffset: rightVehicleLimit))

        let guide = SKShapeNode(path: guidePath)
        guide.strokeColor = SKColor.black.withAlphaComponent(0.08)
        guide.lineWidth = 1
        guide.zPosition = ZPosition.overlay
        return guide
    }

    // MARK: - Road Coordinate Helpers

    private var roadForwardUnit: CGVector {
        let radians = Double(configuration.isometricViewAngleInDegrees) * Double.pi / 180
        return CGVector(dx: CGFloat(cos(radians)), dy: CGFloat(sin(radians)))
    }

    private var roadRightUnit: CGVector {
        let radians = Double(configuration.isometricViewAngleInDegrees) * Double.pi / 180
        return CGVector(dx: CGFloat(cos(radians - Double.pi / 2)), dy: CGFloat(sin(radians - Double.pi / 2)))
    }

    private var roadLength: CGFloat {
        // Long enough to cover the full portrait screen from bottom to top.
        configuration.referenceScreenSize.height / roadForwardUnit.dy
    }

    /// Converts road coordinates into SpriteKit scene coordinates.
    ///
    /// `forwardOffset` moves along the road. `roadWidthOffset` moves left/right
    /// across the road between the borders.
    private func roadPoint(forwardOffset: CGFloat, roadWidthOffset: CGFloat) -> CGPoint {
        CGPoint(
            x: configuration.roadStartCenterPosition.x + roadForwardUnit.dx * forwardOffset + roadRightUnit.dx * roadWidthOffset,
            y: configuration.roadStartCenterPosition.y + roadForwardUnit.dy * forwardOffset + roadRightUnit.dy * roadWidthOffset
        )
    }

    // MARK: - Obstacle Placeholder Layout

    private func addObstacleLayoutNodes() {
        for position in configuration.obstaclePositions {
            let obstacle = makeIsometricObstacleNode()
            obstacle.position = position
            addChild(obstacle)
        }
    }

    // MARK: - Background Grid

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

    // MARK: - Obstacle Placeholder Art

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
}

#if os(iOS) || os(tvOS)
// MARK: - Touch Input

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
