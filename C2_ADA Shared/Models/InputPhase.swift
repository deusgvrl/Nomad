//
//  InputPhase.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics

enum InputPhase {
    case idle
    case holding(startLocation: CGPoint)
    case dragging(startLocation: CGPoint, currentLocation: CGPoint, translation: CGVector)
    case released(releaseLocation: CGPoint)
}
