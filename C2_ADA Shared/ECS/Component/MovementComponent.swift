//
//  MovementComponent.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation
import GameplayKit

// MARK: - Movement Component

/// Converts finger drag into a car position along a shallow screen-space angle.
///
/// Important idea:
/// - The car is not moved by a random angle.
/// - Dragging left/right smoothly moves the car in both X and Y.
/// - The movement angle is configured separately from the isometric art angle.
/// - Spawn rows can also reuse this component as a simple speed holder.
///
/// This matches the current control direction: the player steers left/right on
/// the phone screen, while the world art can still stay isometric.
final class MovementComponent: GKComponent {

    // MARK: - Shared Movement Data

    private(set) var speed: CGFloat

    // MARK: - Screen Movement Data

    private let dragSensitivity: CGFloat
    private let screenXBounds: ClosedRange<CGFloat>
    private let screenYBounds: ClosedRange<CGFloat>
    private let movementOriginPosition: CGPoint
    private let movementAxisXOffsetBounds: ClosedRange<CGFloat>
    private let movementAxisSlope: CGFloat
    private var dragStartLocation: CGPoint?
    private var dragStartPosition: CGPoint?

    // MARK: - Current Movement State

    private(set) var position: CGPoint
    private(set) var roadWidthOffset: CGFloat

    var isDragging: Bool {
        dragStartLocation != nil
    }

    // MARK: - Initialization

    init(
        position: CGPoint,
        screenSize: CGSize,
        vehicleSize: CGSize,
        movementAxisAngleInDegrees: CGFloat,
        movementAxisXOffsetBounds: ClosedRange<CGFloat>,
        dragSensitivity: CGFloat
    ) {
        // Riding movement follows the shallow white guide line from the hi-fi
        // grid prototype. The road still looks isometric, but steering follows
        // this separate movement axis.
        //
        // Because `GameScene.anchorPoint` is (0.5, 0.5), the visible phone
        // bounds are centered around x = 0 and y = 0. The insets keep the
        // placeholder vehicle inside the screen instead of letting it clip out.
        let vehicleHalfWidth = vehicleSize.width / 2
        let vehicleHalfHeight = vehicleSize.height / 2
        let screenHalfWidth = screenSize.width / 2
        let screenHalfHeight = screenSize.height / 2
        let screenXBounds = (-screenHalfWidth + vehicleHalfWidth)...(screenHalfWidth - vehicleHalfWidth)
        let screenYBounds = (-screenHalfHeight + vehicleHalfHeight)...(screenHalfHeight - vehicleHalfHeight)
        let clampedX = min(max(position.x, screenXBounds.lowerBound), screenXBounds.upperBound)
        let clampedY = min(max(position.y, screenYBounds.lowerBound), screenYBounds.upperBound)
        let clampedPosition = CGPoint(x: clampedX, y: clampedY)
        let movementAxisRadians = Double(movementAxisAngleInDegrees) * Double.pi / 180

        // SpriteKit uses positive Y upward. The prototype angle is easier to
        // read as a phone-screen angle, so positive degrees tilt down to the
        // right visually by using a negative SpriteKit slope.
        let movementAxisSlope = -CGFloat(tan(movementAxisRadians))

        self.speed = 0
        self.dragSensitivity = dragSensitivity
        self.screenXBounds = screenXBounds
        self.screenYBounds = screenYBounds
        self.movementOriginPosition = clampedPosition
        self.movementAxisXOffsetBounds = movementAxisXOffsetBounds
        self.movementAxisSlope = movementAxisSlope
        self.position = clampedPosition
        self.roadWidthOffset = 0
        super.init()
    }

    /// Simple movement initializer used by `SpawnSystem` rows.
    ///
    /// Rows only need speed for treadmill movement, while player vehicles need
    /// full road-width steering. Keeping both in one component lets the ECS layer
    /// reuse a shared movement concept without forcing row movement into the
    /// player's steering math.
    init(speed: CGFloat) {
        self.speed = speed
        self.dragSensitivity = 1
        self.screenXBounds = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude
        self.screenYBounds = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude
        self.movementOriginPosition = .zero
        self.movementAxisXOffsetBounds = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude
        self.movementAxisSlope = 0
        self.position = .zero
        self.roadWidthOffset = 0
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drag Handling

    func beginDrag(at location: CGPoint) {
        dragStartLocation = location
        dragStartPosition = position
    }

    func applyDragTranslation(_ translation: CGVector) -> CGPoint {
        let startingPosition = dragStartPosition ?? position
        let targetXOffset = translation.dx * dragSensitivity
        return setPosition(from: startingPosition, xOffset: targetXOffset)
    }

    // MARK: - Position Clamping

    func setPosition(_ position: CGPoint) -> CGPoint {
        let proposedAxisOffset = position.x - movementOriginPosition.x
        return setAxisOffset(proposedAxisOffset)
    }

    private func setPosition(from startPosition: CGPoint, xOffset: CGFloat) -> CGPoint {
        let startingAxisOffset = startPosition.x - movementOriginPosition.x
        return setAxisOffset(startingAxisOffset + xOffset)
    }

    private func setAxisOffset(_ proposedAxisOffset: CGFloat) -> CGPoint {
        let clampedXOffset = clampedAxisOffset(proposedAxisOffset)
        let targetPosition = CGPoint(
            x: movementOriginPosition.x + clampedXOffset,
            y: movementOriginPosition.y + clampedXOffset * movementAxisSlope
        )
        let clampedPosition = CGPoint(
            x: min(max(targetPosition.x, screenXBounds.lowerBound), screenXBounds.upperBound),
            y: min(max(targetPosition.y, screenYBounds.lowerBound), screenYBounds.upperBound)
        )

        position = clampedPosition
        roadWidthOffset = clampedXOffset
        return clampedPosition
    }

    private func clampedAxisOffset(_ proposedAxisOffset: CGFloat) -> CGFloat {
        var lowerOffset = max(
            movementAxisXOffsetBounds.lowerBound,
            screenXBounds.lowerBound - movementOriginPosition.x
        )
        var upperOffset = min(
            movementAxisXOffsetBounds.upperBound,
            screenXBounds.upperBound - movementOriginPosition.x
        )

        if movementAxisSlope != 0 {
            let yLowerOffset = (screenYBounds.lowerBound - movementOriginPosition.y) / movementAxisSlope
            let yUpperOffset = (screenYBounds.upperBound - movementOriginPosition.y) / movementAxisSlope
            lowerOffset = max(lowerOffset, min(yLowerOffset, yUpperOffset))
            upperOffset = min(upperOffset, max(yLowerOffset, yUpperOffset))
        }

        return min(max(proposedAxisOffset, lowerOffset), upperOffset)
    }

    // MARK: - Reset

    func endDrag() {
        dragStartLocation = nil
        dragStartPosition = nil
    }
}
