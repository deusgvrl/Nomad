//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import Foundation
import SpriteKit
import GameplayKit
import UIKit
import CoreText

// MARK: - Game Scene

/// Main SpriteKit scene for Nomad's movement prototype.
///
/// This file is the merged scene:
/// - keeps the newer `worldNode` and `SpawnSystem` structure from `UI/Scene`;
/// - brings in the old prototype's hold, drag, release, jump, and latch logic;
/// - owns the fall game-over flow and overlay while obstacle collision is still
///   being finished on another branch.
final class GameScene: SKScene {

    // MARK: - Dependencies

    private let configuration: GameConfiguration
    private let inputSystem = InputSystem()
    private let movementSystem: MovementSystem
    private let launchSystem: LaunchSystem?
    private let latchSystem: LatchSystem?
    private let distanceScoreSystem = DistanceScoreSystem()
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

    private var gameState: GameState = .waitingToStart
    private var playerState: PlayerState = .idle
    private var playerEntity: PlayerEntity?
    private var currentVehicleEntity: VehicleEntity?
    private var gameOverOverlayNode: SKNode?
    private var gameOverRetryButtonNode: SKNode?
    private var gameOverHomeButtonNode: SKNode?
    private var lastUpdateTime: TimeInterval = 0

    /// Prevents CoreText from re-registering the same whole-game fonts every
    /// time the scene resets after Try Again.
    private static var didRegisterGameFonts = false

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
        guard gameState == .playing else { return }

        spawnSystem?.update(currentTime)
        updateDistanceScore(deltaTime)
        updateJumpingPlayer(deltaTime)

