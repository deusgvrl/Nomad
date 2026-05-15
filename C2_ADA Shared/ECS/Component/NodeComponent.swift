//
//  NodeComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit

// MARK: - Node Component

/// Wraps an `SKNode` so a GameplayKit entity can own a SpriteKit visual node.
///
/// ECS idea: entities hold components; SpriteKit still needs a node for drawing.
/// This component is the bridge between those two worlds.
final class NodeComponent: GKComponent {

    // MARK: - SpriteKit Node

    let node: SKNode

    // MARK: - Initialization

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
