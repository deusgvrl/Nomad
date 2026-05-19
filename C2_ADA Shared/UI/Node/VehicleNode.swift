//
//  VehicleNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 13/05/26.
//

import SpriteKit

enum VehicleType: String, CaseIterable{
    case car = "CAR IDLE"

    /// Returns a list of hitbox shapes for each vehicle type.
    var hitboxShapes: [HitboxShape] {
        switch self {
        case .car:
            return [
                // 1. Bagian Depan (Hood)
                HitboxShape(size: CGSize(width: 45, height: 65), offset: CGPoint(x: 5, y: 38), angle: -0.5),
                // 2. Bagian Kabin/Belakang (Body)
                HitboxShape(size: CGSize(width: 50, height: 40), offset: CGPoint(x: -15, y: 20), angle: -0.3)
            ]
        }
    }
}


class VehicleNode: SKSpriteNode {
    let vehicleType: VehicleType
    
    
    init(type: VehicleType) {
        self.vehicleType = type
        let texture = SKTexture(imageNamed: type.rawValue)

        // Gunakan satu faktor skala agar proporsional
        let scaleFactor: CGFloat = 2.3
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
