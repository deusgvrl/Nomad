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
    
    // MARK: - Settings Source

    enum SettingsSource {
           case menu
           case pause
       }

    // MARK: - Dependencies

    let configuration: GameConfiguration
    private let inputSystem = InputSystem()
    let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem?
    private let latchSystem: LatchSystem?
    let distanceScoreSystem = DistanceScoreSystem()
    let hapticsController: HapticsController
    private let collisionSystem = CollisionSystem()

    // MARK: - World Container

    /// Parent node for gameplay objects that exist in the road/world space.
    ///
    /// Spawned floor and obstacle rows live in `worldNode`, while the active
    /// player and vehicle live in `gameplayNode`. Keeping them separate lets us
    /// merge dev's treadmill setup without shifting the movement prototype's
    /// start position.
    let worldNode = SKNode()
    private let targetReticleNode = SKShapeNode()
    let gameplayNode = SKNode()
    var spawnSystem: SpawnSystem?

    // MARK: - Runtime State

    var gameState: GameState = .waitingToStart
    var playerState: PlayerState = .idle
    var playerEntity: PlayerEntity?
    var currentVehicleEntity: VehicleEntity?
    var gameOverScreen: GameOverScreen?
    var lastUpdateTime: TimeInterval = 0
    private var menuScreen: MenuScreen?
    var dimmedStartScreen: DimmedStartScreen?
    var tutorialScreen: TutorialScreen?
    var tutorialScreen2: TutorialScreen2?
    var tutorialScreen3: TutorialScreen3?
    var tutorialScreen4: TutorialScreen4?
    var hasShownSteerTutorial: Bool = false
    var hasShownReleaseTutorial: Bool = false
    var hasShownLatchTutorial: Bool = false
    var tutorialInitialTouchLocation: CGPoint?
    var isShowingSteerTutorial = false
    var isShowingReleaseTutorial = false
    var isShowingLatchTutorial = false
    var canDismissSteerTutorial = false
    var activeSettingsSource: SettingsSource?
    var currentTimeScale: CGFloat = 1.0
    var targetTimeScale: CGFloat = 1.0
    var lastFrameVehiclePosition: CGPoint?
    var steerIdleTimer: TimeInterval = 0

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

    init(
        size: CGSize,
        configuration: GameConfiguration = .standard,
        hapticsController: HapticsController = .shared
    ) {
        self.configuration = configuration
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: configuration)
        self.latchSystem = LatchSystem(configuration: configuration)
        self.hapticsController = hapticsController
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .standard
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: .standard)
        self.latchSystem = LatchSystem(configuration: .standard)
        self.hapticsController = .shared
        super.init(coder: aDecoder)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    // MARK: - SpriteKit Lifecycle

    override func didMove(to view: SKView) {
        hapticsController.prepare()
        setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = makeDeltaTime(from: currentTime)
        guard gameState == .playing else { return }

        spawnSystem?.update(deltaTime: deltaTime)
        updateJumpingPlayer(deltaTime)
        updateDistanceScore(deltaTime)
        tutorialScreen3?.update()
        
        // TRIGGER TUTORIAL 2 SAAT JARAK MENCAPAI 40m
        // Hanya muncul jika highscore < 400m
        let highscore = UserDefaults.standard.integer(forKey: "Nomad.DistanceScoreSystem.highScoreMeters")
        if highscore < 400 && !hasShownSteerTutorial && distanceScoreSystem.currentDistanceMeters >= 40 {
            showSteerTutorial()
        }
        
        if let vehicle = currentVehicleEntity, let player = playerEntity {
            if playerState == .riding {
                let currentPos = vehicle.node.position
                if let lastPos = lastFrameVehiclePosition {
                    let deltaX = currentPos.x - lastPos.x
                    
                    if deltaX < -1.3 {
                        player.steerVisual(isLeft: true)
                        steerIdleTimer = 0.2
                    } else if deltaX > 1.3 {
                        player.steerVisual(isLeft: false)
                        steerIdleTimer = 0.2
                    } else {
                        steerIdleTimer -= deltaTime
                        if steerIdleTimer <= 0 {
                            player.idleVisual()
                        }
                    }
                }
                lastFrameVehiclePosition = currentPos

                movementSystem.updateLerp(vehicle: vehicle, deltaTime: deltaTime)
                player.place(on: vehicle)
                checkReleaseTutorialTrigger()
            }

            if updateCollisionGameOverIfNeeded(for: vehicle) { return }
            vehicle.component(ofType: VehicleRageComponent.self)?.update(deltaTime: deltaTime)
        }

        if playerState == .riding, let vehicle = currentVehicleEntity, let player = playerEntity {
            player.place(on: vehicle)
            if updateCollisionGameOverIfNeeded(for: vehicle) { return }
        }
    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if childNode(withName: "resumeCountdownNode") != nil { return }
        let sceneLocation = touch.location(in: self)

        if gameState == .gameOver {
            handleGameOverTouch(at: sceneLocation)
            return
        }

        if gameState == .paused {
            if let settingsScreen = childNode(withName: "settingsScreen") as? SettingsScreen {
                _ = settingsScreen.handleTouch(at: sceneLocation)
            } else {
                handlePauseTouch(at: sceneLocation)
            }
            return
        }
        
        if isShowingSteerTutorial {
            tutorialInitialTouchLocation = touch.location(in: self)
            return
        }

        if let dimmedStartScreen {
            dimmedStartScreen.beginHold()
            handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
            return
        }
        
        if let tutorialScreen {
            tutorialScreen.beginHold()
            handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
            return
        }

        if let tutorialScreen4 {
            tutorialScreen4.beginHold()
            handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
            return
        }

        if handlePauseButtonTouch(at: sceneLocation) { return }
        if let menuScreen {
            menuScreen.handleTouch(at: sceneLocation)
            return
        }
        handle(inputSystem.begin(at: touch.location(in: gameplayNode)))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // DISMISS TUTORIAL 2 SAAT DRAG
        if let tutorialScreen2, isShowingSteerTutorial {

            let currentLocation = touch.location(in: self)

            // pertama kali move saat tutorial muncul
            if tutorialInitialTouchLocation == nil {
                tutorialInitialTouchLocation = currentLocation
                return
            }

            let dx = currentLocation.x - tutorialInitialTouchLocation!.x
            let dy = currentLocation.y - tutorialInitialTouchLocation!.y

            let distance = sqrt(dx * dx + dy * dy)

            // hanya dismiss jika benar-benar drag
            if distance > 15 {

                tutorialScreen2.dismiss()
                self.tutorialScreen2 = nil

                targetTimeScale = 1.0
                currentTimeScale = 1.0
                self.speed = 1.0

                isShowingSteerTutorial = false
            }

            return
        }

        guard gameState != .gameOver, gameState != .paused else { return }
        handle(inputSystem.move(to: touch.location(in: gameplayNode)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if gameState == .gameOver || gameState == .paused { return }
        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
        
        if isShowingSteerTutorial {
            canDismissSteerTutorial = true
            return
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard gameState != .gameOver, gameState != .paused else { return }
        handle(inputSystem.end(at: touch.location(in: gameplayNode)))
    }
}

// MARK: - Scene Setup

extension GameScene {
    func setUpScene(skipsMenu: Bool = false, showsMenuImmediately: Bool = false) {
        hapticsController.stopRagePulse()
        hapticsController.prepare()

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
        lastFrameVehiclePosition = nil
        worldNode.isPaused = false
        gameplayNode.isPaused = false
        distanceScoreSystem.resetRun()
        setUpHUD()
        inputSystem.reset()
        
        self.tutorialScreen = nil
        self.tutorialScreen2 = nil
        self.tutorialScreen3 = nil
        self.tutorialScreen4 = nil
        self.hasShownSteerTutorial = false
        self.hasShownReleaseTutorial = false
        self.hasShownLatchTutorial = false

        if skipsMenu {
            showStartOverlay()
        } else {
            showMenuScreen(animated: !showsMenuImmediately)
        }
    }
}

private extension GameScene {

    func setUpNodes() {
        worldNode.name = "world"
        worldNode.position = CGPoint(x: 0, y: -size.height * 0.8)
        worldNode.zPosition = RenderLayer.floor
        addChild(worldNode)

        gameplayNode.name = "gameplay"
        gameplayNode.position = .zero
        gameplayNode.zPosition = RenderLayer.vehicle
        addChild(gameplayNode)
        
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
        spawnSystem = SpawnSystem(worldNode: worldNode, sceneSize: size)
    }

    func setUpMovementPrototype() {
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
        let path = CGMutablePath()
        path.move(to: configuration.movementAxisStartPosition)
        path.addLine(to: configuration.movementAxisEndPosition)
        let guideNode = SKShapeNode(path: path)
        guideNode.name = "movementBoundsGuide"
        guideNode.strokeColor = SKColor.white.withAlphaComponent(0.85)
        guideNode.lineWidth = 4
        guideNode.zPosition = RenderLayer.overlay
        gameplayNode.addChild(guideNode)
        addMovementBoundCap(at: configuration.movementAxisStartPosition)
        addMovementBoundCap(at: configuration.movementAxisEndPosition)
    }

    func addMovementBoundCap(at position: CGPoint) {
        let capNode = SKShapeNode(circleOfRadius: 5)
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
    func updateCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        if updateObstacleCollisionGameOverIfNeeded(for: vehicle) { return true }
        return updateVehicleCollisionGameOverIfNeeded(for: vehicle)
    }

    func updateObstacleCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        guard let obstacles = spawnSystem?.obstacleEntities,
              collisionSystem.checkCollision(vehicle: vehicle, with: obstacles) != nil else {
            return false
        }
        enterGameOver(playerEndState: .crashed)
        return true
    }

    func updateVehicleCollisionGameOverIfNeeded(for vehicle: VehicleEntity) -> Bool {
        guard let otherVehicles = spawnSystem?.vehicleEntities,
              collisionSystem.checkVehicleCollision(playerVehicle: vehicle, with: otherVehicles) != nil else {
            return false
        }
        enterGameOver(playerEndState: .crashed)
        return true
    }

    func updateJumpingPlayer(_ deltaTime: TimeInterval) {
        guard let playerEntity else { return }
        if playerState == .jumping {
            let launchResult = launchSystem?.update(player: playerEntity, deltaTime: deltaTime)
            let allVehicles = spawnSystem?.vehicleEntities ?? []
            let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
            let bestTarget = latchSystem?.getBestTarget(player: playerEntity, vehicles: activeVehicles)
            
            if let target = bestTarget {
                // Jangan timpa jika sedang dalam tutorial latch (yang lebih lambat)
                if !isShowingLatchTutorial {
                    targetTimeScale = 0.6
                }
                targetReticleNode.position = CGPoint(x: target.node.position.x, y: target.node.position.y + 40)
                if targetReticleNode.alpha == 0 { targetReticleNode.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15)) }
            } else {
                if !isShowingLatchTutorial {
                    targetTimeScale = 1.0
                }
                if targetReticleNode.alpha > 0 { targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.15)) }
            }
            if launchResult == .fell { enterFallGameOver() }
        }
    }

    func makeDeltaTime(from currentTime: TimeInterval) -> TimeInterval {
        defer { lastUpdateTime = currentTime }
        guard lastUpdateTime > 0 else { return 0 }
        let rawDelta = min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
        let scaleDiff = targetTimeScale - currentTimeScale
        if abs(scaleDiff) < 0.01 { currentTimeScale = targetTimeScale }
        else { currentTimeScale += scaleDiff * CGFloat(rawDelta * 4.0) }
        let dilatedDelta = rawDelta * TimeInterval(currentTimeScale)
        self.speed = currentTimeScale
        return dilatedDelta
    }
}

