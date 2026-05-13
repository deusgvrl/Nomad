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
/// The current visual is a lo-fi blue isometric block. It is intentionally built
/// in code so the movement backend can be tested before final vehicle assets are
/// ready.
final class VehicleEntity: GKEntity {

    // MARK: - SpriteKit Node

    let node: SKNode

    // MARK: - Initialization

    init(configuration: GameConfiguration) {
        let vehicleNode = Self.makeIsometricVehicleNode(configuration: configuration)
        vehicleNode.name = "vehicle"
        vehicleNode.zPosition = ZPosition.vehicle
        vehicleNode.position = configuration.currentVehiclePosition
        self.node = vehicleNode

        super.init()

        addComponent(NodeComponent(node: vehicleNode))
        // Movement uses the same road width data as the drawn road, so dragging
        // left/right keeps the vehicle inside the road borders from the mockup.
        addComponent(
            MovementComponent(
                position: configuration.currentVehiclePosition,
                roadStartCenterPosition: configuration.roadStartCenterPosition,
                roadAngleInDegrees: configuration.isometricViewAngleInDegrees,
                roadWidth: configuration.roadWidth,
                vehicleWidth: configuration.vehicleSize.width,
                dragSensitivity: configuration.dragSensitivity
            )
        )
    }

    // MARK: - Required Coder Initializer

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Positioning

    func setPosition(_ position: CGPoint) {
        node.position = component(ofType: MovementComponent.self)?.setPosition(position) ?? position
    }

    // MARK: - Placeholder Art

    /// Builds the current placeholder car block.
    ///
    /// Later, this method is the easiest swap point for `SKSpriteNode` assets like
    /// jeep, van, pickup, or monster truck variants.
    private static func makeIsometricVehicleNode(configuration: GameConfiguration) -> SKNode {
        let vehicleNode = SKNode()
        let size = configuration.vehicleSize
        let radians = Double(configuration.isometricViewAngleInDegrees) * Double.pi / 180
        let skew = size.height / CGFloat(tan(radians))
        let sideHeight = size.height * 0.32

        let nearLeft = CGPoint(x: -size.width / 2, y: -size.height / 2)
        let nearRight = CGPoint(x: size.width / 2, y: -size.height / 2)
        let farRight = CGPoint(x: size.width / 2 + skew, y: size.height / 2)
        let farLeft = CGPoint(x: -size.width / 2 + skew, y: size.height / 2)

        // The lower side gives the block some height, matching the lo-fi car shape.
        let sidePath = CGMutablePath()
        sidePath.move(to: nearLeft)
        sidePath.addLine(to: nearRight)
        sidePath.addLine(to: CGPoint(x: nearRight.x, y: nearRight.y - sideHeight))
        sidePath.addLine(to: CGPoint(x: nearLeft.x, y: nearLeft.y - sideHeight))
        sidePath.closeSubpath()

        let side = SKShapeNode(path: sidePath)
        side.fillColor = SKColor(red: 0.02, green: 0.46, blue: 0.86, alpha: 1.0)
        side.strokeColor = .clear
        side.lineWidth = 2
        vehicleNode.addChild(side)

        // The top plane uses the isometric angle so the block faces the road.
        let topPath = CGMutablePath()
        topPath.move(to: nearLeft)
        topPath.addLine(to: nearRight)
        topPath.addLine(to: farRight)
        topPath.addLine(to: farLeft)
        topPath.closeSubpath()

        let top = SKShapeNode(path: topPath)
        top.fillColor = SKColor(red: 0.24, green: 0.65, blue: 1.00, alpha: 1.0)
        top.strokeColor = .clear
        top.lineWidth = 0
        vehicleNode.addChild(top)

        // Temporary visual detail to suggest a vehicle rollbar.
        let rollbarPath = CGMutablePath()
        rollbarPath.move(to: CGPoint(x: -size.width * 0.24 + skew * 0.5, y: size.height * 0.05))
        rollbarPath.addLine(to: CGPoint(x: -size.width * 0.16 + skew * 0.5, y: size.height * 0.46))
        rollbarPath.addLine(to: CGPoint(x: size.width * 0.22 + skew * 0.5, y: size.height * 0.32))

        let rollbar = SKShapeNode(path: rollbarPath)
        rollbar.strokeColor = SKColor(red: 0.03, green: 0.30, blue: 0.67, alpha: 1.0)
        rollbar.lineWidth = 5
        rollbar.lineCap = .round
        vehicleNode.addChild(rollbar)

        return vehicleNode
    }
}
