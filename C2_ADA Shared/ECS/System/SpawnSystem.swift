//
//  SpawnSystem.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

class SpawnSystem {

    // MARK: - Core Properties

    // Container utama untuk semua row
    private let worldNode: SKNode

    // Ukuran scene game
    private let sceneSize: CGSize

    // Menyimpan waktu frame sebelumnya
    private var lastUpdateTime: TimeInterval = 0

    // Data entity dan visual row
    private var RowEntities: [RowEntity] = []
    private var rowNodes: [RowNode] = []

    // MARK: - Grid Configuration

    // Jumlah row dan kolom aktif
    private let totalRows: Int = 25
    private let colCount: Int = 20

    // MARK: - Movement

    // Kecepatan movement row
    private let moveSpeed: CGFloat = 150

    // MARK: - Obstacle

    // Menghitung jarak row kosong antar obstacle
    private var rowsSinceLastObstacle: Int = 0

    // Minimal row aman
    private let minSafeRows = 5

    // Peluang obstacle spawn
    private let spawnChance = 0.7

    // Menyimpan posisi obstacle sebelumnya
    private var lastObstacleCol: Int = -1

    // Mencegah pola obstacle monoton
    private var lastObstacleSum: Int = -1

    // MARK: - Initialization

    init(worldNode: SKNode, sceneSize: CGSize) {
        self.worldNode = worldNode
        self.sceneSize = sceneSize

        setupInitialRows()
    }
}

// MARK: - Initial Setup

extension SpawnSystem {

    private func setupInitialRows() {

        let tileWidth = IsometricHelper.tileWidth
        let tileHeight = IsometricHelper.tileHeight

        for index in 0..<totalRows {

            // Entity movement
            let entity = RowEntity(speed: moveSpeed)
            
            // Visual row
            let rowNode = RowNode(
                rowIndex: 0,
                colCount: colCount
            )

            // Posisi diagonal isometric
            rowNode.position = CGPoint(
                x: CGFloat(index) * (tileWidth / 2),
                y: CGFloat(index) * (tileHeight / 2)
            )

            worldNode.addChild(rowNode)

            // Simpan data
            RowEntities.append(entity)
            rowNodes.append(rowNode)
        }
    }
}

// MARK: - Update Loop

extension SpawnSystem {

    func update(_ currentTime: TimeInterval) {

        let deltaTime: TimeInterval

        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = currentTime - lastUpdateTime
        }

        lastUpdateTime = currentTime

        moveRows(deltaTime: deltaTime)
        recycleRowsIfNeeded()
    }
}

// MARK: - Row Movement

extension SpawnSystem {

    private func moveRows(deltaTime: TimeInterval) {
        
        for (index, entity) in RowEntities.enumerated() {
            guard let movementComponent =
                    entity.component(ofType: MovementComponent.self)
            else {
                continue
            }

            let rowNode = rowNodes[index]

            let speed = movementComponent.speed

            // Movement vertikal
            let dy = speed * CGFloat(deltaTime)

            // Menyesuaikan movement horizontal
            // agar tetap sejajar tile isometric
            let dx = dy * (
                IsometricHelper.tileWidth /
                IsometricHelper.tileHeight
            )

            // Gerakan diagonal kiri bawah
            rowNode.position.x -= dx
            rowNode.position.y -= dy
        }
    }
}

// MARK: - Row Recycling

extension SpawnSystem {

    private func recycleRowsIfNeeded() {

        guard let firstRow = rowNodes.first,
              let lastRow = rowNodes.last else {
            return
        }

        // Threshold saat row keluar layar
        let thresholdY = -IsometricHelper.tileHeight

        if firstRow.position.y < thresholdY {

            let tileWidth = IsometricHelper.tileWidth
            let tileHeight = IsometricHelper.tileHeight

            // Pindahkan row ke posisi paling atas
            firstRow.position = CGPoint(
                x: lastRow.position.x + (tileWidth / 2),
                y: lastRow.position.y + (tileHeight / 2)
            )
            
            // Hapus SEMUA rintangan atau kendaraan lama di baris ini agar tidak menumpuk
            firstRow.children.forEach { child in
                if child.name == "obstacle" || child.name == "vehicle" {
                    child.removeFromParent()
                }
            }
            
            // Spawn rintangan baru (statis atau kendaraan)
            trySpawnObstacle(on: firstRow)

            // Update urutan queue
            rowNodes.removeFirst()
            rowNodes.append(firstRow)
            
            let firstEntity = RowEntities.removeFirst()
            RowEntities.append(firstEntity)
        }
    }
}

// MARK: - Obstacle & Vehicle Spawn

extension SpawnSystem {

    private func trySpawnObstacle(on rowNode: RowNode) {

        rowsSinceLastObstacle += 1
        
        // Pastikan ada jarak aman antar rintangan
        if rowsSinceLastObstacle >= minSafeRows {
            
            // Peluang spawn rintangan
            if Double.random(in: 0...1) < spawnChance {
                
                // Tentukan tipe: 30% peluang Vehicle, 70% Static Obstacle
                if Double.random(in: 0...1) < 0.3 {
                    spawnVehicle(on: rowNode)
                } else {
                    spawnObstacle(on: rowNode)
                }
                
                // Reset counter
                rowsSinceLastObstacle = 0
            }
        }
    }
    
    private func spawnVehicle(on rowNode: RowNode) {
        // Catatan: Pastikan VehicleNode sudah terdefinisi di proyek Anda
         let vehicle = VehicleNode(type: .car)
         vehicle.name = "vehicle"
        
        // Pilih kolom acak di area tengah yang aman
         let randomCol = Int.random(in: 4...(colCount - 5))
         vehicle.position = IsometricHelper.getScreenPosition(row: 0, col: randomCol)
         vehicle.zPosition = 100
        
         rowNode.addChild(vehicle)
    }
    
    private func spawnObstacle(on rowNode: RowNode) {
        // Area spawn aman
        let allowedCols = Array(4...(colCount - 5)).filter { col in
            // Hindari obstacle terlalu dekat
            let isFarEnough = abs(col - lastObstacleCol) >= 3
            // Hindari pola obstacle monoton
            let isDifferentPattern = (rowNode.rowIndex + col) != lastObstacleSum
            
            return isFarEnough && isDifferentPattern
        }
        
        // Ambil kolom random valid
        if let randomCol = allowedCols.randomElement() {
            let randomType = ObstacleType.allCases.randomElement() ?? .small
            let obstacle = ObstacleNode(type: randomType)
            
            obstacle.name = "obstacle"
            obstacle.position = IsometricHelper.getScreenPosition(row: 0, col: randomCol)
            obstacle.zPosition = 100
            
            rowNode.addChild(obstacle)
            
            // Simpan histori obstacle
            lastObstacleCol = randomCol
            lastObstacleSum = rowNode.rowIndex + randomCol
        }
    }
}
