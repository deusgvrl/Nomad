//
//  MovementComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import GameplayKit

final class MovementComponent: GKComponent {

    private let xBounds: ClosedRange<CGFloat>
    private let dragSensitivity: CGFloat
    private var dragStartLocation: CGPoint?
    private var dragStartXPosition: CGFloat?

    private(set) var xPosition: CGFloat

    var isDragging: Bool {
        dragStartLocation != nil
    }

    init(xPosition: CGFloat, xBounds: ClosedRange<CGFloat>, dragSensitivity: CGFloat) {
        self.xPosition = xPosition
        self.xBounds = xBounds
        self.dragSensitivity = dragSensitivity
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginDrag(at location: CGPoint) {
        dragStartLocation = location
        dragStartXPosition = xPosition
    }

    func applyDragTranslation(_ translation: CGVector) -> CGFloat {
        let startingXPosition = dragStartXPosition ?? xPosition
        return setXPosition(startingXPosition + translation.dx * dragSensitivity)
    }

    func setXPosition(_ xPosition: CGFloat) -> CGFloat {
        self.xPosition = min(max(xPosition, xBounds.lowerBound), xBounds.upperBound)
        return self.xPosition
    }

    func endDrag() {
        dragStartLocation = nil
        dragStartXPosition = nil
    }
}
