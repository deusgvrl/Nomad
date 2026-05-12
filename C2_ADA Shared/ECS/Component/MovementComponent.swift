//
//  MovementComponent.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import GameplayKit

class MovementComponent: GKComponent {
    var speed: CGFloat
    
    init(speed: CGFloat) {
        self.speed = speed
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
