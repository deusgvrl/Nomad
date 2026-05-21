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
    private let targetReticleNode = SKShapeNode()
    private let gameplayNode = SKNode()
    private var spawnSystem: SpawnSystem?

    // MARK: - Runtime State

    var gameState: GameState = .waitingToStart
    var playerState: PlayerState = .idle
    var playerEntity: PlayerEntity?
    var currentVehicleEntity: VehicleEntity?
    var gameOverScreen: GameOverScreen?
    private var lastUpdateTime: TimeInterval = 0
    private var currentTimeScale: CGFloat = 1.0
    private var targetTimeScale: CGFloat = 1.0

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

        spawnSystem?.update(deltaTime: deltaTime)
        updateJumpingPlayer(deltaTime)
        
        if let vehicle = currentVehicleEntity, let player = playerEntity {
            if playerState == .riding {
                movementSystem.updateLerp(vehicle: vehicle, deltaTime: deltaTime)
                player.place(on: vehicle)
            }

            // --- DEBUG: Show vehicle hitbox (OFF) ---
            // vehicle.component(ofType: HitboxComponent.self)?.showDebugHitbox(in: vehicle.node, color: .green)

            // 1. Cek tabrakan dengan rintangan (Batu, Pohon, dll)
            if let obstacles = spawnSystem?.obstacleEntities {

                // --- DEBUG: Show all obstacle hitboxes (OFF) ---
                /*
                for obs in obstacles {
                    obs.component(ofType: HitboxComponent.self)?.showDebugHitbox(in: obs.node, color: .red)
                }
                */

                if let hitObstacle = collisionSystem.checkCollision(vehicle: vehicle, with: obstacles) {
                    print("Collision with \(hitObstacle.type.rawValue)")
                    
                    // TODO: Replace this pause logic with a formal Game Over sequence/Scene transition
                    gameState = .gameOver
                    playerState = .crashed
                }
            }

        }
        
//        if playerState == .riding, let vehicle = currentVehicleEntity, let player = playerEntity {
//            player.place(on: vehicle)
//        }
        
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
        
//        let ringDiameter = configuration.latchDistance * 2
//        let path = CGPath(ellipseIn: CGRect(x: -ringDiameter/2, y: -ringDiameter/2, width: ringDiameter, height: ringDiameter), transform: nil)
//        targetReticleNode.path = path
        let ringRadius = configuration.latchDistance
        targetReticleNode.path = CGPath(ellipseIn: CGRect(x: -ringRadius, y: -ringRadius, width: ringRadius*2, height: ringRadius*2), transform: nil)
        targetReticleNode.zPosition = -1
        targetReticleNode.strokeColor = SKColor(red: 1.00, green: 0.86, blue: 0.24, alpha: 1.0)
        targetReticleNode.lineWidth = 4
        targetReticleNode.alpha = 0
        
        targetReticleNode.xScale = 1.0
        targetReticleNode.yScale = 1.0
        worldNode.addChild(targetReticleNode)
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

        // While jumping, SpriteKit's frame loop updates the player's lane path.
        // Drag input is ignored until the player latches again.
        if playerState == .jumping {
            let launchResult = launchSystem?.update(player: playerEntity, deltaTime: deltaTime)
            
            let allVehicles = spawnSystem?.vehicleEntities ?? []
            let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
            
            let bestTarget = latchSystem?.getBestTarget(player: playerEntity, vehicles: activeVehicles)
            
            if let target = bestTarget {
                targetTimeScale = 0.6
                targetReticleNode.position = CGPoint(x: target.node.position.x, y: target.node.position.y + 40)
                
                if targetReticleNode.alpha == 0 {
                    targetReticleNode.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15))
                }
            } else {
                targetTimeScale = 1.0
                if targetReticleNode.alpha > 0 {
                    targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.15))
                }
            }
            
            if launchResult == .fell {
                enterFallGameOver()
            }
        }
    }

    // MARK: - Delta Time

    /// Caps delta time so a simulator pause does not create a giant jump update.
    func makeDeltaTime(from currentTime: TimeInterval) -> TimeInterval {
        defer { lastUpdateTime = currentTime }

        guard lastUpdateTime > 0 else { return 0 }
        let rawDelta = min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
        
        let scaleDiff = targetTimeScale - currentTimeScale
        if abs(scaleDiff) < 0.01 {
            currentTimeScale = targetTimeScale
        } else {
            currentTimeScale += scaleDiff * CGFloat(rawDelta * 4.0)
        }
        
        let dilatedDelta = rawDelta * TimeInterval(currentTimeScale)
        self.speed = currentTimeScale
        return dilatedDelta
    }

}

// MARK: - Game Over Presentation Support

extension GameScene {

    /// Restores normal scene timing before the Game Over overlay is presented.
    func resetGameOverTiming() {
        targetTimeScale = 1.0
        currentTimeScale = 1.0
        speed = 1.0
    }