// MARK: - Game Over Presentation Support

extension GameScene {
    func resetGameOverTiming() {
        hapticsController.stopRagePulse()
        targetTimeScale = 1.0
        currentTimeScale = 1.0
        speed = 1.0
    }

    func cleanUpFallImpactPresentation() {
        targetReticleNode.removeAllActions()
        targetReticleNode.alpha = 0.0
        if let playerEntity {
            playerEntity.node.removeAllActions()
            playerEntity.node.setScale(1.0)
        }
    }
}

// MARK: - Input State Machine

private extension GameScene {
    func handle(_ inputPhase: InputPhase) {
        guard let playerEntity, let currentVehicleEntity else { return }
        playerEntity.recordInput(inputPhase)

        switch inputPhase {
        case .holding(let startLocation) where gameState == .waitingToStart:
            playerEntity.idleVisual()
            playerEntity.attach(to: currentVehicleEntity)
            currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.onJumpRequested = { [weak self] in self?.forcePlayerToJump() }
            currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.startRageCycle()
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)
            gameState = .playing
            playerState = .riding

        case .holding(let startLocation) where gameState == .playing && playerState == .riding:
            playerEntity.idleVisual()
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)

        case .dragging where gameState == .playing && playerState == .riding:
            movementSystem.updateVehicleAndRider(vehicle: currentVehicleEntity, player: playerEntity, inputPhase: inputPhase)

