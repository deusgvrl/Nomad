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
    
    /// Returns a list of hitbox shapes for each obstacle type.
    var hitboxShapes: [HitboxShape] {
        switch self {
        case .smallRock:
            return [
                HitboxShape(size: CGSize(width: 42, height: 25), offset: CGPoint(x: -8, y: 21), angle: -0.08),
                HitboxShape(size: CGSize(width: 34, height: 5), offset: CGPoint(x: 20, y: 22), angle: 1.05)
            ]
        case .mediumRock:
            return [
                HitboxShape(size: CGSize(width: 80, height: 11), offset: CGPoint(x: -2, y: 28), angle: 0),
                HitboxShape(size: CGSize(width: 28, height: 5), offset: CGPoint(x: 15, y: 10), angle: -0.07),
                HitboxShape(size: CGSize(width: 28, height: 5), offset: CGPoint(x: -20, y: 17), angle: -0.1),
                HitboxShape(size: CGSize(width: 24, height: 5), offset: CGPoint(x: 34, y: 20), angle: 1.03)
            ]
        case .largeRock:
            return [
                HitboxShape(size: CGSize(width: 55, height: 35), offset: CGPoint(x: -5, y: 20), angle: 0),
                HitboxShape(size: CGSize(width: 50, height: 5), offset: CGPoint(x: -6, y: 1), angle: -0.11),
                HitboxShape(size: CGSize(width: 32, height: 5), offset: CGPoint(x: 24, y: 10), angle: 1.03),
                HitboxShape(size: CGSize(width: 5, height: 2), offset: CGPoint(x: 32, y: 23), angle: 0)
            ]
        case .tree1:
            return [HitboxShape(size: CGSize(width: 13, height: 25), offset: CGPoint(x: 7, y: 8), angle: 0)]
        case .tree2:
            return [HitboxShape(size: CGSize(width: 6, height: 20), offset: CGPoint(x: -5, y: 5), angle: 0)]
        case .cactus1:
            return [
                HitboxShape(size: CGSize(width: 44, height: 25), offset: CGPoint(x: 1, y: 15), angle: 0),
                HitboxShape(size: CGSize(width: 15, height: 5), offset: CGPoint(x: -3, y: -9), angle: 0),
                HitboxShape(size: CGSize(width: 17, height: 5), offset: CGPoint(x: 15, y: -2), angle: 0.05)


                
            ]
        case .cactus2:
            return [
                HitboxShape(size: CGSize(width: 34, height: 25), offset: CGPoint(x: -6, y: 12), angle: 0),
                HitboxShape(size: CGSize(width: 20, height: 5), offset: CGPoint(x: 2, y: -8), angle: 0),
            ]
        }
    }
}
