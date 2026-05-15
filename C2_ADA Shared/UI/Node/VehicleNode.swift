//
//  VehicleNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 13/05/26.
//

import SpriteKit

enum VehicleType: String, CaseIterable{
    case car = "CAR IDLE"
}

class VehicleNode: SKSpriteNode {
    let vehicleType: VehicleType
    
    
    init(type: VehicleType) {
        self.vehicleType = type
        let texture = SKTexture(imageNamed: type.rawValue)

        // Gunakan satu faktor skala agar proporsional
        let scaleFactor: CGFloat = 1.5
        // Hitung ukuran berdasarkan rasio asli gambar agar tidak "gepeng"
        let textureSize = texture.size()
        let aspectRatio = textureSize.height / textureSize.width

        // Tentukan lebar berdasarkan tile, lalu tinggi mengikuti rasio asli
        let targetWidth = IsometricHelper.tileWidth * scaleFactor
        let targetHeight = targetWidth * aspectRatio

        let vehicleSize = CGSize(width: targetWidth, height: targetHeight)

        super.init(texture: texture, color: .clear, size: vehicleSize)

        self.name = "vehicle"

        // Anchor point disesuaikan agar mobil "menempel" di atas tile
        self.anchorPoint = CGPoint(x: 0.5, y: 0.15)
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
