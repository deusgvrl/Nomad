//
//  CarType.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 22/05/26.
//

import Foundation

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
    
    // Posisi ban belakang relatif terhadap anchor point (0.5, 0.15)
    var backWheelOffsets: [CGPoint] {
        switch self {
        case .car:
            return [
                CGPoint(x: -30, y: 5),   // Ban belakang kiri
                CGPoint(x: 9, y: -5)   // Ban belakang kanan
            ]

        case .truck:
            return [
                CGPoint(x: -45, y: 3),
                CGPoint(x: 12, y: -8)
            ]

        case .bus:
            return [
                CGPoint(x: -30, y: -5),
                CGPoint(x: 5, y: -10)
            ]
        }
    }
    
    // Skala partikel asap berdasarkan jenis kendaraan
    var particleScale: CGFloat {
        switch self {
        case .car: return 0.18
        case .truck: return 0.32
        case .bus: return 0.15
        }
    }
    
    var particleSpeed: CGFloat {
        switch self {
        case .car: return 1
        case .truck: return 0.2
        case .bus: return 1 
        }
    }
}
