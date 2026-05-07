//
//  PlayerEntity.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit

final class PlayerEntity: GKEntity {

    let node: SKNode

    private let rideOffset: CGVector

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attach(to vehicle: VehicleEntity) {
        component(ofType: RideAttachmentComponent.self)?.attach(to: vehicle)
        component(ofType: LaunchComponent.self)?.reset()
        place(on: vehicle)
    }

    func recordInput(_ inputPhase: InputPhase) {
        component(ofType: InputIntentComponent.self)?.updatePhase(inputPhase)
    }

    func detachFromVehicle() {
        component(ofType: RideAttachmentComponent.self)?.detach()
    }

    func place(on vehicle: VehicleEntity) {
        node.position = CGPoint(
            x: vehicle.node.position.x + rideOffset.dx,
            y: vehicle.node.position.y + rideOffset.dy
        )
    }

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
