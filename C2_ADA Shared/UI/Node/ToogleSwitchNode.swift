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

    private let backgroundNode: SKShapeNode
    private let knobNode: SKShapeNode

    // MARK: - Init

    override init() {

        // Background
        backgroundNode = SKShapeNode(
            rectOf: CGSize(width: 70, height: 36),
            cornerRadius: 18
        )

        // Knob
        knobNode = SKShapeNode(
            circleOfRadius: 14
        )

        super.init()

        isUserInteractionEnabled = true

        setupNodes()
        updateVisual(animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup

private extension ToggleSwitchNode {

    func setupNodes() {

        backgroundNode.strokeColor = .clear

        addChild(backgroundNode)

        knobNode.fillColor = .white
        knobNode.strokeColor = .clear

        addChild(knobNode)
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

        updateVisual(animated: true)

        onToggleChanged?(isOn)
    }
}

// MARK: - Visual Update

private extension ToggleSwitchNode {

    func updateVisual(animated: Bool) {

        let backgroundColor: SKColor =
        isOn ? .systemGreen : SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)

        let knobPositionX: CGFloat =
        isOn ? 16 : -16

        let updateBlock = {

            self.backgroundNode.fillColor = backgroundColor

            self.knobNode.position = CGPoint(
                x: knobPositionX,
                y: 0
            )
        }

        if animated {

            let move = SKAction.moveTo(
                x: knobPositionX,
                duration: 0.12
            )

            move.timingMode = .easeInEaseOut

            backgroundNode.fillColor = backgroundColor

            knobNode.run(move)

        } else {

            updateBlock()
        }
    }
}
