//
//  RageState.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 14/05/26.
//

import GameplayKit

class VehiclePoppingState: GKState {
    private var elapsedTime: TimeInterval = 0
    private let duration: TimeInterval = 2.0 // 5s - 3s
    
    override func didEnter(from previousState: GKState?){
        elapsedTime = 0.0
        // TODO: - ADD POPPING OUT ASSET
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
        return stateClass == VehicleHittingState.self
    }
}

class VehicleHittingState: GKState {
    private var elapsedTime: TimeInterval = 0
    private let duration: TimeInterval = 2.0 // 5s - 3s
    
    override func didEnter(from previousState: GKState?){
        elapsedTime = 0.0
        // TODO: - ADD POPPING OUT ASSET
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
        return stateClass == VehicleJumpState.self
    }
}

class VehicleJumpState: GKState {
    override func didEnter(from previousState: GKState?){
        super.didEnter(from: previousState)
        
        // TODO: - ADD JUMPING SYSTEM HERE.
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return false
    }
}


// MARK: - CALM STATE
class VehicleCalmState: GKState {
    // Counter for elapsed time
    private var elapsedTime: TimeInterval = 0
    
    // Total duration of Calm State
    private let duration: TimeInterval = 3.0
    
    // Function to set the timer everytime latch
    override func didEnter(from previousState: GKState?) {
        // Reset Elapsed Time to 0 everytime latch is on
        elapsedTime = 0.0
        
        // TODO: - ADD ASSET HERE
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
    
    
    
