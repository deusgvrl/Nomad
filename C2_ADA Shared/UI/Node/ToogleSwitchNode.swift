//
//  ToogleSwitchNode.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 21/05/26.
//

import SpriteKit

final class ToggleSwitchNode: SKNode {

    // MARK: - State

    private(set) var isOn: Bool = true

    var onToggleChanged: ((Bool) -> Void)?

    // MARK: - Nodes

    private let spriteNode = SKSpriteNode()

    // MARK: - Init

    override init() {
        super.init()

        isUserInteractionEnabled = true
        addChild(spriteNode)
        
        updateVisual()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Interaction

extension ToggleSwitchNode {

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        isOn.toggle()
        updateVisual()
        onToggleChanged?(isOn)
    }
}

// MARK: - Visual Update

private extension ToggleSwitchNode {

    func updateVisual() {
        let textureName = isOn ? "On" : "Off"
        let texture = SKTexture(imageNamed: textureName)
        spriteNode.texture = texture
        
        // Pastikan ukuran node sama persis dengan ukuran gambar asset
        // agar tidak memakan area sentuhan node lain di sekitarnya.
        spriteNode.size = texture.size()
    }
}
