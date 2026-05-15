//
//  WallEntity.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 15/05/26.
//

import GameplayKit

class WallEntity: GKEntity{
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
