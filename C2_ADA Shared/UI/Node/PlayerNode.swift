//
//  PlayerNode.swift
//  C2_ADA Shared
//
//  Created by Gemini CLI on 25/05/26.
//

import SpriteKit

final class PlayerNode: SKSpriteNode {
    private let idleTexture = SKTexture(imageNamed: NomadAsset.playerIdle.rawValue)
    private let leftTexture = SKTexture(imageNamed: NomadAsset.playerLeft.rawValue)
    private let rightTexture = SKTexture(imageNamed: NomadAsset.playerRight.rawValue)
    private let deadTexture = SKTexture(imageNamed: NomadAsset.playerDead.rawValue)
    
    private let jumpTextures = [
        SKTexture(imageNamed: NomadAsset.playerJump1.rawValue),
        SKTexture(imageNamed: NomadAsset.playerJump2.rawValue)
    ]

    init(configuration: GameConfiguration) {
        super.init(texture: idleTexture, color: .clear, size: configuration.playerSize)
        self.name = "player"
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func playIdle() {
        removeAction(forKey: "jumpAnim")
        texture = idleTexture
    }

    func steer(isLeft: Bool) {
        removeAction(forKey: "jumpAnim")
        texture = isLeft ? leftTexture : rightTexture
    }

    func playJump() {
        removeAction(forKey: "jumpAnim")
        let animate = SKAction.animate(with: jumpTextures, timePerFrame: 0.18)
        run(animate, withKey: "jumpAnim")
    }

    func playDead() {
        removeAction(forKey: "jumpAnim")
        texture = deadTexture
    }
}
