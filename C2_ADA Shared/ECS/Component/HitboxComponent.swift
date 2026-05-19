//
//  HitboxComponent.swift
//  C2_ADA Shared
//
//  Created by Gemini CLI on 18/05/26.
//

import GameplayKit
import SpriteKit

/// Individual shape data for a multi-hitbox system.
struct HitboxShape {
    let size: CGSize
    let offset: CGPoint
    let angle: CGFloat
}

/// Defines one or more physical boundaries for collision detection.
final class HitboxComponent: GKComponent {

    // MARK: - Properties

    /// The list of shapes that make up this entity's total hitbox.
    let shapes: [HitboxShape]
    
    /// Optional shape nodes for visual debugging.
    private var debugNodes: [SKShapeNode] = []

    // MARK: - Initialization

    init(shapes: [HitboxShape]) {
        self.shapes = shapes
        super.init()
    }
    
    /// Convenience initializer for a single hitbox.
    init(size: CGSize, offset: CGPoint = .zero, angle: CGFloat = 0) {
        self.shapes = [HitboxShape(size: size, offset: offset, angle: angle)]
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Debugging

    func showDebugHitbox(in parent: SKNode, color: SKColor = .red) {
        // Remove old debug nodes
        debugNodes.forEach { $0.removeFromParent() }
        debugNodes.removeAll()
        
        for shapeData in shapes {
            let shape = SKShapeNode(rectOf: shapeData.size)
            shape.name = "debug_hitbox"
            shape.strokeColor = color
            shape.fillColor = color.withAlphaComponent(0.3)
            shape.position = shapeData.offset
            shape.zRotation = shapeData.angle
            shape.zPosition = 1000
            
            parent.addChild(shape)
            debugNodes.append(shape)
        }
    }
}
