//
//  HapticsController.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 22/05/26.
//

import CoreHaptics
import UIKit

// MARK: - Rage Haptic Phase

/// Rage phases that need CoreHaptics pulse feedback.
///
/// Calm is intentionally not represented here because calm vehicles should not
/// produce any haptic output. Keeping only active feedback phases makes callers
/// choose between "popping" and "hitting" explicitly.
enum RageHapticPhase {
    case popping
    case hitting
}

// MARK: - Haptics Controller

/// Central haptic access point for the game.
///
/// UI buttons use UIKit's lightweight feedback generator, while rage-state
/// pulses use CoreHaptics. Game code should call this controller instead of
/// constructing haptic engines or feedback generators directly, so unsupported
/// devices and the Settings toggle stay handled in one place.
final class HapticsController {

    // MARK: - Shared Instance

    /// Shared controller used by SpriteKit screens and GameplayKit components.
    static let shared = HapticsController()

    // MARK: - Storage Keys

    private enum StorageKey {
        static let isHapticsEnabled = "Nomad.HapticsController.isHapticsEnabled"
    }

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Runtime State

    private var engine: CHHapticEngine?
    private var lastRagePulseTime: TimeInterval = 0
    private var currentRagePhase: RageHapticPhase?

    /// Exposes the current Settings value so UI toggles can mirror it.
    private(set) var isHapticsEnabled: Bool

    /// CoreHaptics is unavailable on some devices and simulators, so every
    /// CoreHaptics path checks this before doing work.
    private let supportsCoreHaptics: Bool

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        if userDefaults.object(forKey: StorageKey.isHapticsEnabled) == nil {
            self.isHapticsEnabled = true
            userDefaults.set(true, forKey: StorageKey.isHapticsEnabled)
        } else {
            self.isHapticsEnabled = userDefaults.bool(forKey: StorageKey.isHapticsEnabled)
        }
    }

    // MARK: - Lifecycle

    /// Prepares the CoreHaptics engine before gameplay.
    ///
    /// Calling this repeatedly is safe. If the current device does not support
    /// CoreHaptics, or haptics are disabled in Settings, this becomes a no-op.
    func prepare() {
        guard isHapticsEnabled, supportsCoreHaptics else {
            return
        }

        do {
            let preparedEngine = try makeEngineIfNeeded()
            try preparedEngine.start()
        } catch {
            engine = nil
        }
    }

    /// Persists the Settings toggle and immediately stops active rage feedback
    /// when the player disables haptics.
    func setHapticsEnabled(_ isEnabled: Bool) {
        isHapticsEnabled = isEnabled
        userDefaults.set(isEnabled, forKey: StorageKey.isHapticsEnabled)

        guard isEnabled else {
            stopRagePulse()
            engine?.stop(completionHandler: nil)
            engine = nil
            return
        }

        prepare()
    }

    // MARK: - Button Feedback

    /// Plays a small UIKit tap for SpriteKit buttons and toggles.
    ///
    /// This intentionally uses `UIImpactFeedbackGenerator` instead of
    /// CoreHaptics because the requested button feedback should stay light and
    /// familiar across all game UI.
    func playLightButtonTap() {
        guard isHapticsEnabled else {
            return
        }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.45)
    }

    // MARK: - Rage Pulse Feedback

    /// Starts or updates the CoreHaptics pulse used by active rage states.
    ///
    /// `progress` is expected to move from `0...1` inside each rage state. The
    /// controller maps that progress into stronger intensity and shorter gaps,
    /// so Popping feels like a warning pulse and Hitting feels more urgent.
    func startOrUpdateRagePulse(phase: RageHapticPhase, progress: Double) {
        guard isHapticsEnabled, supportsCoreHaptics else {
            return
        }

        let clampedProgress = min(max(progress, 0), 1)
        let currentTime = Date().timeIntervalSinceReferenceDate
        let pulseInterval = ragePulseInterval(for: phase, progress: clampedProgress)

        if currentRagePhase != phase {
            currentRagePhase = phase
            lastRagePulseTime = 0
        }

        guard currentTime - lastRagePulseTime >= pulseInterval else {
            return
        }

        lastRagePulseTime = currentTime
        playRagePulse(phase: phase, progress: clampedProgress)
    }

    /// Stops the tracked rage pulse state.
    ///
    /// Transient CoreHaptics events are very short, so there is no long-running
    /// player to stop here. Resetting the pulse state prevents stale intensity
    /// and timing from leaking into the next vehicle rage cycle.
    func stopRagePulse() {
        currentRagePhase = nil
        lastRagePulseTime = 0
    }
}

// MARK: - CoreHaptics Engine

private extension HapticsController {

    /// Creates the engine lazily and installs recovery handlers once.
    func makeEngineIfNeeded() throws -> CHHapticEngine {
        if let engine {
            return engine
        }

        let newEngine = try CHHapticEngine()

        newEngine.stoppedHandler = { [weak self] _ in
            self?.engine = nil
        }

        newEngine.resetHandler = { [weak self] in
            self?.engine = nil
            self?.prepare()
        }

        engine = newEngine
        return newEngine
    }

    /// Builds and plays one short pulse.
    ///
    /// The repeated call from `startOrUpdateRagePulse` creates the felt pulse
    /// rhythm, while this method owns the exact intensity and sharpness of each
    /// individual CoreHaptics event.
    func playRagePulse(phase: RageHapticPhase, progress: Double) {
        do {
            let engine = try makeEngineIfNeeded()
            try engine.start()

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: Float(ragePulseIntensity(for: phase, progress: progress))
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: Float(ragePulseSharpness(for: phase, progress: progress))
                    )
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            engine = nil
        }
    }
}

// MARK: - Rage Pulse Tuning

private extension HapticsController {

    /// Popping uses wider gaps so it feels like an early warning.
    /// Hitting uses tighter gaps so the player can feel the danger escalating.
    func ragePulseInterval(for phase: RageHapticPhase, progress: Double) -> TimeInterval {
        switch phase {
        case .popping:
            return interpolatedValue(from: 0.34, to: 0.18, progress: progress)
        case .hitting:
            return interpolatedValue(from: 0.18, to: 0.10, progress: progress)
        }
    }

    /// Keeps Popping light and lets Hitting become noticeably stronger.
    func ragePulseIntensity(for phase: RageHapticPhase, progress: Double) -> Double {
        switch phase {
        case .popping:
            return interpolatedValue(from: 0.34, to: 0.68, progress: progress)
        case .hitting:
            return interpolatedValue(from: 0.72, to: 1.00, progress: progress)
        }
    }

    /// Sharpness rises with intensity so late Hitting pulses feel more urgent
    /// without turning the earlier Popping warning into a harsh impact.
    func ragePulseSharpness(for phase: RageHapticPhase, progress: Double) -> Double {
        switch phase {
        case .popping:
            return interpolatedValue(from: 0.34, to: 0.58, progress: progress)
        case .hitting:
            return interpolatedValue(from: 0.66, to: 0.94, progress: progress)
        }
    }

    func interpolatedValue(from startValue: Double, to endValue: Double, progress: Double) -> Double {
        startValue + ((endValue - startValue) * progress)
    }
}
