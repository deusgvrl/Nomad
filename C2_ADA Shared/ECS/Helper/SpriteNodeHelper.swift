//
//  SpriteNodeHelper.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 20/05/26.
//

import SpriteKit

// Helper untuk manipulasi SKSpriteNode
enum SpriteNodeHelper {

    // Mengubah ukuran node berdasarkan lebar sambil menjaga proporsi asli.
    // Cara kerja: Menghitung rasio (tinggi/lebar) tekstur asli, 
    // lalu mengalikan lebar baru dengan rasio tersebut untuk mendapat tinggi yang proporsional.
    static func resize(
        node: SKSpriteNode,
        width: CGFloat
    ) {

        guard let texture = node.texture else {
            return
        }

        let aspectRatio =
        texture.size().height / texture.size().width

        node.size = CGSize(
            width: width,
            height: width * aspectRatio
        )
    }
}
