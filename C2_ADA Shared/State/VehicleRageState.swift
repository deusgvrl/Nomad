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

        // MARK: Popping Haptic Start
        // Popping is the first rage warning, so it starts with a soft pulse.
        // The pulse gets stronger during `update(deltaTime:)` as elapsed time
        // moves toward the Hitting transition.
        component?.updateRageHaptics(phase: .popping, progress: 0)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds

        // MARK: Popping Haptic Ramp
        // The haptic controller maps this 0...1 progress to slightly stronger
        // and faster pulses, keeping Popping readable but still lighter than
        // Hitting.
        let progress = min(elapsedTime / duration, 1)
        component?.updateRageHaptics(phase: .popping, progress: progress)

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

        // MARK: Hitting Haptic Start
        // Hitting is the dangerous rage phase, so it starts harder than
        // Popping. The update loop continues ramping the pulse until Jump.
        component?.updateRageHaptics(phase: .hitting, progress: 0)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds

        // MARK: Hitting Haptic Ramp
        // Hitting uses the same normalized progress shape as Popping, but the
        // controller gives it a stronger intensity range and faster rhythm so
        // players can feel the rage peak.
        let progress = min(elapsedTime / duration, 1)
        component?.updateRageHaptics(phase: .hitting, progress: progress)

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
        
        // MARK: Jump Haptic Stop
        // Jump ends the rage warning loop. Stop pulse tracking before asking
        // GameScene to detach the player so no rage haptic leaks into the jump.
        component?.stopRageHaptics()

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

        // MARK: Calm Haptic Stop
        // Calm state intentionally has no haptic output. Entering Calm also
        // clears any pulse timing from the previous vehicle rage cycle.
        component?.stopRageHaptics()
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
