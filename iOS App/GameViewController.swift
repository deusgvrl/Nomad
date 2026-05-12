//
//  GameViewController.swift
//  C2_ADA iOS
//
//  Created by Amadeus Gavriel on 07/05/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let view = self.view as? SKView else {
            return
        }
        
        // MARK: Setup
        let scene = GameScene(size: CGSize(width: 402, height: 874)) //Ukuran Iphone 17
        scene.scaleMode = .aspectFill
        
        view.ignoresSiblingOrder = true
        
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsPhysics = true
        view.presentScene(scene) //navigate ke scenenya (GameScene) 
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
