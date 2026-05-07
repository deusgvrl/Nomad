//
//  LaunchComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation
import GameplayKit

final class LaunchComponent: GKComponent {

    private(set) var isAirborne = false
    private(set) var currentPosition: CGPoint = .zero
    private var horizontalVelocity: CGFloat = 0
    private var verticalVelocity: CGFloat = 0

    func launch(from position: CGPoint, horizontalVelocity: CGFloat, verticalVelocity: CGFloat) {
        isAirborne = true
        currentPosition = position
        self.horizontalVelocity = horizontalVelocity
        self.verticalVelocity = verticalVelocity
    }

    func update(deltaTime: TimeInterval, gravity: CGFloat) -> CGPoint {
        guard isAirborne else { return currentPosition }

        let elapsedTime = CGFloat(deltaTime)
        verticalVelocity -= gravity * elapsedTime
        currentPosition = CGPoint(
            x: currentPosition.x + horizontalVelocity * elapsedTime,
            y: currentPosition.y + verticalVelocity * elapsedTime
        )
        return currentPosition
    }

    func reset() {
        isAirborne = false
        horizontalVelocity = 0
        verticalVelocity = 0
    }
}
