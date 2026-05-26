//
//  GameScene+Tutorial.swift
//  C2_ADA Shared
//
//  Created by Derick Norlan on 25/05/26.
//

import SpriteKit

// MARK: - Tutorial Helpers

extension GameScene {
    
    func showStartOverlay() {
        let highscore = UserDefaults.standard.integer(forKey: "Nomad.DistanceScoreSystem.highScoreMeters")
        
        if highscore < 250 {
            let screen = TutorialScreen(sceneSize: size)
            screen.onHoldStarted = { [weak self] in
                guard let self else { return }
                self.tutorialScreen = nil
                self.gameState = .waitingToStart
            }
            screen.show(in: self)
            self.tutorialScreen = screen
        } else {
            showStandardDimmedStartScreen()
        }
    }
    
    func showStandardDimmedStartScreen() {
        let screen = DimmedStartScreen(
            sceneSize: size
        )

        screen.onHoldStarted = { [weak self] in
            guard let self else { return }
            self.dimmedStartScreen = nil
            self.gameState = .waitingToStart
        }

        screen.show(in: self)
        self.dimmedStartScreen = screen
    }
    
    func showSteerTutorial() {
        hasShownSteerTutorial = true
        isShowingSteerTutorial = true

        let screen = TutorialScreen2(sceneSize: size)

        screen.onDismissed = { }

        screen.show(in: self)
        self.tutorialScreen2 = screen

        // SLOW MOTION
        targetTimeScale = 0.5
        currentTimeScale = 0.5
        self.speed = 0.15
    }

    func showReleaseTutorial() {
        // Jika Tutorial 2 masih muncul dan belum diinteraksi, hapus dulu
        if isShowingSteerTutorial {
            tutorialScreen2?.dismiss()
            self.tutorialScreen2 = nil
            self.isShowingSteerTutorial = false
        }

        hasShownReleaseTutorial = true
        isShowingReleaseTutorial = true

        let screen = TutorialScreen3(
            sceneSize: size,
            targetNode: currentVehicleEntity?.node
        )

        screen.onReleaseStarted = { [weak self] in
            guard let self else { return }
            self.tutorialScreen3 = nil
            self.isShowingReleaseTutorial = false
            
            // Trigger Tutorial 4 Langsung setelah rilis
            self.showLatchTutorial()
        }

        screen.show(in: self)
        self.tutorialScreen3 = screen

        // SLOW MOTION
        targetTimeScale = 0.3
        currentTimeScale = 0.3
        self.speed = 0.1
    }

    func showLatchTutorial() {
        // Hanya muncul jika highscore < 250m
        let highscore = UserDefaults.standard.integer(forKey: "Nomad.DistanceScoreSystem.highScoreMeters")
        guard highscore < 250 else {
            self.targetTimeScale = 1.0
            self.currentTimeScale = 1.0
            self.speed = 1.0
            return
        }
        
        hasShownLatchTutorial = true
        isShowingLatchTutorial = true

        let screen = TutorialScreen4(sceneSize: size)

        screen.onHoldStarted = { [weak self] in
            guard let self else { return }
            self.tutorialScreen4 = nil
            self.isShowingLatchTutorial = false
            
            self.targetTimeScale = 1.0
            self.currentTimeScale = 1.0
            self.speed = 1.0
        }

        screen.show(in: self)
        self.tutorialScreen4 = screen

        // Animasi pulse untuk target highlight (Tutorial 4)
        targetTutorialHighlightNode.removeAllActions()
        let pulseUp = SKAction.scale(to: 1.1, duration: 0.4)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.4)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        
        targetTutorialHighlightNode.run(SKAction.repeatForever(pulse))

        // SLOW MOTION (Disesuaikan agar tidak terlalu lambat)
        targetTimeScale = 0.4
        currentTimeScale = 0.4
        self.speed = 0.10
    }

    func dismissAllTutorials() {
        if let tutorialScreen {
            tutorialScreen.hide()
            self.tutorialScreen = nil
        }
        
        if let tutorialScreen2 {
            tutorialScreen2.dismiss() // TutorialScreen2 HAS dismiss()
            self.tutorialScreen2 = nil
            self.isShowingSteerTutorial = false
        }
        
        if let tutorialScreen3 {
            tutorialScreen3.hide()
            self.tutorialScreen3 = nil
            self.isShowingReleaseTutorial = false
        }
        
        if let tutorialScreen4 {
            tutorialScreen4.hide()
            self.tutorialScreen4 = nil
            self.isShowingLatchTutorial = false
        }
        
        // Reset speed to normal
        self.targetTimeScale = 1.0
        self.currentTimeScale = 1.0
        self.speed = 1.0
    }
}
