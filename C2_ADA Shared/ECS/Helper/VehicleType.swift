//
//  CarType.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 22/05/26.
//

import Foundation
import SwiftUI
import SpriteKit

enum VehicleType: String, CaseIterable {
    case car = "CAR"
    case truck = "TRUCK"
    case bus = "BUS"
    
    // Prefix untuk mencari aset (contoh: "CAR" -> "CAR_IDLE")
    var prefix: String {
        return self.rawValue
    }
    
    // Nama aset untuk kondisi tenang/diam
    var idleAssetName: String {
        return "\(prefix)_IDLE"
    }
    
    // Daftar nama aset untuk animasi peringatan (Notice/Popping)
    // Menyesuaikan jumlah frame: CAR (3), TRUCK (2)
    var noticeAssetNames: [String] {
        return (1...3).map { "\(prefix)_NOTICE_\($0)" } //pakai map dan closure
    }
    
    // Daftar nama aset untuk animasi marah (Rage/Hitting)
    var rageAssetNames: [String] {
        return (1...3).map { "\(prefix)_RAGE_\($0)" }
    }
    
    // Ukuran skala relatif terhadap tile isometric
    var scaleFactor: CGFloat {
        switch self {
        case .car: return 2
        case .truck: return 2.6 // Truk dibuat sedikit lebih besar
        case .bus: return 2.6
        }
    }
    
    // Pengaturan Hitbox unik untuk tiap kendaraan (Perspektif Isometric)
    var hitboxShapes: [HitboxShape] {
        switch self {
        case .car:
            return [
                // Bagian Depan (Hood)
                HitboxShape(size: CGSize(width: 44, height: 57), offset: CGPoint(x: 5, y: 31),angle: -0.5),
                // Bagian Belakang (Body)
                HitboxShape(size: CGSize(width: 43, height: 35), offset: CGPoint(x: -13, y: 17),angle: -0.3),
                HitboxShape(size: CGSize(width: 35, height: 35), offset: CGPoint(x: 12, y: 48),angle: -0.3)
            ]
        case .truck:
            return [
                // Hitbox Truk yang lebih besar
                // Bagian Depan
                HitboxShape(size: CGSize(width: 70, height: 73), offset: CGPoint(x: 3, y: 40), angle: -0.47),
                // Bagian Belakang (Lebih panjang/lebar)
                HitboxShape(size: CGSize(width: 45, height: 50), offset: CGPoint(x: -20, y: 30), angle: -0.43),
                HitboxShape(size: CGSize(width: 35, height: 35), offset: CGPoint(x: 10, y: 63),angle: -0.3)
            ]
        case .bus:
            return [
                // Hitbox Truk yang lebih besar
                // Bagian Depan
                HitboxShape(size: CGSize(width: 50, height: 55), offset: CGPoint(x: 0, y: 25), angle: -0.47),
                // Bagian Belakang (Lebih panjang/lebar)
                HitboxShape(size: CGSize(width: 45, height: 40), offset: CGPoint(x: -10, y: 12), angle: -0.3),
                HitboxShape(size: CGSize(width: 35, height: 70), offset: CGPoint(x: 0, y: 52),angle: -0.5),
                HitboxShape(size: CGSize(width: 35, height: 36), offset: CGPoint(x: 15, y: 63),angle: 0.1)
            ]
            
        }
    }
    
    var riderOffset: CGVector {
        switch self {
        case .car:
            return CGVector(dx: -15, dy: 20)
        case .truck:
            return CGVector(dx: -17.5, dy: 50)
        case .bus:
            return CGVector(dx: -5, dy: 65)
        }
    }
    
    var lassoOffset: CGVector {
        switch self {
        case .car:
            return CGVector(dx: 0, dy: 30)
        case .truck:
            return CGVector(dx: 0, dy: 35)
        case .bus:
            return CGVector(dx: 0, dy: 30)
        }
    }
}

// MARK: - SwiftUI Preview (Debug Only)
#if DEBUG
import SwiftUI
import SpriteKit

/// A custom scene solely for visualizing offsets in the Xcode Canvas.
class VehicleDebugScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.78, green: 0.58, blue: 0.36, alpha: 1.0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let types: [VehicleType] = [.car, .truck, .bus]
        let spacing: CGFloat = 220 // Vertical distance between vehicles
        let startY = CGFloat(types.count - 1) * spacing / 2.0
        
        for (index, type) in types.enumerated() {
            // Arrange vertically (top to bottom)
            let yPos = startY - CGFloat(index) * spacing
            let basePosition = CGPoint(x: 0, y: yPos)
            
            // 1. Draw the Vehicle
            let vehicle = VehicleNode(type: type)
            vehicle.position = basePosition
            vehicle.zPosition = 10
            addChild(vehicle)
            
            // 2. Draw the Lasso (Reticle)
            let lasso = SKSpriteNode(imageNamed: NomadAsset.reticle.rawValue)
            // Use the lassoOffset you wrote in VehicleType!
            lasso.position = CGPoint(
                x: basePosition.x + type.lassoOffset.dx,
                y: basePosition.y + type.lassoOffset.dy
            )
            // Size it just like GameScene does
            let lassoDiameter = GameConfiguration.standard.latchDistance * 2.2
            lasso.size = CGSize(width: lassoDiameter, height: lassoDiameter)
            lasso.zPosition = 20
            lasso.alpha = 0.8 // Slightly transparent so you can see the car under it
            addChild(lasso)
            
            // 3. Draw a Red Dot for the Player Rider position
            // (Using a dot instead of the whole player sprite makes it easier to see the exact pixel center)
            let playerDot = SKShapeNode(circleOfRadius: 4)
            playerDot.fillColor = .red
            playerDot.strokeColor = .white
            // Use the riderOffset you wrote in VehicleType!
            playerDot.position = CGPoint(
                x: basePosition.x + type.riderOffset.dx,
                y: basePosition.y + type.riderOffset.dy
            )
            playerDot.zPosition = 30
            addChild(playerDot)
        }
    }
}

// This macro tells Xcode to render the scene right here in the editor canvas!
#Preview {
    // 1. We use the EXACT size your game runs at (iPhone 17 Pro reference)
    let size = GameConfiguration.standard.referenceScreenSize
    let scene = VehicleDebugScene(size: size)
    
    // 2. We use aspectFill so it scales properly in the canvas just like the real game
    scene.scaleMode = .aspectFill
    return SpriteView(scene: scene)
        .ignoresSafeArea()
}
#endif


