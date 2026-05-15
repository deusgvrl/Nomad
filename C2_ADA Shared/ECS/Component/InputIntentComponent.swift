//
//  InputIntentComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit

// MARK: - Input Intent Component

/// Stores the latest cleaned touch input for an entity.
///
/// This component does not read UIKit touches directly. `InputSystem` converts
/// raw touches into `InputPhase`, then this component keeps that phase attached
/// to the player entity so other systems can react to it.
final class InputIntentComponent: GKComponent {

    // MARK: - Stored Input

    private(set) var phase: InputPhase = .idle

    // MARK: - Phase Updates

    func updatePhase(_ phase: InputPhase) {
        self.phase = phase
    }

    func reset() {
        phase = .idle
    }
}