        case .released where gameState == .playing && playerState == .riding:
            if let tutorialScreen3 {
                tutorialScreen3.beginRelease()
            }
            forcePlayerToJump()

        case .holding(let startLocation) where gameState == .playing && playerState == .jumping:
            playerState = .latching
            let allVehicles = spawnSystem?.vehicleEntities ?? []
            let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
            if let latchedVehicle = latchSystem?.attemptLatch(player: playerEntity, onto: activeVehicles) {
                completeLatch(on: latchedVehicle, startLocation: startLocation)
            } else {
                let failedLatchFallDistance = configuration.vehicleSize.height * 0.55
                playerEntity.component(ofType: LaunchComponent.self)?.beginFailedLatchFall(from: playerEntity.node.position, direction: configuration.jumpForwardUnitVector, distance: failedLatchFallDistance, duration: configuration.playerFallSettleDuration)
                playerState = .jumping
            }
        default: break
        }
    }
}

// MARK: - Movement State Helpers

private extension GameScene {
    func forcePlayerToJump() {
        guard let currentVehicleEntity, let playerEntity, playerState == .riding else { return }
        currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.stopRageHaptics()
        movementSystem.endSteering(vehicle: currentVehicleEntity)
        let wait = SKAction.wait(forDuration: 0.3)
        let reset = SKAction.run { [weak currentVehicleEntity] in currentVehicleEntity?.component(ofType: VehicleRageComponent.self)?.resetRageCycle() }
        currentVehicleEntity.node.run(SKAction.sequence([wait, reset]))
        spawnSystem?.adopt(oldVehicle: currentVehicleEntity)
        currentVehicleEntity.removeComponent(ofType: MovementComponent.self)
        currentVehicleEntity.addComponent(MovementComponent(speed: 0))
        launchSystem?.launch(player: playerEntity)
        playerEntity.playJumpVisual(duration: configuration.jumpForwardDuration)
        playerState = .jumping
    }
    
