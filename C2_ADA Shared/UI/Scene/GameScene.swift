//
//  GameScene.swift
//  C2_ADA Shared
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import SpriteKit

class GameScene: SKScene {
    //MARK: Properties
    
    //WorldNode untuk kontrol isi game
    private let worldNode = SKNode()
    
    //MARK: Lifecycle
    override func didMove(to view: SKView) {
        setupNodes()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        //Game Loop
    }
}


//MARK: -Setups
extension GameScene {
    func setupNodes() {
        //Posisi X ditengah layar dan Y 30% dibawah layar
        let worldX = size.width / 2
        let worldY = size.height * (-0.3)
        worldNode.position = CGPoint(x: worldX, y: worldY)
        addChild(worldNode)
        
//        //Initial Floor (menutupi layar)
//        for i in 0..<20{
//            let floor = RowNode(rowIndex: i, colCount: 20)
//            worldNode.addChild(floor)
//        }
    }
}
