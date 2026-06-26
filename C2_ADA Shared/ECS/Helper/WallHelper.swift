//
//  EnumHelper.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 15/05/26.
//

import Foundation

enum WallSide {
    case left
    case right
    
    var imageName: String {
        switch self{
        case .left: return "WALL KIRI"
        case .right: return "WALL KANAN"
        }
    }
}