    func pausePlayerAfterFall() {
        targetTimeScale = 1.0
        playerEntity?.cancelJumpVisual()
        targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.1))
        playerState = .falling
        if let currentVehicleEntity { movementSystem.endSteering(vehicle: currentVehicleEntity) }
    }
    
    func checkReleaseTutorialTrigger() {
        let highscore = UserDefaults.standard.integer(forKey: "Nomad.DistanceScoreSystem.highScoreMeters")
        guard highscore < 400, !hasShownReleaseTutorial, playerState == .riding, let vehicle = currentVehicleEntity else { return }
        
        // 1. Check Rage 2 (HittingState)
        if let rageComponent = vehicle.component(ofType: VehicleRageComponent.self) {
            if rageComponent.stateMachine?.currentState is VehicleHittingState {
                showReleaseTutorial()
                return
            }
        }
        
        // 2. Check Jump Range
        let allVehicles = spawnSystem?.vehicleEntities ?? []
        let activeVehicles = allVehicles.filter { $0 !== currentVehicleEntity }
        
        let landingPos = configuration.jumpForwardLandingPosition(from: vehicle.node.position)
        
        for v in activeVehicles {
            let vPos = v.node.position
            let dx = vPos.x - landingPos.x
            let dy = vPos.y - landingPos.y
            let dist = sqrt(dx * dx + dy * dy)
            
            if dist < configuration.latchDistance * 1.5 {
                showReleaseTutorial()
                return
            }
        }
    }
    
    func completeLatch(on vehicle: VehicleEntity, startLocation: CGPoint? = nil) {
        guard let playerEntity else { return }
        playerEntity.cancelJumpVisual()
        targetTimeScale = 1.0
        targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.1))
        spawnSystem?.removeVehicle(entity: vehicle)
        let newParent = gameplayNode
        if let oldParent = vehicle.node.parent, oldParent !== newParent {
            let interceptedPos = oldParent.convert(vehicle.node.position, to: newParent)
            vehicle.node.removeFromParent()
            vehicle.node.position = interceptedPos
            newParent.addChild(vehicle.node)
        }
        vehicle.node.zPosition = RenderLayer.vehicle
        let steering = MovementComponent(anchorPosition: configuration.currentVehiclePosition, currentPosition: vehicle.node.position, screenSize: configuration.referenceScreenSize, vehicleSize: configuration.vehicleSize, movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees, movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds, dragSensitivity: configuration.dragSensitivity)
        steering.startLerping(to: configuration.currentVehiclePosition)
        vehicle.addComponent(steering)
        playerEntity.attach(to: vehicle)
        currentVehicleEntity = vehicle
        vehicle.component(ofType: VehicleRageComponent.self)?.onJumpRequested = { [weak self] in self?.forcePlayerToJump() }
        vehicle.component(ofType: VehicleRageComponent.self)?.startRageCycle()
        if let startLocation { movementSystem.beginSteering(vehicle: vehicle, at: startLocation) }
        gameState = .playing
        playerState = .riding
    }
}

