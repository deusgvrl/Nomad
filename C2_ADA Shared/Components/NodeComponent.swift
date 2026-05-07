//
//  NodeComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit
import SpriteKit

final class NodeComponent: GKComponent {

    let node: SKNode

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
