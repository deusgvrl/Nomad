//
//  InputSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics

// MARK: - Input System

/// Converts raw touch events into simple gameplay input phases.
///
/// GameScene sends touches here first. The rest of the game reads clean states:
/// hold, drag, release, or idle.
final class InputSystem {

    // MARK: - Touch Tracking

    private var isTrackingTouch = false
    private var startLocation: CGPoint?

    private(set) var phase: InputPhase = .idle

    // MARK: - Touch Begin

    func begin(at location: CGPoint) -> InputPhase {
        guard !isTrackingTouch else { return phase }

        isTrackingTouch = true
        startLocation = location
        phase = .holding(startLocation: location)
        return phase
    }

    // MARK: - Touch Move

    func move(to currentLocation: CGPoint) -> InputPhase {
        guard isTrackingTouch, let startLocation else { return phase }

        phase = .dragging(
            startLocation: startLocation,
            currentLocation: currentLocation,
            translation: CGVector(
                dx: currentLocation.x - startLocation.x,
                dy: currentLocation.y - startLocation.y
            )
        )
        return phase
    }

    // MARK: - Touch End

    func end(at location: CGPoint) -> InputPhase {
        guard isTrackingTouch else { return phase }

        reset()
        phase = .released(releaseLocation: location)
        return phase
    }

    // MARK: - Reset

    func reset() {
        isTrackingTouch = false
        startLocation = nil
        phase = .idle
    }
}
