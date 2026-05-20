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
/// The player is drawn from the `PLAYER` asset, while the input, movement, and
/// launch systems only talk to this entity's node.
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
        playerNode.zPosition = RenderLayer.player
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
        guard let playerParent = node.parent,
              let vehicleParent = vehicle.node.parent,
              playerParent !== vehicleParent else {
            node.position = CGPoint(x: vehicle.node.position.x + rideOffset.dx, y: vehicle.node.position.y + rideOffset.dy)
            return
        }
        let targetPos = vehicleParent.convert(vehicle.node.position, to: playerParent)
        
        node.position = CGPoint(x: targetPos.x + rideOffset.dx, y: targetPos.y + rideOffset.dy)
    }

    // MARK: - Player Art

    private static func makePlayerNode(configuration: GameConfiguration) -> SKNode {
        let playerNode = SKSpriteNode(imageNamed: NomadAsset.player.rawValue)
        playerNode.size = configuration.playerSize

        return playerNode
    }
}
