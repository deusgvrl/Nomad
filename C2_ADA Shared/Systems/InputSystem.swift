//
//  InputSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics

final class InputSystem {

    private var isTrackingTouch = false
    private var startLocation: CGPoint?

    private(set) var phase: InputPhase = .idle

    func begin(at location: CGPoint) -> InputPhase {
        guard !isTrackingTouch else { return phase }

        isTrackingTouch = true
        startLocation = location
        phase = .holding(startLocation: location)
        return phase
    }

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

    func end(at location: CGPoint) -> InputPhase {
        guard isTrackingTouch else { return phase }

        reset()
        phase = .released(releaseLocation: location)
        return phase
    }

    func reset() {
        isTrackingTouch = false
        startLocation = nil
        phase = .idle
    }
}
