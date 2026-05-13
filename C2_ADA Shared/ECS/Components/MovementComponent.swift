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

/// Converts finger drag into a car position inside the isometric road width.
///
/// Important idea:
/// - The car is not moved by a random angle.
/// - The car has a fixed forward position on the road.
/// - Dragging left/right changes only its offset across the road width.
///
/// This matches the lo-fi design: the road borders define the playable band.
final class MovementComponent: GKComponent {

    // MARK: - Road Coordinate Data

    private let dragSensitivity: CGFloat
    private let roadStartCenterPosition: CGPoint
    private let roadForwardUnit: CGVector
    private let roadRightUnit: CGVector
    private let roadWidthBounds: ClosedRange<CGFloat>
    private let forwardOffset: CGFloat
    private var dragStartLocation: CGPoint?
    private var dragStartRoadWidthOffset: CGFloat?

    // MARK: - Current Movement State

    private(set) var position: CGPoint
    private(set) var roadWidthOffset: CGFloat

    var isDragging: Bool {
        dragStartLocation != nil
    }

    // MARK: - Initialization

    init(
        position: CGPoint,
        roadStartCenterPosition: CGPoint,
        roadAngleInDegrees: CGFloat,
        roadWidth: CGFloat,
        vehicleWidth: CGFloat,
        dragSensitivity: CGFloat
    ) {
        // Convert the road angle into two direction vectors:
        // forward = along the road, right = across the road width.
        let roadRadians = Double(roadAngleInDegrees) * Double.pi / 180
        let forwardUnit = CGVector(dx: CGFloat(cos(roadRadians)), dy: CGFloat(sin(roadRadians)))
        let rightUnit = CGVector(
            dx: CGFloat(cos(roadRadians - Double.pi / 2)),
            dy: CGFloat(sin(roadRadians - Double.pi / 2))
        )
        let positionOffset = CGVector(
            dx: position.x - roadStartCenterPosition.x,
            dy: position.y - roadStartCenterPosition.y
        )
        let vehicleInset = vehicleWidth / 2
        let roadHalfWidth = roadWidth / 2
        let forwardOffset = positionOffset.dot(forwardUnit)
        // Keep the vehicle inside the road by reserving half the vehicle width
        // on both sides, so the placeholder does not clip through the border.
        let roadWidthBounds = (-roadHalfWidth + vehicleInset)...(roadHalfWidth - vehicleInset)
        let roadWidthOffset = min(
            max(positionOffset.dot(rightUnit), roadWidthBounds.lowerBound),
            roadWidthBounds.upperBound
        )

        self.dragSensitivity = dragSensitivity
        self.roadStartCenterPosition = roadStartCenterPosition
        self.roadForwardUnit = forwardUnit
        self.roadRightUnit = rightUnit
        self.roadWidthBounds = roadWidthBounds
        self.forwardOffset = forwardOffset
        self.roadWidthOffset = roadWidthOffset
        self.position = Self.makePosition(
            roadStartCenterPosition: roadStartCenterPosition,
            roadForwardUnit: forwardUnit,
            roadRightUnit: rightUnit,
            forwardOffset: forwardOffset,
            roadWidthOffset: roadWidthOffset
        )
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drag Handling

    func beginDrag(at location: CGPoint) {
        dragStartLocation = location
        dragStartRoadWidthOffset = roadWidthOffset
    }

    func applyDragTranslation(_ translation: CGVector) -> CGPoint {
        let startingRoadWidthOffset = dragStartRoadWidthOffset ?? roadWidthOffset
        // Only horizontal finger movement changes steering for now.
        let targetRoadWidthOffset = startingRoadWidthOffset + translation.dx * dragSensitivity
        return setRoadWidthOffset(targetRoadWidthOffset)
    }

    // MARK: - Position Projection

    func setPosition(_ position: CGPoint) -> CGPoint {
        let positionOffset = CGVector(
            dx: position.x - roadStartCenterPosition.x,
            dy: position.y - roadStartCenterPosition.y
        )
        return setRoadWidthOffset(positionOffset.dot(roadRightUnit))
    }

    private func setRoadWidthOffset(_ roadWidthOffset: CGFloat) -> CGPoint {
        // Clamp to the left/right road borders before converting back to screen points.
        self.roadWidthOffset = min(max(roadWidthOffset, roadWidthBounds.lowerBound), roadWidthBounds.upperBound)
        position = Self.makePosition(
            roadStartCenterPosition: roadStartCenterPosition,
            roadForwardUnit: roadForwardUnit,
            roadRightUnit: roadRightUnit,
            forwardOffset: forwardOffset,
            roadWidthOffset: self.roadWidthOffset
        )
        return position
    }

    private static func makePosition(
        roadStartCenterPosition: CGPoint,
        roadForwardUnit: CGVector,
        roadRightUnit: CGVector,
        forwardOffset: CGFloat,
        roadWidthOffset: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: roadStartCenterPosition.x + roadForwardUnit.dx * forwardOffset + roadRightUnit.dx * roadWidthOffset,
            y: roadStartCenterPosition.y + roadForwardUnit.dy * forwardOffset + roadRightUnit.dy * roadWidthOffset
        )
    }

    // MARK: - Reset

    func endDrag() {
        dragStartLocation = nil
        dragStartRoadWidthOffset = nil
    }
}

private extension CGVector {

    // MARK: - Vector Math

    /// Dot product tells us how much one vector points in another vector's direction.
    func dot(_ other: CGVector) -> CGFloat {
        dx * other.dx + dy * other.dy
    }
}
