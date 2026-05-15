//
//  StateMachine.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - State Transition

/// Describes one allowed move from one state to another.
nonisolated struct StateTransition<State: Hashable>: Hashable {
    let from: State
    let to: State
}

// MARK: - State Machine

/// Small reusable state machine helper.
///
/// If `allowedTransitions` is empty, every transition is allowed. If it has
/// values, `transition(to:)` succeeds only when the pair exists in the set.
nonisolated final class StateMachine<State: Hashable> {

    // MARK: - Stored State

    private(set) var currentState: State
    private let allowedTransitions: Set<StateTransition<State>>

    // MARK: - Initialization

    init(initialState: State, allowedTransitions: Set<StateTransition<State>> = []) {
        self.currentState = initialState
        self.allowedTransitions = allowedTransitions
    }

    // MARK: - Transition Checks

    func canTransition(to nextState: State) -> Bool {
        guard currentState != nextState else { return true }
        guard !allowedTransitions.isEmpty else { return true }
        return allowedTransitions.contains(StateTransition(from: currentState, to: nextState))
    }

    // MARK: - Transition Updates

    @discardableResult
    func transition(to nextState: State) -> Bool {
        guard canTransition(to: nextState) else { return false }
        currentState = nextState
        return true
    }
}
