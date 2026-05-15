//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import Foundation
import SpriteKit

// MARK: - Game Scene

/// Main SpriteKit scene for Nomad's movement prototype.
///
/// This file is the merged scene:
/// - keeps the newer `worldNode` and `SpawnSystem` structure from `UI/Scene`;
/// - brings in the old prototype's hold, drag, release, jump, and latch logic;
/// - keeps game-over code parked so this branch stays focused on movement.
final class GameScene: SKScene {

    // MARK: - Dependencies

    private let configuration: GameConfiguration
    private let inputSystem = InputSystem()
    private let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem
    private let latchSystem: LatchSystem

    // MARK: - World Container

    /// Parent node for gameplay objects that exist in the road/world space.
    ///
    /// Spawned floor and obstacle rows live in `worldNode`, while the active
    /// player and vehicle live in `gameplayNode`. Keeping them separate lets us
    /// merge dev's treadmill setup without shifting the movement prototype's
    /// start position.
    private let worldNode = SKNode()
    private let gameplayNode = SKNode()
    private var spawnSystem: SpawnSystem?

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
    /// That matches the coordinate assumptions used by `GameConfiguration`.
    class func newGameScene() -> GameScene {
        let configuration = GameConfiguration.standard
        let scene = GameScene(size: configuration.referenceScreenSize, configuration: configuration)
        scene.scaleMode = SKSceneScaleMode.aspectFill
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
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .standard
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: .standard)
        self.latchSystem = LatchSystem(configuration: .standard)
        super.init(coder: aDecoder)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    // MARK: - SpriteKit Lifecycle

    override func didMove(to view: SKView) {
        setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        spawnSystem?.update(currentTime)
        updateJumpingPlayer(currentTime)
    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.move(to: touch.location(in: gameplayNode)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
    }
}

// MARK: - Scene Setup

private extension GameScene {

    func setUpScene() {
        removeAllChildren()
        worldNode.removeAllChildren()
        gameplayNode.removeAllChildren()

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)

        setUpNodes()
        setUpSpawnSystem()
        setUpMovementPrototype()
        setUpMovementBoundsGuide()

        gameOverOverlayNode = nil
        gameState = .waitingToStart
        playerState = .idle
        lastUpdateTime = 0
    }

    func setUpNodes() {
        // This keeps the setup shape from `dev`:
        // - `worldNode` owns floor/obstacle rows from `SpawnSystem`.
        // - `gameplayNode` owns the active player and vehicle.
        //
        // The original dev scene used the default bottom-left scene anchor.
        // This scene uses anchorPoint (0.5, 0.5), so the equivalent world
        // placement is shifted down from the centered coordinate system.
        worldNode.name = "world"
        worldNode.position = CGPoint(
            x: 0,
            y: -size.height * 0.8
        )
        worldNode.zPosition = ZPosition.floor
        addChild(worldNode)

        gameplayNode.name = "gameplay"
        gameplayNode.position = .zero
        gameplayNode.zPosition = ZPosition.vehicle
        addChild(gameplayNode)
    }

    func setUpSpawnSystem() {
        spawnSystem = SpawnSystem(
            worldNode: worldNode,
            sceneSize: size
        )
    }

    func setUpMovementPrototype() {
        // V1 uses one active vehicle slot only. Later treadmill spawning can
        // replace this same slot with new vehicle assets.
        let vehicleEntity = VehicleEntity(configuration: configuration)
        vehicleEntity.setPosition(configuration.currentVehiclePosition)

        let playerEntity = PlayerEntity(configuration: configuration)
        playerEntity.place(on: vehicleEntity)

        gameplayNode.addChild(vehicleEntity.node)
        gameplayNode.addChild(playerEntity.node)

        currentVehicleEntity = vehicleEntity
        self.playerEntity = playerEntity
    }

    func setUpMovementBoundsGuide() {
        guard configuration.showsMovementBoundsGuide else { return }

        // Temporary prototype guide:
        // - white line = the shallow movement lane from the hi-fi grid image;
        // - yellow caps = the current estimated canyon/wall limits.
        //
        // When the real canyon assets arrive, the numbers can be updated in
        // `GameConfiguration` without changing the movement system.
        let path = CGMutablePath()
        path.move(to: configuration.movementAxisStartPosition)
        path.addLine(to: configuration.movementAxisEndPosition)

        let guideNode = SKShapeNode(path: path)
        guideNode.name = "movementBoundsGuide"
        guideNode.strokeColor = SKColor.white.withAlphaComponent(0.85)
        guideNode.lineWidth = 4
        guideNode.lineCap = .round
        guideNode.zPosition = ZPosition.overlay
        gameplayNode.addChild(guideNode)

        addMovementBoundCap(at: configuration.movementAxisStartPosition)
        addMovementBoundCap(at: configuration.movementAxisEndPosition)
    }

    func addMovementBoundCap(at position: CGPoint) {
        let capNode = SKShapeNode(circleOfRadius: 5)
        capNode.name = "movementBoundCap"
        capNode.position = position
        capNode.fillColor = SKColor(red: 1.00, green: 0.86, blue: 0.24, alpha: 1.0)
        capNode.strokeColor = SKColor.white.withAlphaComponent(0.9)
        capNode.lineWidth = 2
        capNode.zPosition = ZPosition.overlay
        gameplayNode.addChild(capNode)
    }
}

// MARK: - Frame Update

private extension GameScene {

    func updateJumpingPlayer(_ currentTime: TimeInterval) {
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

    /// Caps delta time so a simulator pause does not create a giant jump update.
    func makeDeltaTime(from currentTime: TimeInterval) -> TimeInterval {
        defer { lastUpdateTime = currentTime }

        guard lastUpdateTime > 0 else { return 0 }
        return min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
    }
}

// MARK: - Input State Machine

private extension GameScene {

    /// Applies the player action rules:
    /// hold starts riding, drag steers while riding, release jumps, hold while
    /// jumping tries to latch.
    func handle(_ inputPhase: InputPhase) {
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
}

// MARK: - Movement State Helpers

private extension GameScene {

    /// Movement-focused placeholder for missed jumps and falls.
    ///
    /// This branch should stay focused on player/vehicle movement, so falling no
    /// longer triggers the game-over overlay. The old game-over functions are
    /// kept below, disconnected, for the later game-over branch.
    func pausePlayerAfterFall() {
        playerState = .falling
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
    }

    func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }

        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle

        if let startLocation {
            movementSystem.beginSteering(vehicle: vehicle, at: startLocation)
        }
        gameState = .playing
        playerState = .riding
    }
}

// MARK: - Parked Game Over Logic

private extension GameScene {

    /// Parked for a future game-over branch.
    ///
    /// Kept intentionally so the popup work is not lost, but this movement branch
    /// should not call it.
    func enterGameOver(playerEndState: PlayerState = .crashed) {
        guard gameState != .gameOver else { return }

        gameState = .gameOver
        playerState = playerEndState
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
        showGameOverOverlay()
    }

    /// Parked popup UI for the later game-over branch.
    func showGameOverOverlay() {
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
}
