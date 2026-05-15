//
//  ObstacleEntity.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import GameplayKit

class ObstacleEntity: GKEntity {
    let type: ObstacleType

    init(type: ObstacleType) {
        self.type = type
        super.init()

        // Di sini nanti bisa ditambahkan component behavior
        // Contoh: self.addComponent(ObstacleBehaviorComponent())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
