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

    // MARK: - State Sync

    /// Updates the switch without requiring a touch event.
    ///
    /// Settings uses this to mirror saved preferences when the screen is built.
    /// The callback is optional so loading stored state does not accidentally
    /// re-save the same value or trigger sound/haptic side effects.
    func setIsOn(
        _ isOn: Bool,
        animated: Bool = false,
        sendsCallback: Bool = false
    ) {
        self.isOn = isOn
        updateVisual(animated: animated)

        if sendsCallback {
            onToggleChanged?(isOn)
        }
    }

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
