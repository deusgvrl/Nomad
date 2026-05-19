//
//  VehicleEntity.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit
import Foundation

// MARK: - Vehicle Entity

/// The vehicle ECS entity controlled by the player's drag while riding.
///
/// The current visual uses the imported `CAR IDLE` asset. The movement systems
/// still treat it as a plain SpriteKit node, so future car variants can be
/// swapped from the asset enum without changing input logic.
final class VehicleEntity: GKEntity {

    // MARK: - SpriteKit Node

    let node: SKNode

    // MARK: - Initialization
    
    init(node: SKNode, movementComponent: MovementComponent? = nil) {
        self.node = node
        super.init()
        
        addComponent(NodeComponent(node: node))
        
        if let movement = movementComponent {
            addComponent(movement)
        }

        // Use custom hitbox values if the node is a VehicleNode
        if let vehicleNode = node as? VehicleNode {
            // MENGAMBIL: Array berisi banyak bentuk kotak tabrakan dari Enum VehicleType
            addComponent(HitboxComponent(shapes: vehicleNode.vehicleType.hitboxShapes))
        } else {
            // Fallback for generic nodes (tetap menggunakan satu kotak default)
            let hitboxWidth = node.frame.width * 0.7
            let hitboxHeight = node.frame.height * 0.4
            let hitboxOffset = CGPoint(x: 0, y: hitboxHeight / 2)
            addComponent(HitboxComponent(size: CGSize(width: hitboxWidth, height: hitboxHeight), offset: hitboxOffset))
        }
    }
    
    convenience init(configuration: GameConfiguration){
        
        let vehicleNode = Self.makeVehicleNode(configuration: configuration)
        vehicleNode.name = "vehicle"
        vehicleNode.zPosition = ZPosition.vehicle
        vehicleNode.position = configuration.currentVehiclePosition
        
        let steering = MovementComponent(
            position: configuration.currentVehiclePosition,
            screenSize: configuration.referenceScreenSize,
            vehicleSize: configuration.vehicleSize,
            movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
            movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
            dragSensitivity: configuration.dragSensitivity
        )
        self.init(node: vehicleNode, movementComponent: steering)
    }
    

//    init(configuration: GameConfiguration) {
//        let vehicleNode = Self.makeVehicleNode(configuration: configuration)
//        vehicleNode.name = "vehicle"
//        vehicleNode.zPosition = ZPosition.vehicle
//        vehicleNode.position = configuration.currentVehiclePosition
//        self.node = vehicleNode
//
//        super.init()
//
//        addComponent(NodeComponent(node: vehicleNode))
//        // Movement follows a shallow screen-space angle, clamped to the visible
//        // phone bounds from the centered SpriteKit scene.
//        addComponent(
//            MovementComponent(
//                position: configuration.currentVehiclePosition,
//                screenSize: configuration.referenceScreenSize,
//                vehicleSize: configuration.vehicleSize,
//                movementAxisAngleInDegrees: configuration.movementAxisAngleInDegrees,
//                movementAxisXOffsetBounds: configuration.movementAxisXOffsetBounds,
//                dragSensitivity: configuration.dragSensitivity
//            )
//        )
//    }

    // MARK: - Required Coder Initializer

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Positioning

    func setPosition(_ position: CGPoint) {
        node.position = component(ofType: MovementComponent.self)?.setPosition(position) ?? position
    }

    // MARK: - Vehicle Art

    /// Builds the current car sprite using the specialized VehicleNode class.
    ///
    /// PERBAIKAN: Sebelumnya ini menggunakan SKSpriteNode biasa dengan anchor point (0.5, 0.5).
    /// Sekarang menggunakan VehicleNode agar anchor point (0.5, 0.15) dan pengaturan hitbox
    /// konsisten antara mobil awal dan mobil yang di-spawn kemudian.
    private static func makeVehicleNode(configuration: GameConfiguration) -> SKNode {
        let vehicleNode = VehicleNode(type: .car)
        // Ukuran diambil dari konfigurasi game agar tetap fleksibel
        vehicleNode.size = configuration.vehicleSize
        return vehicleNode
    }
}