// MARK: - Score Result

struct ScoreResult {
    let distanceMeters: Int
    let highScoreMeters: Int
    let isNewHighScore: Bool
}

// MARK: - Distance Score System

final class DistanceScoreSystem {
    private enum StorageKey { static let highScoreMeters = "Nomad.DistanceScoreSystem.highScoreMeters" }
    private let userDefaults: UserDefaults
    private(set) var currentDistanceMeters: Int = 0
    private var distanceMetersAccumulator: CGFloat = 0
    init(userDefaults: UserDefaults = .standard) { self.userDefaults = userDefaults }
    func resetRun() { currentDistanceMeters = 0; distanceMetersAccumulator = 0 }
    func updateDistance(deltaTime: TimeInterval, metersPerSecond: CGFloat) {
        guard deltaTime > 0 else { return }
        distanceMetersAccumulator += CGFloat(deltaTime) * metersPerSecond
        currentDistanceMeters = max(0, Int(distanceMetersAccumulator.rounded(.down)))
    }
    func setDistanceMeters(_ meters: Int) { currentDistanceMeters = max(0, meters); distanceMetersAccumulator = CGFloat(currentDistanceMeters) }
    func finishRun() -> ScoreResult {
        let previousHighScore = userDefaults.integer(forKey: StorageKey.highScoreMeters)
        let isNewHighScore = currentDistanceMeters > previousHighScore
        let finalHighScore = isNewHighScore ? currentDistanceMeters : previousHighScore
        if isNewHighScore { userDefaults.set(finalHighScore, forKey: StorageKey.highScoreMeters) }
        return ScoreResult(distanceMeters: currentDistanceMeters, highScoreMeters: finalHighScore, isNewHighScore: isNewHighScore)
    }
}

// MARK: - Menu Screen

private extension GameScene {
    func showMenuScreen(animated: Bool = true) {
        let menu = MenuScreen(sceneSize: size, hapticsController: hapticsController)
        menu.onStartTapped = { [weak self] in
            guard let self else { return }
            self.menuScreen = nil
            self.showStartOverlay()
        }
        menu.onSettingsTapped = { [weak self] in
            guard let self else { return }
            self.activeSettingsSource = .menu
            let settings = SettingsScreen(sceneSize: self.size)
            settings.onClosed = { [weak self] in self?.activeSettingsSource = nil }
            settings.show(in: self)
        }
        menu.show(in: self, animated: animated)
        self.menuScreen = menu
    }
}
