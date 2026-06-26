//
//  FloorNode.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 11/05/26.
//

import SpriteKit

class FloorNode: SKSpriteNode {
    let row: Int
    let col: Int
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
        
        //Setup texture
        let texture = SKTexture(imageNamed: "Floor")
        let tileSize  = CGSize(width: texture.size().width + 2.0,
                               height: texture.size().height + 2.0)
        super.init(texture: texture,color: .clear, size: tileSize)
        
        // Set Posisi Menggunakan IsometricHelper
        self.position = IsometricHelper.getScreenPosition(row: row, col: col)
        self.zPosition = IsometricHelper.getTileRenderLayer(row: row, col: col)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
