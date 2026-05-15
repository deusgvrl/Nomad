//
//  WallNode.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 15/05/26.
//

import Foundation
import SpriteKit




class WallNode: SKSpriteNode{
    let side: WallSide
    
    init(side: WallSide) {
        self.side = side
        let texture = SKTexture(imageNamed: side.imageName)
        
        //Atur ukuran Chunk
        let scale: CGFloat = 0.2
        let wallSize = CGSize(width: texture.size().width * scale, height: texture.size().height * scale)
        
        super.init(texture: texture, color: .clear, size: wallSize)
        
        // identifier
        self.name = "wall_\(side)"
        
        // Anchor point di tengah bawah
        self.anchorPoint = CGPoint(x: 0.5, y: 0.1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
