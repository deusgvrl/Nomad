//
//  GameConfiguration.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation

struct GameConfiguration {

    static let standard = GameConfiguration(
        referenceScreenSize: CGSize(width: 402, height: 874),
        playableWidthFraction: 1.0 / 3.0,
        isometricViewAngleInDegrees: 60,
        dragSensitivity: 1.0,
        roadStartCenterPosition: CGPoint(x: -95, y: -370),
        roadWidth: 260,
        roadDepth: 680,
        rideDepthOffset: 190,
        currentVehiclePosition: CGPoint(x: -115, y: -245),
        nextVehiclePosition: CGPoint(x: -45, y: -45),
        obstaclePositions: [
            CGPoint(x: 45, y: 125),
            CGPoint(x: 130, y: -20),
            CGPoint(x: -95, y: -360)
        ],
        vehicleXBounds: -165...25,
        playerRideOffset: CGVector(dx: -8, dy: 42),
        vehicleSize: CGSize(width: 62, height: 112),
        playerSize: CGSize(width: 19, height: 19),
        obstacleSize: CGSize(width: 36, height: 92),
        launchVelocity: 360,
        launchGravity: 920,
        jumpTravelDuration: 0.65,
        latchDistance: 52,
        groundYPosition: -345,
        maximumDeltaTime: 1.0 / 30.0
    )

    let referenceScreenSize: CGSize
    let playableWidthFraction: CGFloat
    let isometricViewAngleInDegrees: CGFloat
    let dragSensitivity: CGFloat
    let roadStartCenterPosition: CGPoint
    let roadWidth: CGFloat
    let roadDepth: CGFloat
    let rideDepthOffset: CGFloat
    let currentVehiclePosition: CGPoint
    let nextVehiclePosition: CGPoint
    let obstaclePositions: [CGPoint]
    let vehicleXBounds: ClosedRange<CGFloat>
    let playerRideOffset: CGVector
    let vehicleSize: CGSize
    let playerSize: CGSize
    let obstacleSize: CGSize
    let launchVelocity: CGFloat
    let launchGravity: CGFloat
    let jumpTravelDuration: TimeInterval
    let latchDistance: CGFloat
    let groundYPosition: CGFloat
    let maximumDeltaTime: TimeInterval

    var playableXBounds: ClosedRange<CGFloat> {
        let halfPlayableWidth = referenceScreenSize.width * playableWidthFraction / 2
        return -halfPlayableWidth...halfPlayableWidth
    }

    var rideAnchorPosition: CGPoint {
        let radians = Double(isometricViewAngleInDegrees) * Double.pi / 180
        return CGPoint(
            x: roadStartCenterPosition.x + rideDepthOffset * CGFloat(cos(radians)),
            y: roadStartCenterPosition.y + rideDepthOffset * CGFloat(sin(radians))
        )
    }
}
