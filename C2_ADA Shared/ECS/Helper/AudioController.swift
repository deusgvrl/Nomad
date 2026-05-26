//
//  AudioController.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 26/05/26.
//

import Foundation
import SpriteKit

// MARK: - One-Shot Audio Events

/// Short gameplay confirmations that should play exactly once per event.
///
/// Future button effects can be added here without teaching
/// `GameScene` about filenames or SpriteKit audio construction.
enum AudioEvent: String {
    case landsOnCar = "Lands on Car_NOMAD"
    case playerFalls = "Player Falls_NOMAD"
    case playerJump = "Player Jump_NOMAD"

    /// Balances impact confirmations below music and vehicle loops so a short
    /// event does not spike above the rest of the gameplay audio mix.
    var playbackVolume: Float {
        switch self {
        case .landsOnCar, .playerFalls, .playerJump:
            return 0.15
        }
    }

    /// Leaves enough time for the node to finish before it is removed.
    var cleanupDelay: TimeInterval {
        switch self {
        case .landsOnCar:
            return 2.0
        case .playerFalls:
            return 5.0
        case .playerJump:
            return 2.0
        }
    }
}

// MARK: - Looping Audio Channels

/// Long-lived sounds whose lifetime follows a gameplay condition.
///
/// Menu and gameplay music also live here so screen/run transitions use the
/// same duplicate prevention, pause restoration, and persisted Sound setting
/// as vehicle loops.
enum AudioLoop: String, CaseIterable, Hashable {
    case homeBackground = "Home Background_NOMAD"
    case inGameMusic = "In-Game Music_NOMAD"
    case engine = "Car Engine3 (Gravel)_NOMAD"
    case steering = "Car Turns Left_Right_NOMAD"
    case rageHitting = "Hitting Sound_NOMAD"

    /// Keeps continuous background tracks behind gameplay feedback without
    /// changing the global Sound toggle or reducing one-shot action cues.
    var playbackVolume: Float {
        switch self {
        case .inGameMusic:
            return 0.15
        case .engine:
            return 0.10
        case .rageHitting:
            return 0.15
        case .steering:
            return 0.15
        default:
            return 1.0
        }
    }
}

// MARK: - Audio Controller

/// Owns all SpriteKit audio playback for the current scene.
///
/// The scene and state-machine layers report named gameplay intent only. This
/// controller resolves bundled files, creates `SKAudioNode` instances, obeys
/// the persisted Sound setting, and keeps looping channels stable across pause
/// and resume transitions.
final class AudioController {

    // MARK: - Shared Instance

    static let shared = AudioController()

    // MARK: - Dependencies

    private let storageController: StorageController

    // MARK: - Playback Nodes

    private let audioRootNode = SKNode()
    private let loopContainerNode = SKNode()
    private let effectContainerNode = SKNode()
    private weak var scene: SKScene?

    // MARK: - Playback State

    /// The setting shown by `SettingsScreen`; changes are persisted immediately.
    private(set) var isAudioEnabled: Bool

    /// Loops that gameplay still requires, even when muted or temporarily paused.
    private var requestedLoops: Set<AudioLoop> = []

    /// Nodes actually audible in the current scene.
    private var playbackNodes: [AudioLoop: SKAudioNode] = [:]

    /// Pause suppresses playback while retaining loops that should resume later.
    private var isPlaybackSuspended = false

    // MARK: - Initialization

    init(storageController: StorageController = .shared) {
        self.storageController = storageController
        self.isAudioEnabled = storageController.isAudioEnabled

        audioRootNode.name = "audioRoot"
        loopContainerNode.name = "audioLoops"
        effectContainerNode.name = "audioEffects"
        audioRootNode.addChild(loopContainerNode)
        audioRootNode.addChild(effectContainerNode)
    }

    // MARK: - Scene Lifecycle

    /// Attaches non-positional audio to the active SpriteKit scene.
    ///
    /// Keeping audio below one scene-owned root lets retry/home cleanup remove
    /// playback predictably without attaching sounds to moving world nodes.
    func attach(to scene: SKScene) {
        self.scene = scene

        if audioRootNode.parent !== scene {
            audioRootNode.removeFromParent()
            scene.addChild(audioRootNode)
        }

        materializeRequestedLoopsIfPossible()
    }

    /// Clears all gameplay audio when a run is rebuilt or returns home.
    ///
    /// Unlike pause, reset removes requested loop intent because the next run
    /// must decide afresh which sounds are valid.
    func resetGameplayAudio() {
        requestedLoops.removeAll()
        isPlaybackSuspended = false
        removeRenderedLoops()
        effectContainerNode.removeAllChildren()
    }

