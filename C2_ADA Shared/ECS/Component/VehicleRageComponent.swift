//
//  VehicleRageComponent.swift
//  C2_ADA Shared
//
//  Created by Gemini CLI on 20/05/26.
//

import GameplayKit
import SpriteKit

/// Komponen yang mengelola status rage kendaraan.
/// Menggunakan GKStateMachine untuk mengatur transisi dari tenang hingga melompat.
class VehicleRageComponent: GKComponent {
    
    /// Sinyal yang akan dipanggil saat kendaraan mencapai fase JumpState
    var onJumpRequested: (() -> Void)?
    
    /// Mesin status yang mengontrol logika kemarahan
    var stateMachine: GKStateMachine?
    
    /// Inisialisasi komponen dengan referensi ke node visual kendaraan
    init(node: VehicleNode) {
        super.init()
        
        // Membuat instance dari setiap status dan memasukkan node serta komponen ini
        let calmState = VehicleCalmState(node: node, component: self)
        let poppingState = VehiclePoppingState(node: node, component: self)
        let hittingState = VehicleHittingState(node: node, component: self)
        let jumpState = VehicleJumpState(node: node, component: self)
        
        // Memasukkan status-status tersebut ke dalam State Machine
        self.stateMachine = GKStateMachine(states: [
            calmState,
            poppingState,
            hittingState,
            jumpState
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Fungsi update yang harus dipanggil setiap frame agar timer di dalam state berjalan
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        stateMachine?.update(deltaTime: seconds)
    }
    
    /// Memulai siklus kemarahan (biasanya dipanggil saat pemain menempel/latch)
    func startRageCycle() {
        stateMachine?.enter(VehicleCalmState.self)
    }
    
    /// Menghentikan siklus kemarahan dan kembali ke kondisi tenang
    func resetRageCycle() {
        stateMachine?.enter(VehicleCalmState.self)
    }
}
