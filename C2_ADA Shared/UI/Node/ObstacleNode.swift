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
        
        // Gunakan faktor skala yang proporsional
        let scaleFactor: CGFloat = 2
        
        // Hitung ukuran berdasarkan rasio asli agar tidak "stretch"
        let textureSize = texture.size()
        let aspectRatio = textureSize.height / textureSize.width
        
        // Tentukan lebar berdasarkan tile, tinggi mengikuti rasio asli
        let targetWidth = IsometricHelper.tileWidth * scaleFactor
        let targetHeight = targetWidth * aspectRatio
        
        let tileSize = CGSize(width: targetWidth, height: targetHeight)

        super.init(texture: texture, color: .clear, size: tileSize)
        
        self.name = "obstacle"
        
        // Atur anchorPoint agar rintangan "duduk" pas di atas tile
        self.anchorPoint = CGPoint(x: 0.5, y: 0.15) 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