    /// Clears jump-only visuals while preserving the exact lane-linear fall endpoint.
    func cleanUpFallImpactPresentation() {
        // MARK: Fall Reticle Cleanup
        // A missed latch should hide the target indicator before the overlay
        // appears so the Game Over screen is not visually cluttered.
        targetReticleNode.removeAllActions()
        targetReticleNode.alpha = 0.0

        // MARK: Fall Player Cleanup
        // Keep the player exactly where `LaunchSystem` ended the lane movement;
        // only reset visual scale/actions before showing Game Over.
        if let playerEntity {
            playerEntity.node.removeAllActions()
            playerEntity.node.setScale(1.0)
        }
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
            
            // Siapkan callback untuk lompat paksa
            currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.onJumpRequested = { [weak self] in
                self?.forcePlayerToJump()
            }
            
            // Mulai siklus kemarahan
            currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.startRageCycle()
            
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
            // Pindah jadi function, biar bisa di reuse untuk rage counter
            forcePlayerToJump()

        case .holding(let startLocation) where gameState == .playing && playerState == .jumping:
            // Holding again while airborne attempts to latch. A miss switches
            // into a short straight fall along the same car-facing lane.
            playerState = .latching
            let allVehicles = spawnSystem?.vehicleEntities ?? []
            let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
            
            if let latchedVehicle = latchSystem?.attemptLatch(player: playerEntity, onto: activeVehicles) {
                completeLatch(on: latchedVehicle, startLocation: startLocation)
            } else {
                let failedLatchFallDistance = configuration.vehicleSize.height * 0.55
                playerEntity.component(ofType: LaunchComponent.self)?.beginFailedLatchFall(
                    from: playerEntity.node.position,
                    direction: configuration.jumpForwardUnitVector,
                    distance: failedLatchFallDistance,
                    duration: configuration.playerFallSettleDuration
                )
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
    
    /// Executes the jumping sequence, detaching the player and launching them forward.
    func forcePlayerToJump() {
        guard let currentVehicleEntity, let playerEntity, playerState == .riding else { return }
        
        movementSystem.endSteering(vehicle: currentVehicleEntity)
        
        // Menambahkan delay sebelum kendaraan kembali ke kondisi Idle agar efek marahnya masih terlihat sejenak
        let wait = SKAction.wait(forDuration: 0.3)
        let reset = SKAction.run { [weak currentVehicleEntity] in
            //Reset state kendaraan kembali ke idle
            currentVehicleEntity?.component(ofType: VehicleRageComponent.self)?.resetRageCycle()
        }
        currentVehicleEntity.node.run(SKAction.sequence([wait, reset]))
        
        spawnSystem?.adopt(oldVehicle: currentVehicleEntity)
            
        currentVehicleEntity.removeComponent(ofType: MovementComponent.self)
        
        // Creating a new MovementComponent with speed: 0 for a receding movement.
        let recedingMovement = MovementComponent(speed: 0)
        currentVehicleEntity.addComponent(recedingMovement)
        
        launchSystem?.launch(player: playerEntity)
        playerEntity.playJumpVisual(duration: configuration.jumpForwardDuration)
        playerState = .jumping
    }
    
    /// Movement-focused placeholder for missed jumps and falls.
    ///
    /// This branch should stay focused on player/vehicle movement, so falling no
    /// longer triggers the game-over overlay. The old game-over functions are
    /// kept below, disconnected, for the later game-over branch.
    func pausePlayerAfterFall() {
        targetTimeScale = 1.0
        playerEntity?.cancelJumpVisual()
        targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.1))
        playerState = .falling
        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }
    }
    
    func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }
        playerEntity.cancelJumpVisual()
        targetTimeScale = 1.0
        targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.1))
        // 1. Remove the old vehicle from the scene
//        if let oldVehicle = currentVehicleEntity {
//            oldVehicle.node.removeFromParent()
//            spawnSystem?.removeVehicle(entity: oldVehicle)
//        }
        
        // 2. Remove new vehicle from SpawnSystem's automatic flow
        spawnSystem?.removeVehicle(entity: vehicle)
        
        // MARK: Dev New Vehicle Parenting
        // Match `dev`: move the latched vehicle into gameplayNode only when it
        // came from another parent, then place it at the active vehicle slot.
        let newParent = gameplayNode
        if let oldParent = vehicle.node.parent, oldParent !== newParent {
            let interceptedPos = oldParent.convert(vehicle.node.position, to: newParent)
            vehicle.node.removeFromParent()
            vehicle.node.position = interceptedPos
//            vehicle.node.position = configuration.currentVehiclePosition
            newParent.addChild(vehicle.node)
            
        }

        vehicle.node.zPosition = RenderLayer.vehicle
        
        // 4. Initialize steering starting from the spawn position
        let steering = MovementComponent(
            anchorPosition: configuration.currentVehiclePosition,
            currentPosition: vehicle.node.position,
            screenSize: configuration.referenceScreenSize,
            vehicleSize: configuration.vehicleSize,
            movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
            movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
            dragSensitivity: configuration.dragSensitivity
        )
        steering.startLerping(to: configuration.currentVehiclePosition)
        vehicle.addComponent(steering)
        
        // MARK: Dev Latch Completion
        // Attach the player to the new vehicle and optionally continue steering
        // from the touch that triggered the latch.
        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle
        
        // Siapkan callback untuk lompat paksa pada mobil baru
        vehicle.component(ofType: VehicleRageComponent.self)?.onJumpRequested = { [weak self] in
            self?.forcePlayerToJump()
        }
        // Mulai siklus kemarahan
        vehicle.component(ofType: VehicleRageComponent.self)?.startRageCycle()
        
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
