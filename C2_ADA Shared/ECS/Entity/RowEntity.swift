//
//  RowEntity.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 13/05/26.
//

import GameplayKit

class RowEntity: GKEntity {
    
    init(speed: CGFloat) {
        super.init()
        
        // Memasukkan MovementComponent langsung di dalam Entity
        let movementComponent = MovementComponent(speed: speed)
        self.addComponent(movementComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
