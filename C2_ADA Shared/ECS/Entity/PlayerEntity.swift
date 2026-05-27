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

    let node: PlayerNode


    // MARK: - Placement Tuning

    private let rideOffset: CGVector

    // MARK: - Initialization

    init(configuration: GameConfiguration) {
        self.rideOffset = configuration.playerRideOffset

        let playerNode = PlayerNode(configuration: configuration)
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
        var currentRiderOffset = rideOffset
        
        if let vehicleNode = vehicle.node as? VehicleNode {
            currentRiderOffset = vehicleNode.vehicleType.riderOffset
        }
        
        let playerCenterX = vehicle.node.position.x + currentRiderOffset.dx
        let playerCenterY = vehicle.node.position.y + currentRiderOffset.dy
        
        guard let playerParent = node.parent,
              let vehicleParent = vehicle.node.parent,
              playerParent !== vehicleParent else {
            node.position = CGPoint(x: playerCenterX, y: playerCenterY)
            return
        }
        
        let rawVehiclePos = CGPoint(x: playerCenterX, y: playerCenterY)
        let targetPos = vehicleParent.convert(rawVehiclePos, to: playerParent)
        
        node.position = targetPos
    }

    // MARK: - Visual Animation
    
    func playDeadVisual() {
        node.playDead()
    }
    
    func steerVisual(isLeft: Bool) {
        node.steer(isLeft: isLeft)
    }
    
    func idleVisual() {
        node.playIdle()
    }
    
    func playJumpVisual(duration: TimeInterval) {
        node.playJump()
        
        // MARK: Jump Visual Timing
        // Match the visual airborne timing to the lane movement duration so the
        // player does not return to normal size and appear to glide on the floor.
        let halfDuration = max(duration / 2, 0.05)

        let grow = SKAction.scale(to: 1.5, duration: halfDuration)
        grow.timingMode = .easeOut
        
        let shrink = SKAction.scale(to: 1.0, duration: halfDuration)
        shrink.timingMode = .easeIn
        
        let sequence = SKAction.sequence([grow, shrink])
        node.run(sequence)
    }
    
    func cancelJumpVisual() {
        node.removeAllActions()
        node.playIdle()
        
        let resetScale = SKAction.scale(to: 1.0, duration: 0.15)
        resetScale.timingMode = .easeOut
        node.run(resetScale)
    }
    
    
}
