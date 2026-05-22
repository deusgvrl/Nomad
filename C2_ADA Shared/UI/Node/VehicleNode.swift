//
//  VehicleNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 13/05/26.
//

import SpriteKit

class VehicleNode: SKSpriteNode {
    let vehicleType: VehicleType

    // Simpan tekstur asli agar mudah dikembalikan
    private let idleTexture: SKTexture

    init(type: VehicleType) {
        self.vehicleType = type
        self.idleTexture = SKTexture(imageNamed: type.idleAssetName)

        // Hitung ukuran berdasarkan rasio asli gambar & faktor skala tipe mobil
        let textureSize = idleTexture.size()
        let aspectRatio = textureSize.height / textureSize.width
        let targetWidth = IsometricHelper.tileWidth * type.scaleFactor
        let targetHeight = targetWidth * aspectRatio

        super.init(texture: idleTexture, color: .clear, size: CGSize(width: targetWidth, height: targetHeight))

        self.name = "vehicle"

        // Anchor point disesuaikan agar mobil "menempel" di atas tile (0.15 = dasar roda)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.15)
    }


    // MARK: - Rage Animations

    /// Mengembalikan kendaraan ke kondisi Idle
    func resetToCalm() {
        self.removeAllActions()
        self.texture = idleTexture
    }

    /// Menampilkan animasi peringatan (Popping)
    func playPoppingAnimation() {
        self.removeAllActions()
        
        let noticeTextures = vehicleType.noticeAssetNames.map { SKTexture(imageNamed: $0) }
        
        // Durasi disesuaikan agar transisi halus sesuai jumlah frame
        let timePerFrame = 0.6
        let animateAction = SKAction.animate(with: noticeTextures, timePerFrame: timePerFrame)
    
        self.run(animateAction)
    }

    /// Menjalankan animasi marah (Hitting)
    func playHittingAnimation() {
        self.removeAllActions()

        let rageTextures = vehicleType.rageAssetNames.map { SKTexture(imageNamed: $0) }

        let animateAction = SKAction.animate(with: rageTextures, timePerFrame: 0.1)
        let repeatAction = SKAction.repeatForever(animateAction)

        self.run(repeatAction)
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
