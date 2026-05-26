//
//  StorageController.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 26/05/26.
//

import Foundation

// MARK: - Storage Controller

/// Centralizes lightweight player preferences stored in `UserDefaults`.
///
/// Live gameplay state does not belong in persistent storage. This controller
/// stores only settings that must survive scene rebuilds and future app
/// launches, beginning with the Sound toggle used by `AudioController`.
final class StorageController {

    // MARK: - Shared Instance

    static let shared = StorageController()

    // MARK: - Storage Keys

    private enum StorageKey {
        static let isAudioEnabled = "Nomad.StorageController.isAudioEnabled"
    }

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if userDefaults.object(forKey: StorageKey.isAudioEnabled) == nil {
            userDefaults.set(true, forKey: StorageKey.isAudioEnabled)
        }
    }

    // MARK: - Audio Preference

    /// Whether sound effects and vehicle loops are allowed to play.
    var isAudioEnabled: Bool {
        get {
            userDefaults.bool(forKey: StorageKey.isAudioEnabled)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.isAudioEnabled)
        }
    }
}
