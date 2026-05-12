//
//  RowNode.swift
//  C2_ADA iOS
//
//  Created by Deny Wahyudi Asaloei  on 12/05/26.
//

import Foundation
import SpriteKit

class RowNode: SKNode {
    let rowIndex: Int //index baris ke berapa
    let colCount: Int //berapa tile per baris
    
    init(rowIndex: Int, colCount: Int) {
        self.rowIndex = rowIndex
        self.colCount = colCount
        super.init()
        
        // Generate row
        for col in 0..<colCount {
            let tile = FloorNode(row: rowIndex, col: col)
            addChild(tile)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
