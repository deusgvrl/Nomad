//
//  InputPhase.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics

// MARK: - Input Phase

/// Clean input states used by the gameplay systems.
///
/// Raw touches can be noisy. `InputSystem` converts them into these cases so
/// `GameScene` can read gameplay intention directly.
enum InputPhase {
    /// No active touch.
    case idle

    /// Finger is down but has not necessarily moved.
    case holding(startLocation: CGPoint)

    /// Finger is still down and has moved from the first hold location.
    case dragging(startLocation: CGPoint, currentLocation: CGPoint, translation: CGVector)

    /// Finger lifted; this is the release-to-jump trigger.
    case released(releaseLocation: CGPoint)
}