        if playerState == .riding, let vehicle = currentVehicleEntity, let player = playerEntity {
            player.place(on: vehicle)

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

            // 2. Cek tabrakan antar kendaraan (Mobil pemain vs Mobil lain)
            // PERBAIKAN: Sekarang mobil bisa saling bertabrakan jika berada di jalur yang sama.
            if let others = spawnSystem?.vehicleEntities {

                // --- DEBUG: Show other vehicle hitboxes (OFF) ---
                /*
                for other in others {
                    if other !== vehicle {
                        other.component(ofType: HitboxComponent.self)?.showDebugHitbox(in: other.node, color: .blue)
                    }
                }
                */

                if collisionSystem.checkVehicleCollision(playerVehicle: vehicle, with: others) != nil {
                    print("Collision with another vehicle!")
                    
                    // TODO: Replace this pause logic with a formal Game Over sequence/Scene transition
                    gameState = .gameOver
                    playerState = .crashed
                }
            }
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

private extension GameScene {

    func setUpScene() {
        registerGameFontsIfNeeded()

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
        gameOverRetryButtonNode = nil
        gameOverHomeButtonNode = nil
        gameState = .waitingToStart
        playerState = .idle
        lastUpdateTime = 0
        distanceScoreSystem.resetRun()
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
            launchSystem?.launch(
                player: playerEntity,
                landingTargetPosition: fallLandingPosition(
                    for: playerEntity,
                    vehicle: currentVehicleEntity
                )
            )
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
        
        // 1. Remove the old vehicle from the scene
        if let oldVehicle = currentVehicleEntity {
            oldVehicle.node.removeFromParent()
            spawnSystem?.removeVehicle(entity: oldVehicle)
        }
        
        // 2. Remove new vehicle from SpawnSystem's automatic flow
        spawnSystem?.removeVehicle(entity: vehicle)
        
        // 3. Move the new vehicle to the initial spawn position
        let newParent = gameplayNode
        vehicle.node.removeFromParent()
        vehicle.node.position = configuration.currentVehiclePosition
        newParent.addChild(vehicle.node)
        
        vehicle.node.zPosition = ZPosition.vehicle
        
        // 4. Initialize steering starting from the spawn position
        let steering = MovementComponent(
            position: configuration.currentVehiclePosition,
            screenSize: configuration.referenceScreenSize,
            vehicleSize: configuration.vehicleMovementBoundsSize,
            movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
            movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
            dragSensitivity: configuration.dragSensitivity
        )
        vehicle.addComponent(steering)
        
        // 5. Attach player (this also reparents player to the vehicle)
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
//            vehicle.node.zPosition = ZPosition.vehicle
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


// MARK: - Game Over Logic

private extension GameScene {

    // MARK: - Game Over Entry

    /// Ends the run, settles the player in front of the car, and shows the
    /// result overlay. Obstacle collision can call this same entry later.
    func enterGameOver(playerEndState: PlayerState = .crashed) {
        guard gameState != .gameOver else { return }

        gameState = .gameOver
        playerState = playerEndState

        if let currentVehicleEntity {
            movementSystem.endSteering(vehicle: currentVehicleEntity)
        }

        playerEntity?.component(ofType: LaunchComponent.self)?.reset()

        let scoreResult = distanceScoreSystem.finishRun()
        settlePlayerInFrontOfVehicle { [weak self] in
            self?.showGameOverOverlay(scoreResult: scoreResult)
        }
    }

    // MARK: - Fall Landing

    /// Snaps the failed jump back to a readable spot near the active car.
    /// This avoids the old off-screen X-axis drift from the launch velocity.
    func settlePlayerInFrontOfVehicle(completion: @escaping () -> Void) {
        guard let playerEntity, let currentVehicleEntity else {
            completion()
            return
        }

        let landingPosition = fallLandingPosition(
            for: playerEntity,
            vehicle: currentVehicleEntity
        )

        playerEntity.node.removeAllActions()
        playerEntity.node.zPosition = ZPosition.player

        let settleAction = SKAction.move(
            to: landingPosition,
            duration: configuration.playerFallSettleDuration
        )
        settleAction.timingMode = .easeOut
        playerEntity.node.run(settleAction, completion: completion)
    }

    /// Projects the failed jump from the player's current position along the
    /// same 60-degree road-forward line used by latch filtering.
    func fallLandingPosition(for player: PlayerEntity, vehicle _: VehicleEntity) -> CGPoint {
        let playerPosition = player.node.position
        let proposedPosition = configuration.jumpForwardLandingPosition(from: playerPosition)

        return clampedPlayerPosition(proposedPosition)
    }

    /// Keeps the settled player visible even if the car was near a screen edge.
    func clampedPlayerPosition(_ position: CGPoint) -> CGPoint {
        let halfPlayerWidth = configuration.playerSize.width / 2
        let halfPlayerHeight = configuration.playerSize.height / 2
        let xBounds = (-size.width / 2 + halfPlayerWidth)...(size.width / 2 - halfPlayerWidth)
        let yBounds = (-size.height / 2 + halfPlayerHeight)...(size.height / 2 - halfPlayerHeight)

        return CGPoint(
            x: min(max(position.x, xBounds.lowerBound), xBounds.upperBound),
            y: min(max(position.y, yBounds.lowerBound), yBounds.upperBound)
        )
    }

    // MARK: - Game Over Overlay

    /// Builds the full-screen overlay shown in the design reference.
    func showGameOverOverlay(scoreResult: ScoreResult) {
        guard gameOverOverlayNode == nil else { return }

        let overlayNode = SKNode()
        overlayNode.name = "gameOverOverlay"
        overlayNode.zPosition = ZPosition.gameOverOverlay
        overlayNode.alpha = 0

        overlayNode.addChild(makeGameOverDimLayer())
        overlayNode.addChild(makeGameOverTitle())

        if scoreResult.isNewHighScore {
            addNewHighScoreContent(to: overlayNode, scoreResult: scoreResult)
        } else {
            addRegularHighScoreContent(to: overlayNode, scoreResult: scoreResult)
        }

        let retryButton = makeTryAgainButton()
        overlayNode.addChild(retryButton)
        gameOverRetryButtonNode = retryButton

        let homeButton = makeHomeButton()
        overlayNode.addChild(homeButton)
        gameOverHomeButtonNode = homeButton

        gameOverOverlayNode = overlayNode
        addChild(overlayNode)

        overlayNode.run(SKAction.fadeIn(withDuration: 0.12))
    }

    // MARK: - Overlay Background

    func makeGameOverDimLayer() -> SKNode {
        let dimBackground = SKShapeNode(rectOf: configuration.referenceScreenSize)
        dimBackground.name = "gameOverDimLayer"
        dimBackground.fillColor = gameOverOverlayBrown.withAlphaComponent(0.70)
        dimBackground.strokeColor = .clear
        dimBackground.zPosition = 0
        return dimBackground
    }

    // MARK: - Overlay Title

    func makeGameOverTitle() -> SKLabelNode {
        // The title uses the darker reference orange and stays in the upper
        // result area like the right-side comparison screen.
        let titleLabel = makeLabel(
            text: "GAME OVER",
            fontName: configuration.primaryFontName,
            fontSize: 58,
            color: gameOverTitleColor
        )
        titleLabel.name = "gameOverTitle"
        titleLabel.position = CGPoint(x: 0, y: 190)
        return titleLabel
    }

    // MARK: - New Highscore Layout

    func addNewHighScoreContent(to overlayNode: SKNode, scoreResult: ScoreResult) {
        let crownNode = makeCrownNode()
        crownNode.position = CGPoint(x: 0, y: 104)
        overlayNode.addChild(crownNode)

        let newHighScoreLabel = makeLabel(
            text: "NEW HIGHSCORE",
            fontName: configuration.secondaryFontName,
            fontSize: 25,
            color: gameOverSecondaryTextColor
        )
        newHighScoreLabel.name = "gameOverNewHighScoreLabel"
        newHighScoreLabel.position = CGPoint(x: 0, y: 52)
        overlayNode.addChild(newHighScoreLabel)

        let scoreNode = makePrimaryScoreNode(scoreResult.distanceMeters)
        scoreNode.position = CGPoint(x: 0, y: -30)
        overlayNode.addChild(scoreNode)
    }

    // MARK: - Regular Highscore Layout

    func addRegularHighScoreContent(to overlayNode: SKNode, scoreResult: ScoreResult) {
        // The normal game-over score sits under the title with the large
        // primary type treatment from the reference.
        let scoreNode = makePrimaryScoreNode(scoreResult.distanceMeters)
        scoreNode.position = CGPoint(x: 0, y: 70)
        overlayNode.addChild(scoreNode)

        // Normal highscore copy uses #E28B40 and sits between the large score
        // and Try Again button so the result stack matches the reference.
        let highScoreTitleLabel = makeLabel(
            text: "YOUR HIGHSCORE",
            fontName: configuration.secondaryFontName,
            fontSize: 20,
            color: gameOverHighScoreTextColor
        )
        highScoreTitleLabel.name = "gameOverHighScoreTitle"
        highScoreTitleLabel.position = CGPoint(x: 0, y: -42)
        overlayNode.addChild(highScoreTitleLabel)

        // The saved highscore amount stays directly under the highscore label
        // while remaining above the shared Try Again button.
        let highScoreValueLabel = makeLabel(
            text: "\(scoreResult.highScoreMeters)m",
            fontName: configuration.secondaryFontName,
            fontSize: 25,
            color: gameOverHighScoreTextColor
        )
        highScoreValueLabel.name = "gameOverHighScoreValue"
        highScoreValueLabel.position = CGPoint(x: 0, y: -74)
        overlayNode.addChild(highScoreValueLabel)
    }

    // MARK: - Crown Symbol

    func makeCrownNode() -> SKNode {
        let crownTexture = makeTintedSymbolTexture(
            systemName: "crown",
            pointSize: 46,
            color: gameOverSecondaryTextColor.uiColor
        )
        let crownNode = SKSpriteNode(texture: crownTexture)
        crownNode.name = "gameOverCrown"
        crownNode.size = CGSize(width: 52, height: 42)
        return crownNode
    }

    func makeTintedSymbolTexture(
        systemName: String,
        pointSize: CGFloat,
        color: UIColor
    ) -> SKTexture? {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        guard let symbolImage = UIImage(
            systemName: systemName,
            withConfiguration: symbolConfiguration
        )?.withRenderingMode(.alwaysTemplate) else {
            return nil
        }

        let imageSize = CGSize(width: pointSize * 1.3, height: pointSize * 1.1)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let renderedImage = renderer.image { _ in
            color.set()

            let drawRect = CGRect(
                x: (imageSize.width - symbolImage.size.width) / 2,
                y: (imageSize.height - symbolImage.size.height) / 2,
                width: symbolImage.size.width,
                height: symbolImage.size.height
            )
            symbolImage.draw(in: drawRect)
        }

        return SKTexture(image: renderedImage)
    }

    // MARK: - Score Typography

    func makePrimaryScoreNode(_ meters: Int) -> SKNode {
        let scoreNode = SKNode()
        scoreNode.name = "gameOverScore"

        let scoreLabel = makeLabel(
            text: "\(meters)",
            fontName: configuration.primaryFontName,
            fontSize: 104,
            color: gameOverScoreColor
        )
        scoreLabel.name = "gameOverScoreNumber"
        scoreLabel.position = .zero
        scoreNode.addChild(scoreLabel)

        let metersLabel = makeLabel(
            text: "m",
            fontName: configuration.primaryFontName,
            fontSize: 32,
            color: gameOverScoreColor
        )
        metersLabel.name = "gameOverScoreMeters"
        metersLabel.horizontalAlignmentMode = .left
        metersLabel.position = CGPoint(x: scoreLabel.frame.maxX + 6, y: -28)
        scoreNode.addChild(metersLabel)

        return scoreNode
    }

    // MARK: - Try Again Button

    func makeTryAgainButton() -> SKSpriteNode {
        // The button uses the exact asset and the configured size so future art
        // tuning can happen from `GameConfiguration` without touching this UI.
        let buttonNode = SKSpriteNode(imageNamed: NomadAsset.tryAgainButton.rawValue)
        buttonNode.name = "gameOverRetryButton"
        buttonNode.position = CGPoint(x: 0, y: -178)
        buttonNode.size = configuration.gameOverTryAgainButtonSize
        buttonNode.zPosition = 2
        return buttonNode
    }

    // MARK: - Home Button

    func makeHomeButton() -> SKNode {
        let homeNode = SKNode()
        homeNode.name = "gameOverHomeButton"
        homeNode.position = CGPoint(x: 0, y: -252)
        homeNode.zPosition = 3

        let homeLabel = makeLabel(
            text: "Home",
            fontName: configuration.secondaryFontName,
            fontSize: 20,
            color: gameOverSecondaryTextColor
        )
        homeLabel.name = "gameOverHomeLabel"
        homeNode.addChild(homeLabel)

        let underlineY = homeLabel.frame.minY - 2
        let underlinePath = CGMutablePath()
        underlinePath.move(to: CGPoint(x: homeLabel.frame.minX, y: underlineY))
        underlinePath.addLine(to: CGPoint(x: homeLabel.frame.maxX, y: underlineY))

        let underlineNode = SKShapeNode(path: underlinePath)
        underlineNode.name = "gameOverHomeUnderline"
        underlineNode.strokeColor = gameOverSecondaryTextColor
        underlineNode.lineWidth = 1
        homeNode.addChild(underlineNode)

        return homeNode
    }

    // MARK: - Label Factory

    func makeLabel(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        color: SKColor
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        return label
    }

    // MARK: - Game Font Registration

    /// Registers the shared game typography before any SpriteKit label asks for
    /// the primary or secondary font by name.
    func registerGameFontsIfNeeded() {
        guard !Self.didRegisterGameFonts else { return }

        // MARK: Game Font Registration
        // Register the whole-game primary and secondary fonts before UI nodes
        // try to create labels with these typefaces.
        registerGameFontResource(named: configuration.primaryFontName, fileExtension: "ttf")
        registerGameFontResource(named: configuration.secondaryFontName, fileExtension: "ttf")
        Self.didRegisterGameFonts = true
    }

    /// Looks for a font either in the app bundle root or inside `Fonts/`, then
    /// registers it for the current process as a defensive runtime fallback.
    func registerGameFontResource(named name: String, fileExtension: String) {
        let directURL = Bundle.main.url(forResource: name, withExtension: fileExtension)
        let fontsFolderURL = Bundle.main.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "Fonts"
        )

        guard let fontURL = directURL ?? fontsFolderURL else { return }

        // UIAppFonts handles the normal app launch path. This registration is a
        // defensive fallback for the file-synced project folder layout.
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    // MARK: - Game Over Touch Handling

    func handleGameOverTouch(at location: CGPoint) {
        if isTouch(location, inside: gameOverRetryButtonNode, xInset: -18, yInset: -10) {
            setUpScene()
            return
        }

        if isTouch(location, inside: gameOverHomeButtonNode, xInset: -16, yInset: -10) {
            // FIXME: Navigate to the Home Menu once the Home Menu screen exists.
            return
        }
    }

    func isTouch(
        _ location: CGPoint,
        inside node: SKNode?,
        xInset: CGFloat,
        yInset: CGFloat
    ) -> Bool {
        guard let node else { return false }

        return node.calculateAccumulatedFrame()
            .insetBy(dx: xInset, dy: yInset)
            .contains(location)
    }

    // MARK: - Game Over Colors

    var gameOverTitleColor: SKColor {
        // Title color from the user's latest comparison palette.
        SKColor(hex: 0xE28B40)
    }

    var gameOverScoreColor: SKColor {
        // Score keeps the brighter orange so the distance remains the focal point.
        SKColor(hex: 0xF6A74C)
    }

    var gameOverSecondaryTextColor: SKColor {
        // Secondary accent is used for new-highscore and Home text.
        SKColor(hex: 0xF6A74C)
    }

    var gameOverHighScoreTextColor: SKColor {
        // Normal highscore label and value use the requested #E28B40 color.
        SKColor(hex: 0xE28B40)
    }

    var gameOverOverlayBrown: SKColor {
        // Overlay wash is the requested dark brown at 70% alpha in the dim node.
        SKColor(hex: 0x49270E)
    }
}

// MARK: - Score Result

private struct ScoreResult {
    // MARK: - Score Values

    let distanceMeters: Int
    let highScoreMeters: Int
    let isNewHighScore: Bool
}

// MARK: - Distance Score System

/// Stores score and highscore separately from the temporary preview updater.
/// The real distance counter can set meters directly without changing overlay UI.
private final class DistanceScoreSystem {

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

// MARK: - SpriteKit Color Bridge

private extension SKColor {

    // MARK: - Hex Initialization

    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    // MARK: - UIKit Conversion

    var uiColor: UIColor {
        self
    }
}
