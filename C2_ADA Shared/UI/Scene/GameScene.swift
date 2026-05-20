//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

// MARK: - Game Scene

/// Main SpriteKit scene for Nomad's movement prototype.
///
/// This file is the merged scene:
/// - keeps the newer `worldNode` and `SpawnSystem` structure from `UI/Scene`;
/// - brings in the old prototype's hold, drag, release, jump, and latch logic;
/// - routes Game Over transitions to `GameScene+GameOver.swift` and the
///   `GameOverScreen` overlay.
final class GameScene: SKScene {

    // MARK: - Dependencies

    let configuration: GameConfiguration
    private let inputSystem = InputSystem()
    let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem?
    private let latchSystem: LatchSystem?
    let distanceScoreSystem = DistanceScoreSystem()
    private let collisionSystem = CollisionSystem()

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

    var gameState: GameState = .waitingToStart
    var playerState: PlayerState = .idle
    var playerEntity: PlayerEntity?
    var currentVehicleEntity: VehicleEntity?
    var gameOverScreen: GameOverScreen?
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
        // MARK: Frame Delta
        // SpriteKit gives absolute time here, so convert it to a capped delta
        // before physics uses it. Passing absolute time made jumps fly too far.
        let deltaTime = makeDeltaTime(from: currentTime)
        guard gameState == .playing else { return }

        spawnSystem?.update(currentTime)
        updateDistanceScore(deltaTime)
        updateJumpingPlayer(deltaTime)

        if playerState == .riding, let vehicle = currentVehicleEntity, let player = playerEntity {
            player.place(on: vehicle)

            // MARK: Riding Collision Game Over
            // CollisionSystem checks the active vehicle's hitboxes while the
            // player is riding. A collision now flows through the real game-over
            // entry instead of only flipping state.
            if updateCollisionGameOverIfNeeded(for: vehicle) { return }
        }

    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard gameState != .gameOver else { return }

        handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard gameState != .gameOver else { return }

        handle(inputSystem.move(to: touch.location(in: gameplayNode)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if gameState == .gameOver {
            handleGameOverTouch(at: touch.location(in: self))
            return
        }

        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard gameState != .gameOver else { return }

        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
    }
}

// MARK: - Scene Setup

extension GameScene {

    func setUpScene() {
        GameFontRegistry.registerGameFontsIfNeeded(configuration: configuration)

        removeAllChildren()
        worldNode.removeAllChildren()
        gameplayNode.removeAllChildren()

        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)

        setUpNodes()
        setUpSpawnSystem()
        setUpMovementPrototype()
        setUpMovementBoundsGuide()

        gameOverScreen = nil
        gameState = .waitingToStart
        playerState = .idle
        lastUpdateTime = 0
        distanceScoreSystem.resetRun()
    }
}

private extension GameScene {

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
        worldNode.zPosition = RenderLayer.floor
        addChild(worldNode)

        gameplayNode.name = "gameplay"
        gameplayNode.position = .zero
        gameplayNode.zPosition = RenderLayer.vehicle
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
        guideNode.zPosition = RenderLayer.overlay
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
        capNode.zPosition = RenderLayer.overlay
        gameplayNode.addChild(capNode)
    }
}

// MARK: - Frame Update

private extension GameScene {

    // MARK: - Collision Game Over

    func updateCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        // MARK: Obstacle Collision Priority
        // Obstacles are the primary crash rule; check them first so the debug
        // message and player state describe the obstacle hit.
        if updateObstacleCollisionGameOverIfNeeded(for: vehicle) {
            return true
        }

