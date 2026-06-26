//
//  GameFontRegistry.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 20/05/26.
//

import CoreText
import Foundation

// MARK: - Game Font Registry

/// Registers the game's shared typography so every SpriteKit screen can use
/// the same primary and secondary typefaces.
enum GameFontRegistry {

    // MARK: - Registration State

    /// Prevents repeated CoreText registration when a scene resets after retry.
    private static var didRegisterGameFonts = false

    // MARK: - Public Registration

    /// Registers the primary and secondary game fonts from `GameConfiguration`.
    ///
    /// Call this before building screens that create labels with the configured
    /// font names, including Game Over, menu, HUD, and future screens.
    static func registerGameFontsIfNeeded(configuration: GameConfiguration) {
        guard !didRegisterGameFonts else { return }

        // MARK: Shared Game Typeface Registration
        // Both fonts are game-wide resources, not Game Over-only resources.
        registerFontResource(named: configuration.primaryFontName, fileExtension: "ttf")
        registerFontResource(named: configuration.secondaryFontName, fileExtension: "ttf")
        didRegisterGameFonts = true
    }

    // MARK: - Font Resource Lookup

    /// Looks in both the bundle root and `Fonts/` folder so the registry works
    /// with the current project layout and with future bundled-resource cleanup.
    private static func registerFontResource(named name: String, fileExtension: String) {
        let directURL = Bundle.main.url(forResource: name, withExtension: fileExtension)
        let fontsFolderURL = Bundle.main.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "Fonts"
        )

        guard let fontURL = directURL ?? fontsFolderURL else { return }

        // MARK: Runtime Font Fallback
        // UIAppFonts handles normal app launch registration. This fallback keeps
        // SpriteKit labels safe when files are loaded from the synced folder.
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
