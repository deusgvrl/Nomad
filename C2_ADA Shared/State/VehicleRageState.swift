//
//  RageState.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 14/05/26.
//

import GameplayKit

// MARK: - POPPING STATE (2)
/// Transisi pertama , kendaraan mulai marah  (2 detik)
class VehiclePoppingState: GKState {
    private var elapsedTime: TimeInterval = 0
    private let duration: TimeInterval = 2.0 // 5s - 3s
    
    // Referensi ke node visual kendaraan
    weak var node: VehicleNode?
    // Referensi ke komponen yang memegang callback
    weak var component: VehicleRageComponent?
    
    init(node: VehicleNode, component: VehicleRageComponent) {
        self.node = node
        self.component = component
        super.init()
    }
    
    override func didEnter(from previousState: GKState?){
        elapsedTime = 0.0
        // TODO: - ADD POPPING OUT ASSET
        
        // Menjalankan animasi peringatan pada node
        node?.playPoppingAnimation()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds
        if elapsedTime >= duration {
            // Enter Hitting State if Duration exceeds the required time.
            self.stateMachine?.enter(VehicleHittingState.self)
        }
    }
    
    override func isValidNextState (_ stateClass: AnyClass) -> Bool {
        // Mengizinkan pindah ke Hitting atau kembali ke Calm (jika player jump)
        return stateClass == VehicleHittingState.self || stateClass == VehicleCalmState.self
    }
}

// MARK: - HITTING STATE (3)
/// Fase setelah Popping, animasi hitting (2 detik)
class VehicleHittingState: GKState {
    private var elapsedTime: TimeInterval = 0
    private let duration: TimeInterval = 2.0 // 5s - 3s
    
    // Referensi ke node visual kendaraan
    weak var node: VehicleNode?
    // Referensi ke komponen yang memegang callback
    weak var component: VehicleRageComponent?
    
    init(node: VehicleNode, component: VehicleRageComponent) {
        self.node = node
        self.component = component
        super.init()
    }
    
    override func didEnter(from previousState: GKState?){
        elapsedTime = 0.0
        // TODO: - ADD HITTING ASSET
        
        // Menjalankan animasi memukul/marah pada node
        node?.playHittingAnimation()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds
        if elapsedTime >= duration {
            // Enter Hitting State if Duration exceeds the required time.
            self.stateMachine?.enter(VehicleJumpState.self)
        }
    }
    
    override func isValidNextState (_ stateClass: AnyClass) -> Bool {
        // Mengizinkan pindah ke Jump atau kembali ke Calm
        return stateClass == VehicleJumpState.self || stateClass == VehicleCalmState.self
    }
}

// MARK: - JUMP STATE
/// Fase akhir setelah hitting state , player akan melompat otomatis.
class VehicleJumpState: GKState {
    // Referensi ke node visual kendaraan
    weak var node: VehicleNode?
    // Referensi ke komponen yang memegang callback
    weak var component: VehicleRageComponent?
    
    init(node: VehicleNode, component: VehicleRageComponent) {
        self.node = node
        self.component = component
        super.init()
    }
    
    override func didEnter(from previousState: GKState?){
        super.didEnter(from: previousState)
        
        // TODO: - ADD JUMPING SYSTEM HERE.
        
        // Memanggil sinyal lompat paksa ke GameScene melalui komponen
        component?.onJumpRequested?()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        // PERBAIKAN: Harus mengizinkan transisi kembali ke Calm agar mobil tidak marah terus
        return stateClass == VehicleCalmState.self
    }
}


// MARK: - CALM STATE (1)
/// Kondisi awal dimana kendaraan berada dalam kondisi tenang setelah latch (3 detik)
class VehicleCalmState: GKState {
    // Counter for elapsed time
    private var elapsedTime: TimeInterval = 0
    
    // Total duration of Calm State
    private let duration: TimeInterval = 3.0
    
    // Referensi ke node visual kendaraan
    weak var node: VehicleNode?
    // Referensi ke komponen yang memegang callback
    weak var component: VehicleRageComponent?
    
    init(node: VehicleNode, component: VehicleRageComponent) {
        self.node = node
        self.component = component
        super.init()
    }
    
    // Function to set the timer everytime latch
    override func didEnter(from previousState: GKState?) {
        // Reset Elapsed Time to 0 everytime latch is on
        elapsedTime = 0.0
        
        // TODO: - ADD ASSET HERE
        
        // Mengembalikan node ke kondisi visual tenang (Idle)
        node?.resetToCalm()
    }
    
    // Function to start the timer
    override func update (deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        // Increment the time (milisecond)
        elapsedTime += seconds
        // Check if time exceeds the required duration
        if elapsedTime >= duration {
            // Move to next state
            stateMachine?.enter(VehiclePoppingState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        // Fallback condition to only pass the state to Popping state.
        return stateClass == VehiclePoppingState.self
    }
}
