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

    // MARK: - Haptics

    /// Central controller for all rage haptics.
    ///
    /// The state machine owns the timing of Calm, Popping, Hitting, and Jump.
    /// This component only forwards those state updates into the shared haptics
    /// controller so CoreHaptics stays isolated from state classes.
    private let hapticsController: HapticsController

    // MARK: - Audio

    /// Central audio controller for the repeating final rage warning.
    ///
    /// Rage state transitions own the valid lifetime of the hitting sound; the
    /// component forwards only start/stop intent so states never build nodes.
    private let audioController: AudioController
    
    /// Inisialisasi komponen dengan referensi ke node visual kendaraan
    init(
        node: VehicleNode,
        hapticsController: HapticsController = .shared,
        audioController: AudioController = .shared
    ) {
        self.hapticsController = hapticsController
        self.audioController = audioController
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
        stopRageHaptics()
        stopRageAudio()
        stateMachine?.enter(VehicleCalmState.self)
    }

    // MARK: - Rage Haptics

    /// Updates the active CoreHaptics pulse for the current rage phase.
    ///
    /// `progress` comes from each state's elapsed time. The controller converts
    /// it into stronger and faster pulse feedback as rage increases.
    func updateRageHaptics(phase: RageHapticPhase, progress: Double) {
        hapticsController.startOrUpdateRagePulse(
            phase: phase,
            progress: progress
        )
    }

    /// Stops rage haptics whenever the vehicle becomes calm, jumps, or leaves
    /// the active gameplay flow.
    func stopRageHaptics() {
        hapticsController.stopRagePulse()
    }

    // MARK: - Rage Audio

    /// Starts the repeated hitting sound only for the final danger phase.
    func startRageAudio() {
        audioController.startLoop(.rageHitting)
    }

    /// Ends the repeated hitting sound on jump, calm reset, or interrupted ride.
    func stopRageAudio() {
        audioController.stopLoop(.rageHitting)
    }
}
