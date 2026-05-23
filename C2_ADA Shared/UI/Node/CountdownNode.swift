//
//  SettingsScreen.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 22/05/26.
//

import SpriteKit

/// Layar dimmed dengan countdown (3, 2, 1) sebelum game dilanjutkan.
final class CountdownNode: SKNode {
    
    private let label = SKLabelNode()
    private let background: SKShapeNode
    private let configuration: GameConfiguration
    private let haptics: HapticsController
    
    init(configuration: GameConfiguration, sceneSize: CGSize, haptics: HapticsController = .shared) {
        self.configuration = configuration
        self.haptics = haptics
        
        // Buat Background Dimmed (sedikit lebih gelap agar angka terlihat jelas)
        self.background = SKShapeNode(rectOf: sceneSize)
        self.background.fillColor = ColorHelper.fromHex(0x49270E, alpha: 0.58)
        self.background.strokeColor = .clear
        self.background.zPosition = 0
        
        super.init()
        
        self.name = "resumeCountdownNode"
        
        // Setup Label menggunakan Primary Font
        label.fontName = configuration.primaryFontName
        label.fontSize = 120
        label.fontColor = ColorHelper.fromHex(0xF6A74C)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        
        addChild(background)
        addChild(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Menjalankan animasi countdown 3, 2, 1 kemudian menghapus diri sendiri.
    func start(completion: @escaping () -> Void) {
        let counts = ["3", "2", "1"]
        var actions: [SKAction] = []
        
        for text in counts {
            let step = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.label.text = text
                
                // Animasi "Pop" agar angka terasa hidup
                self.label.setScale(0.2)
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleNormal = SKAction.scale(to: 1.0, duration: 0.1)
                self.label.run(SKAction.sequence([scaleUp, scaleNormal]))
                
                // Feedback haptic instan di setiap angka
                self.haptics.playLightButtonTap()
            }
            
            let wait = SKAction.wait(forDuration: 0.7) // Durasi setiap angka tampil
            actions.append(contentsOf: [step, wait])
        }
        
        let finish = SKAction.run {
            completion()
        }
        
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence(actions + [finish, remove]))
    }
}
