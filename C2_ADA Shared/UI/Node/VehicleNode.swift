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

    // Simpan tekstur asli agar mudah dikembalikan
    private let idleTexture: SKTexture

    init(type: VehicleType) {
        self.vehicleType = type
        self.idleTexture = SKTexture(imageNamed: type.rawValue)

        // Gunakan satu faktor skala agar proporsional
        let scaleFactor: CGFloat = 2.3
        // Hitung ukuran berdasarkan rasio asli gambar agar tidak "gepeng"
        let textureSize = idleTexture.size()
        let aspectRatio = textureSize.height / textureSize.width

        // Tentukan lebar berdasarkan tile, lalu tinggi mengikuti rasio asli
        let targetWidth = IsometricHelper.tileWidth * scaleFactor
        let targetHeight = targetWidth * aspectRatio

        let vehicleSize = CGSize(width: targetWidth, height: targetHeight)

        super.init(texture: idleTexture, color: .clear, size: vehicleSize)

        self.name = "vehicle"

        // Anchor point disesuaikan agar mobil "menempel" di atas tile
        self.anchorPoint = CGPoint(x: 0.5, y: 0.15)
    }


    // MARK: - Rage Animations

    /// Mengembalikan kendaraan ke kondisi Idle
    func resetToCalm() {
        self.removeAllActions() // Hentikan animasi jika ada
        self.texture = idleTexture
    }

    /// Menampilkan peringatan (Popping)
    func playPoppingAnimation() {
        self.removeAllActions()
        
        let noticeTextures = [
            SKTexture(imageNamed: "notice1"),
            SKTexture(imageNamed: "notice2"),
            SKTexture(imageNamed: "notice3")
        ]
        
        // Animasi pergantian frame setiap 0.5 detik
        let animateAction = SKAction.animate(with: noticeTextures, timePerFrame: 0.6)
    
        self.run(animateAction)
    }

    /// Menjalankan animasi marah/memukul berulang-ulang
    func playHittingAnimation() {
        self.removeAllActions()

        let rageTextures = [
            SKTexture(imageNamed: "rage1"),
            SKTexture(imageNamed: "rage2"),
            SKTexture(imageNamed: "rage3")
        ]

        // Animasi pergantian frame setiap 0.1 detik
        let animateAction = SKAction.animate(with: rageTextures, timePerFrame: 0.1)
        let repeatAction = SKAction.repeatForever(animateAction)

        self.run(repeatAction)
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
