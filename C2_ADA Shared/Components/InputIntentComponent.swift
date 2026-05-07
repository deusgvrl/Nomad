//
//  InputIntentComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import GameplayKit

final class InputIntentComponent: GKComponent {

    private(set) var phase: InputPhase = .idle

    func updatePhase(_ phase: InputPhase) {
        self.phase = phase
    }

    func reset() {
        phase = .idle
    }
}
