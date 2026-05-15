//
//  ObstacleNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import SpriteKit

class ObstacleNode: SKSpriteNode {
    let obstacleType: ObstacleType
    
    init(type: ObstacleType) {
        self.obstacleType = type
        let texture = SKTexture(imageNamed: type.rawValue)
        
        // Gunakan ukuran tile dari IsometricHelper agar pas
        let scale: CGFloat = 1.5

        let tileSize = CGSize(
            width: IsometricHelper.tileWidth * scale,
            height: IsometricHelper.tileHeight * scale
        )

        super.init(texture: texture, color: .clear, size: tileSize)
        
        self.name = "obstacle"
        
        // Atur anchorPoint ke tengah bawah agar rintangan "berdiri" tepat di atas tile
        self.anchorPoint = CGPoint(x: 0.5, y: 0.1) 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
