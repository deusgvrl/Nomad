//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private let worldNode = SKNode()
    
    private var spawnSystem: SpawnSystem?
    
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        setupNodes()
        
        spawnSystem = SpawnSystem(
            worldNode: worldNode,
            sceneSize: size
        )
    }
    
    override func update(_ currentTime: TimeInterval) {
        spawnSystem?.update(currentTime)
    }
}


// MARK: - Setup

extension GameScene {
    
    private func setupNodes() {
        
        let worldX = size.width / 2
        let worldY = size.height * (-0.3)
        
        worldNode.position = CGPoint(
            x: worldX,
            y: worldY
        )
        
        addChild(worldNode)
    }
}
