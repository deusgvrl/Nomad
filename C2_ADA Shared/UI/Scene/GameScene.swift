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
    let audioController: AudioController
    private let collisionSystem = CollisionSystem()

    // MARK: - World Container

    /// Parent node for gameplay objects that exist in the road/world space.
    ///
    /// Spawned floor and obstacle rows live in `worldNode`, while the active
    /// player and vehicle live in `gameplayNode`. Keeping them separate lets us
    /// merge dev's treadmill setup without shifting the movement prototype's
    /// start position.
    let worldNode = SKNode()
    private let targetReticleNode = SKSpriteNode()
    let targetTutorialHighlightNode = SKNode()
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
        hapticsController: HapticsController = .shared,
        audioController: AudioController = .shared
    ) {
        self.configuration = configuration
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: configuration)
        self.latchSystem = LatchSystem(configuration: configuration)
        self.hapticsController = hapticsController
        self.audioController = audioController
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .standard
        self.movementSystem = MovementSystem()
        self.launchSystem = LaunchSystem(configuration: .standard)
        self.latchSystem = LatchSystem(configuration: .standard)
        self.hapticsController = .shared
        self.audioController = .shared
        super.init(coder: aDecoder)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    // MARK: - SpriteKit Lifecycle

    override func didMove(to view: SKView) {
        hapticsController.prepare()
        audioController.attach(to: self)
        setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        let timing = makeDeltaTime(from: currentTime)

        // Selalu periksa visibilitas highlight tutorial meskipun sedang pause atau game over
        if !isShowingLatchTutorial {
            if targetTutorialHighlightNode.alpha > 0 {
                targetTutorialHighlightNode.alpha = 0
            }
        }
        guard gameState == .playing else { return }

        spawnSystem?.update(deltaTime: timing.worldDelta)
        updateJumpingPlayer(timing.playerDelta)
        updateDistanceScore(timing.worldDelta)
        tutorialScreen3?.update()
        
        // TRIGGER TUTORIAL 2 SAAT JARAK MENCAPAI 40m
        // Hanya muncul jika highscore < 400m
        let highscore = UserDefaults.standard.integer(forKey: "Nomad.DistanceScoreSystem.highScoreMeters")
        if highscore < 400 && !hasShownSteerTutorial && distanceScoreSystem.currentDistanceMeters >= 40 {
            showSteerTutorial()
        }
        
        // DISMISS TUTORIAL 2 SAAT JARAK MENCAPAI 60m
        if isShowingSteerTutorial && distanceScoreSystem.currentDistanceMeters >= 60 {
            tutorialScreen2?.dismiss()
            self.tutorialScreen2 = nil
            self.isShowingSteerTutorial = false
            
            targetTimeScale = 1.0
            currentTimeScale = 1.0
            self.speed = 1.0
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
                        steerIdleTimer -= timing.worldDelta
                        if steerIdleTimer <= 0 {
                            player.idleVisual()

                            // MARK: Steering Audio Idle Stop
                            // SpriteKit sends no new move event when a finger
                            // becomes stationary. End the turning loop with the
                            // established steering-visual idle window so it
                            // represents active sliding only.
                            audioController.stopLoop(.steering)
                        }
                    }
                }
                lastFrameVehiclePosition = currentPos

                movementSystem.updateLerp(vehicle: vehicle, deltaTime: timing.worldDelta)
                player.place(on: vehicle)
                checkReleaseTutorialTrigger()
            }

            if updateCollisionGameOverIfNeeded(for: vehicle) { return }
            
            // Update rage State
            vehicle.component(ofType: VehicleRageComponent.self)?.update(deltaTime: timing.worldDelta)
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
        
//        if isShowingSteerTutorial {
//            tutorialInitialTouchLocation = touch.location(in: self)
//            // Biarkan input lanjut ke gameplay agar player bisa mencoba steer saat tutorial muncul
//        }

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

        // MARK: Audio Run Reset
        // Retry and Home rebuild the same scene instance. Clear active loop
        // intent before removing children so an old engine or rage warning
        // cannot leak into the next waiting/menu state.
        audioController.resetGameplayAudio()

        removeAllChildren()
        worldNode.removeAllChildren()
        gameplayNode.removeAllChildren()

        // `removeAllChildren()` also removes the controller's scene audio root.
        // Reattach it immediately so the first hold can start engine playback.
        audioController.attach(to: self)

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
        
        targetTutorialHighlightNode.alpha = 0 // Pastikan sembunyi saat reset
        
        self.tutorialScreen = nil
        self.tutorialScreen2 = nil
        self.tutorialScreen3 = nil
        self.tutorialScreen4 = nil
        self.hasShownSteerTutorial = false
        self.hasShownReleaseTutorial = false
        self.hasShownLatchTutorial = false
        self.isShowingSteerTutorial = false
        self.isShowingReleaseTutorial = false
        self.isShowingLatchTutorial = false

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
        
