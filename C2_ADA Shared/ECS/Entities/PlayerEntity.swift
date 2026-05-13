//
//  PlayerEntity.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit

// MARK: - Player Entity

/// The player ECS entity.
///
/// Right now the player is represented by a red placeholder circle. Later, this
/// entity can swap that node for real player sprites without changing the input,
/// movement, or launch systems.
final class PlayerEntity: GKEntity {

    // MARK: - SpriteKit Node

    let node: SKNode

    // MARK: - Placement Tuning

    private let rideOffset: CGVector

    // MARK: - Initialization

    init(configuration: GameConfiguration) {
        self.rideOffset = configuration.playerRideOffset

        let playerNode = Self.makePlayerNode(configuration: configuration)
        playerNode.name = "player"
        playerNode.zPosition = ZPosition.player
        self.node = playerNode

        super.init()

        addComponent(NodeComponent(node: playerNode))
        addComponent(InputIntentComponent())
        addComponent(RideAttachmentComponent())
        addComponent(LaunchComponent())
    }

    // MARK: - Required Coder Initializer

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Riding State

    func attach(to vehicle: VehicleEntity) {
        component(ofType: RideAttachmentComponent.self)?.attach(to: vehicle)
        component(ofType: LaunchComponent.self)?.reset()
        place(on: vehicle)
    }

    // MARK: - Input State

    func recordInput(_ inputPhase: InputPhase) {
        component(ofType: InputIntentComponent.self)?.updatePhase(inputPhase)
    }

    // MARK: - Detach

    func detachFromVehicle() {
        component(ofType: RideAttachmentComponent.self)?.detach()
    }

    // MARK: - Positioning

    /// Places the player marker on top of the current vehicle.
    ///
    /// The offset is named in `GameConfiguration` so asset placement can be tuned
    /// later when the real player and vehicle sprites arrive.
    func place(on vehicle: VehicleEntity) {
        node.position = CGPoint(
            x: vehicle.node.position.x + rideOffset.dx,
            y: vehicle.node.position.y + rideOffset.dy
        )
    }

    // MARK: - Placeholder Art

    private static func makePlayerNode(configuration: GameConfiguration) -> SKNode {
        let playerNode = SKNode()
        let size = configuration.playerSize

        let marker = SKShapeNode(ellipseOf: size)
        marker.fillColor = SKColor(red: 0.68, green: 0.25, blue: 0.22, alpha: 1.0)
        marker.strokeColor = SKColor.black.withAlphaComponent(0.12)
        marker.lineWidth = 1
        playerNode.addChild(marker)

        return playerNode
    }
}