    // MARK: - Settings

    /// Persists the Sound toggle and immediately applies the new playback rule.
    ///
    /// Muting removes audible nodes while leaving current loop intent intact;
    /// enabling Sound can therefore restore an engine or rage loop only when
    /// gameplay still considers it active.
    func setAudioEnabled(_ isEnabled: Bool) {
        isAudioEnabled = isEnabled
        storageController.isAudioEnabled = isEnabled

        if isEnabled {
            materializeRequestedLoopsIfPossible()
        } else {
            removeRenderedLoops()
            effectContainerNode.removeAllChildren()
        }
    }

    // MARK: - One-Shot Effects

    /// Plays a short, named event without exposing audio files to callers.
    func play(_ event: AudioEvent) {
        guard isAudioEnabled,
              !isPlaybackSuspended,
              let node = makeAudioNode(resourceName: event.rawValue) else {
            return
        }

        node.name = "audioEffect.\(event.rawValue)"
        node.autoplayLooped = false
        effectContainerNode.addChild(node)
        node.run(
            SKAction.sequence([
                // MARK: One-Shot Mix Balance
                // Apply the selected event's mix level before sound begins.
                SKAction.changeVolume(to: event.playbackVolume, duration: 0.0),
                SKAction.play(),
                SKAction.wait(forDuration: event.cleanupDelay),
                SKAction.stop(),
                SKAction.removeFromParent()
            ])
        )
    }

    // MARK: - Loop Lifecycle

    /// Requests one looping channel; repeated requests remain a single node.
    func startLoop(_ loop: AudioLoop) {
        requestedLoops.insert(loop)
        materializeRequestedLoopsIfPossible()
    }

    /// Ends one gameplay condition and removes its rendered loop immediately.
    func stopLoop(_ loop: AudioLoop) {
        requestedLoops.remove(loop)
        removeRenderedLoop(loop)
    }

    /// Stops every loop because no running gameplay condition remains valid.
    func stopAllLoops() {
        requestedLoops.removeAll()
        removeRenderedLoops()
    }

    // MARK: - Pause And Resume

    /// Silences gameplay while an overlay pauses the run.
    ///
    /// In-game music, engine, and hitting intent is retained so resume restores
    /// only loops that were already valid. Steering is stopped by `GameScene`
    /// separately, because a paused finger drag is no longer active input.
    func suspendLoops() {
        isPlaybackSuspended = true
        removeRenderedLoops()
    }

    /// Restarts retained loops after countdown/resume, respecting Sound mute.
    func resumeLoops() {
        isPlaybackSuspended = false
        materializeRequestedLoopsIfPossible()
    }
}

// MARK: - Node Construction

private extension AudioController {

    /// Creates a non-positional node from bundled resources.
    ///
    /// Xcode may preserve `Resources/Audio` as a subdirectory or flatten copied
    /// resources into the app bundle. Supporting both layouts keeps playback
    /// stable while project resource membership evolves.
    func makeAudioNode(resourceName: String) -> SKAudioNode? {
        let resourceURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: "mp3",
            subdirectory: "Audio"
        ) ?? Bundle.main.url(
            forResource: resourceName,
            withExtension: "mp3"
        )

        guard let resourceURL else {
            return nil
        }

        let node = SKAudioNode(url: resourceURL)
        node.isPositional = false
        return node
    }

    /// Builds nodes only for requested channels not already being rendered.
    func materializeRequestedLoopsIfPossible() {
        guard isAudioEnabled,
              !isPlaybackSuspended,
              scene != nil else {
            return
        }

        for loop in requestedLoops where playbackNodes[loop] == nil {
            guard let node = makeAudioNode(resourceName: loop.rawValue) else {
                continue
            }

            node.name = "audioLoop.\(loop.rawValue)"
            node.autoplayLooped = true

            // MARK: Per-Loop Mix Balance
            // Queue volume before insertion so a reduced music track begins at
            // its intended level rather than briefly starting at full volume.
            node.run(SKAction.changeVolume(to: loop.playbackVolume, duration: 0.0))
            loopContainerNode.addChild(node)
            playbackNodes[loop] = node
        }
    }

    func removeRenderedLoop(_ loop: AudioLoop) {
        playbackNodes[loop]?.removeFromParent()
        playbackNodes[loop] = nil
    }

    func removeRenderedLoops() {
        for loop in AudioLoop.allCases {
            removeRenderedLoop(loop)
        }
    }
}