//        let ringDiameter = configuration.latchDistance * 2
//        let path = CGPath(ellipseIn: CGRect(x: -ringDiameter/2, y: -ringDiameter/2, width: ringDiameter, height: ringDiameter), transform: nil)
//        targetReticleNode.path = path
        targetReticleNode.texture = SKTexture(imageNamed: NomadAsset.reticle.rawValue)
        
        let ringDiameter = configuration.latchDistance * 2.5
        targetReticleNode.size = CGSize(width: ringDiameter, height: ringDiameter)
        targetReticleNode.zPosition = -1
        targetReticleNode.strokeColor = ColorHelper.fromHex(0xF6A74C) // Orange like Tutorial 1
        targetReticleNode.lineWidth = 4
        targetReticleNode.alpha = 0
        
        targetReticleNode.xScale = 1.0
        targetReticleNode.yScale = 1.0
        worldNode.addChild(targetReticleNode)

        // MARK: Target Tutorial Highlight Setup
        let targetRadius: CGFloat = 65
        let targetDotsCount = 20
        targetTutorialHighlightNode.removeAllChildren()
        for i in 0..<targetDotsCount {
            let angle = CGFloat(i) * .pi * 2 / CGFloat(targetDotsCount)
            let dot = SKShapeNode(circleOfRadius: 3.0)
            dot.fillColor = ColorHelper.fromHex(0xF6A74C) // Orange like Tutorial 1
            dot.strokeColor = .clear
            dot.position = CGPoint(x: cos(angle) * targetRadius, y: sin(angle) * targetRadius)
            targetTutorialHighlightNode.addChild(dot)
        }
        // Muncul di atas semua (termasuk vehicle dan dim tutorial)
        targetTutorialHighlightNode.zPosition = RenderLayer.dimmed + 10
        targetTutorialHighlightNode.alpha = 0
        worldNode.addChild(targetTutorialHighlightNode)
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
            
            // Mencari target: Dalam Tutorial 4, kita tunjukkan mobil terdekat di depan meskipun belum dalam jangkauan latch
            var bestTarget: VehicleEntity?
            if isShowingLatchTutorial {
                bestTarget = activeVehicles
                    .filter { $0.node.position.y > playerEntity.node.position.y }
                    .min(by: { 
                        let d1 = hypot($0.node.position.x - playerEntity.node.position.x, $0.node.position.y - playerEntity.node.position.y)
                        let d2 = hypot($1.node.position.x - playerEntity.node.position.x, $1.node.position.y - playerEntity.node.position.y)
                        return d1 < d2
                    })
            } else {
                bestTarget = latchSystem?.getBestTarget(player: playerEntity, vehicles: activeVehicles)
            }

            if let target = bestTarget {
                if isShowingLatchTutorial {
                    // Offset disesuaikan agar lebih maju dan pas di tengah mobil
                    targetTutorialHighlightNode.position = CGPoint(
                        x: target.node.position.x + -2,
                        y: target.node.position.y + 35,
                    )
                    
                    if targetTutorialHighlightNode.alpha == 0 {
                        targetTutorialHighlightNode.alpha = 1.0 // Langsung muncul 100%
                    }
                } else {
                    // Pastikan highlight tutorial sembunyi jika bukan Tutorial 4
                    if targetTutorialHighlightNode.alpha > 0 {
                        targetTutorialHighlightNode.alpha = 0
                    }
                }

                // Jangan timpa jika sedang dalam tutorial latch (yang lebih lambat)
                if !isShowingLatchTutorial {
                    targetTimeScale = 0.6
                    
                    // Hanya tampilkan reticle kuning standar jika BUKAN tutorial 4
                    targetReticleNode.position = CGPoint(x: target.node.position.x, y: target.node.position.y + 40)
                    if targetReticleNode.alpha == 0 { targetReticleNode.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15)) }
                } else {
                    // Pastikan reticle kuning sembunyi saat tutorial 4
                    if targetReticleNode.alpha > 0 { targetReticleNode.alpha = 0 }
                }
            } else {
                if targetTutorialHighlightNode.alpha > 0 {
                    targetTutorialHighlightNode.alpha = 0
                }

                if !isShowingLatchTutorial {
                    targetTimeScale = 1.0
                }
                
                if targetReticleNode.alpha > 0 { targetReticleNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.15)) }
            }
            if launchResult == .fell { enterFallGameOver() }
        } else {
            if targetTutorialHighlightNode.alpha > 0 {
                targetTutorialHighlightNode.run(SKAction.fadeAlpha(to: 0.0, duration: 0.15))
            
            if currentTimeScale < 1.0 {
                playerEntity.node.speed = 0.5
            } else {
                playerEntity.node.speed = 1.0
            }
            
            if launchResult == .fell {
                enterFallGameOver()
            }
        } 
    }

    // MARK: - Delta Time
    struct FrameTiming {
        let worldDelta: TimeInterval
        let playerDelta: TimeInterval
    }

    /// Caps delta time so a simulator pause does not create a giant jump update.
    func makeDeltaTime(from currentTime: TimeInterval) -> FrameTiming {
        defer { lastUpdateTime = currentTime }

        guard lastUpdateTime > 0 else { return FrameTiming(worldDelta: 0, playerDelta: 0) }
        let rawDelta = min(currentTime - lastUpdateTime, configuration.maximumDeltaTime)
        let scaleDiff = targetTimeScale - currentTimeScale
        if abs(scaleDiff) < 0.01 {
            currentTimeScale = targetTimeScale
        } else {
            currentTimeScale += scaleDiff * CGFloat(rawDelta * 2.75)
        }
        
        let dilatedDelta = rawDelta * TimeInterval(currentTimeScale)
        self.speed = currentTimeScale
        
        var playerPhysicsDelta = dilatedDelta
        
        if currentTimeScale < 1.0 {
            playerPhysicsDelta = dilatedDelta * 0.5
        }
        return FrameTiming(worldDelta: dilatedDelta, playerDelta: playerPhysicsDelta)
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

            // MARK: Music Handoff On Run Start
            // The home track deliberately survives the menu and hold-to-start
            // overlay. Swap tracks only when input starts an actual playable run.
            audioController.stopLoop(.homeBackground)
            audioController.startLoop(.inGameMusic)

            // MARK: Initial Ride Engine Loop
            // The engine represents only the vehicle currently controlled by
            // the player, so it begins when the first ride becomes active.
            audioController.startLoop(.engine)

        case .holding(let startLocation) where gameState == .playing && playerState == .riding:
            playerEntity.idleVisual()
            movementSystem.beginSteering(vehicle: currentVehicleEntity, at: startLocation)

        case .dragging where gameState == .playing && playerState == .riding:
            let previousPosition = currentVehicleEntity.node.position
            movementSystem.updateVehicleAndRider(vehicle: currentVehicleEntity, player: playerEntity, inputPhase: inputPhase)

            // MARK: Active Steering Audio
            // Input can continue while the car is clamped at the road edge.
            // Sound only while the vehicle actually changes position so an
            // unmoving drag does not imply a turn that never happened.
            if currentVehicleEntity.node.position != previousPosition {
                audioController.startLoop(.steering)
            } else {
                audioController.stopLoop(.steering)
            }

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
        currentVehicleEntity.component(ofType: VehicleRageComponent.self)?.stopRageAudio()

        // MARK: Ride Audio Stop On Launch
        // Manual release and rage-forced launch share this method. Both stop
        // the owned vehicle and finger-drag loops as soon as the rider leaves.
        audioController.stopLoop(.engine)
        audioController.stopLoop(.steering)
        audioController.stopLoop(.rageHitting)

        // MARK: Jump Sound Effect
        // Both release input and a rage-forced launch enter through this method.
        // Sound at takeoff because landing success is determined later.
        audioController.play(.playerJump)

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
        
        // ===== Tutorial 4 Cleanup =====
        isShowingLatchTutorial = false
        hasShownLatchTutorial = true

        tutorialScreen4?.hide() // TutorialScreen4 uses hide()
        tutorialScreen4 = nil

        targetTutorialHighlightNode.removeAllActions()
        targetTutorialHighlightNode.alpha = 0

        targetReticleNode.removeAllActions()
        targetReticleNode.alpha = 0
        
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

        // MARK: Successful Latch Audio
        // This method is reached only after an airborne latch, so the landing
        // effect is not played for the starting vehicle. The newly controlled
        // car then owns the single active engine loop.
        audioController.play(.landsOnCar)
        audioController.startLoop(.engine)
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
        // MARK: Home Music Loop
        // Menu Settings and the subsequent hold-to-start overlay share this
        // soundtrack; the first playable hold performs the music handoff.
        audioController.startLoop(.homeBackground)

        let menu = MenuScreen(
            sceneSize: size,
            hapticsController: hapticsController,
            audioController: audioController
        )
        menu.onStartTapped = { [weak self] in
            guard let self else { return }
            self.menuScreen = nil
            self.showStartOverlay()
        }
        menu.onSettingsTapped = { [weak self] in
            guard let self else { return }
            self.activeSettingsSource = .menu
            let settings = SettingsScreen(
                sceneSize: self.size,
                hapticsController: self.hapticsController,
                audioController: self.audioController
            )
            settings.onClosed = { [weak self] in self?.activeSettingsSource = nil }
            settings.show(in: self)
        }
        menu.show(in: self, animated: animated)
        self.menuScreen = menu
    }
}
