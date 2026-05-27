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

    // TEMPLATE PARTIKEL: Muat dari file HANYA SATU KALI untuk menghemat memori dan CPU
    private static let particleTemplate = SKEmitterNode(fileNamed: "VehicleParticle.sks")
    private static let crashSmokeTemplate = SKEmitterNode(fileNamed: "CrashSmoke.sks")
    
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
        
        // Setelah self.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        setupParticles()
    }
    
    // MARK: - Particles Setup
    
    private func setupParticles() {
        for offset in vehicleType.backWheelOffsets {
            // Gunakan .copy() dari template, ini JAUH lebih cepat daripada membaca file .sks berulang kali
            guard let template = VehicleNode.particleTemplate,
                  let emitter = template.copy() as? SKEmitterNode else {
                print("Failed to copy VehicleParticle from template")
                continue
            }
            
            emitter.position = offset
            
            emitter.zPosition = -1
            
            emitter.name = "wheelParticle"
            
            // Atur ukuran partikel berdasarkan jenis kendaraan
            emitter.setScale(vehicleType.particleScale)
            
            // Atur speed particle menggunakan properti fisika internal partikel
            let speedMultiplier = vehicleType.particleSpeed
            
            // Mengubah seberapa cepat partikel bergerak
            emitter.particleSpeed = emitter.particleSpeed * speedMultiplier
            
            // Mengubah seberapa lama partikel hidup (jika geraknya pelan, umurnya harus lebih lama agar jarak tempuhnya sama)
            emitter.particleLifetime = emitter.particleLifetime / speedMultiplier
            
            // Mengubah seberapa sering partikel muncul
            emitter.particleBirthRate = emitter.particleBirthRate * speedMultiplier
            
            addChild(emitter)
        }
    }
    
    // MARK: - Crash Effects

    func playCrashSmoke() {
        guard let template = VehicleNode.crashSmokeTemplate,
              let smoke = template.copy() as? SKEmitterNode else {
            return
        }

        // Posisikan sesuai titik tabrakan, atau di tengah jika tidak diberikan
        smoke.position = CGPoint(x: 0, y: 40)
        smoke.zPosition = 9999 // Tepat di atas segalanya
        smoke.setScale(0.3)
        
        addChild(smoke)

        // Asap hilang setelah 3 detik
        let wait = SKAction.wait(forDuration: 3.0)
        let remove = SKAction.removeFromParent()
        smoke.run(SKAction.sequence([wait, remove]))
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
