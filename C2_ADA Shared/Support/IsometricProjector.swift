//
//  IsometricProjector.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import Foundation

struct IsometricProjector {

    let viewAngleInDegrees: CGFloat

    func project(horizontalOffset: CGFloat, depthOffset: CGFloat, from origin: CGPoint) -> CGPoint {
        let radians = Double(viewAngleInDegrees) * Double.pi / 180
        return CGPoint(
            x: origin.x + horizontalOffset + depthOffset * CGFloat(cos(radians)),
            y: origin.y + depthOffset * CGFloat(sin(radians))
        )
    }
}
