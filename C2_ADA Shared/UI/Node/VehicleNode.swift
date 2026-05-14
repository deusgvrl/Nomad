//
//  VehicleNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 13/05/26.
//

import SpriteKit

enum VehicleType: String, CaseIterable{
    case car = "VEHICLE TEST"
}

class VehicleNode: SKSpriteNode {
    let vehicleType: VehicleType
    
    
    init(type: VehicleType) {
        self.vehicleType = type
        let texture = SKTexture(imageNamed: type.rawValue)
        
        let scale: CGFloat = 1.5
        
        let vehicleSize = CGSize(
            width: IsometricHelper.tileWidth * scale,
            height: IsometricHelper.tileHeight * scale
        )

        super.init(texture: texture, color: .clear, size: vehicleSize)
        
        self.name = "Vehicle"
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
