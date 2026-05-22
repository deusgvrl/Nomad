//
//  ObstacleEntity.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import GameplayKit
import SpriteKit

class ObstacleEntity: GKEntity {
    let type: ObstacleType
    let node: SKNode
    
    init(type: ObstacleType, node: SKNode) {
        self.type = type
        self.node = node
        super.init()

        addComponent(NodeComponent(node: node))
        addComponent(HitboxComponent(shapes: type.hitboxShapes))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