        // MARK: Vehicle Collision Priority
        // The existing collision system also supports vehicle-to-vehicle hits,
        // so route those through the same game-over overlay path.
        return updateVehicleCollisionGameOverIfNeeded(for: vehicle)
    }

    func updateObstacleCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        guard let obstacles = spawnSystem?.obstacleEntities,
              let hitObstacle = collisionSystem.checkCollision(
                vehicle: vehicle,
                with: obstacles
              ) else {
            return false
        }

        // MARK: Obstacle Crash Result
        // Use the formal game-over flow so obstacle crashes show score,
        // highscore, retry, and home UI just like fall game over.
        print("Collision with \(hitObstacle.type.rawValue)")
        enterGameOver(playerEndState: .crashed)
        return true
    }

    func updateVehicleCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        guard let otherVehicles = spawnSystem?.vehicleEntities,
              collisionSystem.checkVehicleCollision(
                playerVehicle: vehicle,
                with: otherVehicles
              ) != nil else {
            return false
        }

        // MARK: Vehicle Crash Result
        // Keep car-to-car collision consistent with obstacle crashes when the
        // collision system reports another vehicle hit.
        print("Collision with another vehicle!")
        enterGameOver(playerEndState: .crashed)
        return true
    }

    // MARK: - Distance Score Preview

    func updateDistanceScore(_ deltaTime: TimeInterval) {
        guard configuration.debugDistancePreviewEnabled,
              gameState == .playing else {
            return
        }

        // Temporary preview only: the real distance counter can replace this
        // one call without changing the highscore or game-over overlay logic.
        distanceScoreSystem.updatePreview(
            deltaTime: deltaTime,
            metersPerSecond: configuration.debugDistancePreviewMetersPerSecond
        )
    }

    // MARK: - Jumping Player

    func updateJumpingPlayer(_ deltaTime: TimeInterval) {
        guard let playerEntity else { return }

        // While jumping, SpriteKit's frame loop updates the player's arc.
        // Drag input is ignored until the player latches again.
        if playerState == .jumping {
            let launchResult = launchSystem?.update(player: playerEntity, deltaTime: deltaTime)
            if launchResult == .fell {
                enterGameOver(playerEndState: .falling)
            }
        }
    }

    // MARK: - Delta Time

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
            // MARK: Dev Jump Release
            // Use the same untargeted launch arc as `dev`; game-over landing
            // logic should not influence the jump while latching is still possible.
            launchSystem?.launch(player: playerEntity)
            playerState = .jumping

        case .holding(let startLocation) where gameState == .playing && playerState == .jumping:
            // Holding again while airborne attempts to latch. A miss leaves the
            // player in the jump arc until the fall line triggers game over.
            playerState = .latching
            let allVehicles = spawnSystem?.vehicleEntities ?? []
            let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
            
            if let latchedVehicle = latchSystem?.attemptLatch(player: playerEntity, onto: activeVehicles) {
                completeLatch(on: latchedVehicle, startLocation: startLocation)
            } else {
                playerState = .jumping
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

    // MARK: - Latch Completion

    func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }
        
        // MARK: Old Vehicle Cleanup
        // Remove the previously ridden car when the player latches to a new car.
        // Re-adding it to the scrolling world creates the extra car beside the
        // player after every successful jump.
        if let oldVehicle = currentVehicleEntity, oldVehicle !== vehicle {
            movementSystem.endSteering(vehicle: oldVehicle)
            oldVehicle.removeComponent(ofType: MovementComponent.self)
            spawnSystem?.removeVehicle(entity: oldVehicle)
            oldVehicle.node.removeFromParent()
        }

        // MARK: Merged Spawn-System Safety
        // This branch's SpawnSystem auto-moves spawned vehicles. Once a vehicle
        // becomes the active player car, remove it from that automatic flow.
        spawnSystem?.removeVehicle(entity: vehicle)
        
        // MARK: Dev New Vehicle Parenting
        // Match `dev`: move the latched vehicle into gameplayNode only when it
        // came from another parent, then place it at the active vehicle slot.
        let newParent = gameplayNode
        if let oldParent = vehicle.node.parent, oldParent !== newParent {
            vehicle.node.removeFromParent()
            vehicle.node.position = configuration.currentVehiclePosition
            newParent.addChild(vehicle.node)
        }
        
        vehicle.node.zPosition = RenderLayer.vehicle
        
        // MARK: Dev Steering Rebuild
        // Rebuild steering on the new vehicle so dragging continues from the
        // same starting slot after a successful latch.
        let steering = MovementComponent(
            position: configuration.currentVehiclePosition,
            screenSize: configuration.referenceScreenSize,
            vehicleSize: configuration.vehicleMovementBoundsSize,
            movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
            movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
            dragSensitivity: configuration.dragSensitivity
        )
        vehicle.addComponent(steering)
        
        // MARK: Dev Latch Completion
        // Attach the player to the new vehicle and optionally continue steering
        // from the touch that triggered the latch.
        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle
        
        if let startLocation {
            movementSystem.beginSteering(vehicle: vehicle, at: startLocation)
        }
        gameState = .playing
        playerState = .riding
    }
}
//        let oldParent = currentVehicleEntity.node.parent
//        let newParent = vehicle.node.parent
//        let scene = currentVehicleEntity.node.scene
//        
//        if let scene, let oldParent, let newParent {
//            let scenePosOld = oldParent.convert(currentVehicleEntity.node.position, to: scene)
//            
//            currentVehicleEntity.node.removeFromParent()
//            vehicle.node.removeFromParent()
//            
//            currentVehicleEntity.node.position = newParent.convert(scenePosOld, from: scene)
//            newParent.addChild(currentVehicleEntity.node)
//            
//            vehicle.node.position = configuration.currentVehiclePosition
//            oldParent.addChild(vehicle.node)
//            
//            currentVehicleEntity.node.zPosition = 100
//            vehicle.node.zPosition = RenderLayer.vehicle
//            
//            currentVehicleEntity.removeComponent(ofType: MovementComponent.self)
//            
//            let steering = MovementComponent (
//                position: vehicle.node.position,
//                screenSize: configuration.referenceScreenSize,
//                vehicleSize: configuration.vehicleSize,
//                movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
//                movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
//                dragSensitivity: configuration.dragSensitivity
//            )
//            vehicle.addComponent(steering)
//            
//        }
//    }


