//
//  ObstacleHelper.swift
//  C2_ADA iOS
//
//  Created by Howie Homan on 13/05/26.
//

import CoreGraphics

enum ObstacleType: String, CaseIterable {
    case smallRock = "OBSTACLE 1"
    case mediumRock = "OBSTACLE 2"
    case largeRock = "OBSTACLE 3"
    case tree1 = "OBSTACLE 4"
    case tree2 = "OBSTACLE 5"
    case cactus1 = "OBSTACLE 6"
    case cactus2 = "OBSTACLE 7"
    
    /// Specific hitbox size for each obstacle type.
    var hitboxSize: CGSize {
        switch self {
        case .smallRock: return CGSize(width: 45, height: 25)
        case .mediumRock: return CGSize(width: 78, height: 15)
        case .largeRock: return CGSize(width: 55, height: 35)
        case .tree1: return CGSize(width: 13, height: 25)
        case .tree2: return CGSize(width: 6, height: 20)
        case .cactus1: return CGSize(width: 44, height: 25)
        case .cactus2: return CGSize(width: 34, height: 25)
        }
    }
    
    /// Specific offset (X and Y) for the hitbox to align with the visual base of each asset.
    var hitboxOffset: CGPoint {
        switch self {
        case .smallRock:
            return CGPoint(x: -6, y: 23)
        case .mediumRock:
            return CGPoint(x: 0, y: 28)
        case .largeRock:
            return CGPoint(x: -5, y: 20)
        case .tree1:
            return CGPoint(x: 7, y: 8)
        case .tree2:
            return CGPoint(x: -5, y: 5)
        case .cactus1:
            return CGPoint(x: 1, y: 15)
        case .cactus2:
            return CGPoint(x: -6, y: 12)
        }
    }
}
