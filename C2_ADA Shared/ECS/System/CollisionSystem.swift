//
//  CollisionSystem.swift
//  C2_ADA Shared
//
//  Created by Gemini CLI on 18/05/26.
//

import CoreGraphics
import GameplayKit
import SpriteKit

/// System responsible for detecting collisions between entities.
final class CollisionSystem {

    // MARK: - Collision Detection

    /// Checks if a vehicle collides with any obstacles. Supports multi-shape hitboxes.
    func checkCollision(vehicle: VehicleEntity, with obstacles: [ObstacleEntity]) -> ObstacleEntity? {
        guard let vehicleHitbox = vehicle.component(ofType: HitboxComponent.self),
              let vehicleParent = vehicle.node.parent else {
            return nil
        }

        // Iterate through all shapes of the vehicle
        for vehicleShape in vehicleHitbox.shapes {
            let vehicleVertices = getVertices(for: vehicle.node, shape: vehicleShape, relativeTo: vehicleParent)

            for obstacle in obstacles {
                guard let obstacleHitbox = obstacle.component(ofType: HitboxComponent.self),
                      let _ = obstacle.node.parent else {
                    continue
                }

                // Iterate through all shapes of the obstacle
                for obstacleShape in obstacleHitbox.shapes {
                    let obstacleVertices = getVertices(for: obstacle.node, shape: obstacleShape, relativeTo: vehicleParent)

                    if polygonsIntersect(p1: vehicleVertices, p2: obstacleVertices) {
                        return obstacle
                    }
                }
            }
        }

        return nil
    }

    /// Checks collision between vehicles using SAT and multi-shape support.
    func checkVehicleCollision(playerVehicle: VehicleEntity, with otherVehicles: [VehicleEntity]) -> VehicleEntity? {
        guard let playerHitbox = playerVehicle.component(ofType: HitboxComponent.self),
              let playerParent = playerVehicle.node.parent else {
            return nil
        }
        
        for playerShape in playerHitbox.shapes {
            let playerVertices = getVertices(for: playerVehicle.node, shape: playerShape, relativeTo: playerParent)

            for other in otherVehicles {
                guard other !== playerVehicle else { continue }
                
                guard let otherHitbox = other.component(ofType: HitboxComponent.self),
                    other.node.parent != nil else {
                    continue
                }

                for otherShape in otherHitbox.shapes {
                    let otherVertices = getVertices(for: other.node, shape: otherShape, relativeTo: playerParent)

                    if polygonsIntersect(p1: playerVertices, p2: otherVertices) {
                        return other
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Vertex Calculation

    private func getVertices(for node: SKNode, shape: HitboxShape, relativeTo targetParent: SKNode) -> [CGPoint] {
        let w = shape.size.width / 2
        let h = shape.size.height / 2
        
        let corners = [
            CGPoint(x: -w, y: -h),
            CGPoint(x: w, y: -h),
            CGPoint(x: w, y: h),
            CGPoint(x: -w, y: h)
        ]
        
        var transform = CGAffineTransform(translationX: shape.offset.x, y: shape.offset.y)
        transform = transform.rotated(by: shape.angle)
        
        return corners.map { pt in
            let localPt = pt.applying(transform)
            return targetParent.convert(localPt, from: node)
        }
    }

    // MARK: - SAT Logic

    private func polygonsIntersect(p1: [CGPoint], p2: [CGPoint]) -> Bool {
        let edges = getEdges(for: p1) + getEdges(for: p2)
        for edge in edges {
            let axis = CGPoint(x: -edge.y, y: edge.x)
            let range1 = project(points: p1, onto: axis)
            let range2 = project(points: p2, onto: axis)
            if range1.max < range2.min || range2.max < range1.min {
                return false
            }
        }
        return true
    }

    private func getEdges(for points: [CGPoint]) -> [CGPoint] {
        var edges: [CGPoint] = []
        for i in 0..<points.count {
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            edges.append(CGPoint(x: p2.x - p1.x, y: p2.y - p1.y))
        }
        return edges
    }

    private func project(points: [CGPoint], onto axis: CGPoint) -> (min: CGFloat, max: CGFloat) {
        var min = CGFloat.infinity
        var max = -CGFloat.infinity
        for p in points {
            let dot = p.x * axis.x + p.y * axis.y
            if dot < min { min = dot }
            if dot > max { max = dot }
        }
        return (min, max)
    }
}