// MARK: - Score Result

/// Finished-run score data shown by the Game Over overlay.
struct ScoreResult {
    // MARK: - Score Values

    let distanceMeters: Int
    let highScoreMeters: Int
    let isNewHighScore: Bool
}

// MARK: - Distance Score System

/// Stores score and highscore separately from the temporary preview updater.
/// The real distance counter can set meters directly without changing overlay UI.
final class DistanceScoreSystem {

    // MARK: - Storage Keys

    private enum StorageKey {
        static let highScoreMeters = "Nomad.DistanceScoreSystem.highScoreMeters"
    }

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Runtime State

    private(set) var currentDistanceMeters: Int = 0
    private var previewDistanceMeters: CGFloat = 0

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Run Lifecycle

    func resetRun() {
        currentDistanceMeters = 0
        previewDistanceMeters = 0
    }

    // MARK: - Distance Preview

    func updatePreview(deltaTime: TimeInterval, metersPerSecond: CGFloat) {
        guard deltaTime > 0 else { return }

        previewDistanceMeters += CGFloat(deltaTime) * metersPerSecond
        currentDistanceMeters = max(0, Int(previewDistanceMeters.rounded(.down)))
    }

    // MARK: - Distance Input

    func setDistanceMeters(_ meters: Int) {
        currentDistanceMeters = max(0, meters)
        previewDistanceMeters = CGFloat(currentDistanceMeters)
    }

    // MARK: - Result

    func finishRun() -> ScoreResult {
        let previousHighScore = userDefaults.integer(forKey: StorageKey.highScoreMeters)
        let isNewHighScore = currentDistanceMeters > previousHighScore
        let finalHighScore = isNewHighScore ? currentDistanceMeters : previousHighScore

        if isNewHighScore {
            userDefaults.set(finalHighScore, forKey: StorageKey.highScoreMeters)
        }

        return ScoreResult(
            distanceMeters: currentDistanceMeters,
            highScoreMeters: finalHighScore,
            isNewHighScore: isNewHighScore
        )
    }
}
