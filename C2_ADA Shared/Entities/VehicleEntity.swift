//
//  VehicleEntity.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit
import Foundation

final class VehicleEntity: GKEntity {

    let node: SKNode

    init(configuration: GameConfiguration) {
        let vehicleNode = Self.makeIsometricVehicleNode(configuration: configuration)
        vehicleNode.name = "vehicle"
        vehicleNode.zPosition = ZPosition.vehicle
        vehicleNode.position = configuration.rideAnchorPosition
        self.node = vehicleNode

        super.init()

        addComponent(NodeComponent(node: vehicleNode))
        addComponent(
            MovementComponent(
                xPosition: configuration.currentVehiclePosition.x,
                xBounds: configuration.vehicleXBounds,
                dragSensitivity: configuration.dragSensitivity
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPosition(_ position: CGPoint) {
        node.position = position
        _ = component(ofType: MovementComponent.self)?.setXPosition(position.x)
    }

    func setXPosition(_ xPosition: CGFloat) {
        let clampedXPosition = component(ofType: MovementComponent.self)?.setXPosition(xPosition) ?? xPosition
        node.position = CGPoint(x: clampedXPosition, y: node.position.y)
    }

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

        let sidePath = CGMutablePath()
        sidePath.move(to: nearLeft)
        sidePath.addLine(to: nearRight)
        sidePath.addLine(to: CGPoint(x: nearRight.x, y: nearRight.y - sideHeight))
        sidePath.addLine(to: CGPoint(x: nearLeft.x, y: nearLeft.y - sideHeight))
        sidePath.closeSubpath()

        let side = SKShapeNode(path: sidePath)
        side.fillColor = SKColor(red: 0.16, green: 0.17, blue: 0.17, alpha: 1.0)
        side.strokeColor = .black
        side.lineWidth = 2
        vehicleNode.addChild(side)

        let topPath = CGMutablePath()
        topPath.move(to: nearLeft)
        topPath.addLine(to: nearRight)
        topPath.addLine(to: farRight)
        topPath.addLine(to: farLeft)
        topPath.closeSubpath()

        let top = SKShapeNode(path: topPath)
        top.fillColor = SKColor(red: 0.28, green: 0.30, blue: 0.29, alpha: 1.0)
        top.strokeColor = .black
        top.lineWidth = 3
        vehicleNode.addChild(top)

        let rollbarPath = CGMutablePath()
        rollbarPath.move(to: CGPoint(x: -size.width * 0.24 + skew * 0.5, y: size.height * 0.05))
        rollbarPath.addLine(to: CGPoint(x: -size.width * 0.16 + skew * 0.5, y: size.height * 0.46))
        rollbarPath.addLine(to: CGPoint(x: size.width * 0.22 + skew * 0.5, y: size.height * 0.32))

        let rollbar = SKShapeNode(path: rollbarPath)
        rollbar.strokeColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        rollbar.lineWidth = 5
        rollbar.lineCap = .round
        vehicleNode.addChild(rollbar)

        return vehicleNode
    }
}
