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
    private var rowEntities: [RowEntity] = []
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
    
    // MARK: - Wall Data
    private let totalWallChunks = 12
    private var leftWallEntities: [WallEntity] = []
    private var leftWallNodes: [WallNode] = []
    private var rightWallEntities: [WallEntity] = []
    private var rightWallNodes: [WallNode] = []
    
    // Jarak sambungan antar chunk (Dibuat lebih rapat agar overlap)
    private let chunkOffsetX:CGFloat = 176
    private let chunkOffsetY:CGFloat = 304
    
    // MARK: - Initialization

    init(worldNode: SKNode, sceneSize: CGSize) {
        self.worldNode = worldNode
        self.sceneSize = sceneSize

        setupInitialRows()
        setupInitialWalls()
    }
}

// MARK: - Initial Setup

extension SpawnSystem {
    // TODO: Setup Row
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
            rowEntities.append(entity)
            rowNodes.append(rowNode)
        }
    }
    
    //TODO: Setup Wall
    private func setupInitialWalls(){
        for index in 0..<totalWallChunks {
            //WALL KIRI
            let leftEntity = WallEntity(speed: moveSpeed)
            let leftNode = WallNode(side: .left)
            
            // Posisi Chunk Kiri
            let leftBaseX: CGFloat = -150
            let leftBaseY: CGFloat = 780
            
            // zPosition dinamis: Makin atas (index besar) makin kecil z-nya agar di belakang
            leftNode.zPosition = CGFloat(100 - index)
            
            leftNode.position = CGPoint(
                x: leftBaseX + (CGFloat(index) * chunkOffsetX),
                y: leftBaseY + (CGFloat(index) * chunkOffsetY)
            )
            worldNode.addChild(leftNode)
            leftWallEntities.append(leftEntity)
            leftWallNodes.append(leftNode)
            
            
            // --- WALL KANAN ---
            let rightEntity = WallEntity(speed: moveSpeed)
            let rightNode = WallNode(side: .right)
            
            // Posisi Chunk Kanan
            let rightBaseX: CGFloat = 100
            let rightBaseY: CGFloat = -50
            
            // zPosition dinamis
            rightNode.zPosition = CGFloat(100 - index)
            
            rightNode.position = CGPoint(
                x: rightBaseX + (CGFloat(index) * chunkOffsetX),
                y: rightBaseY + (CGFloat(index) * chunkOffsetY)
            )
            worldNode.addChild(rightNode)
            rightWallEntities.append(rightEntity)
            rightWallNodes.append(rightNode)
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
        
        moveWall(deltaTime: deltaTime)
        recycleWalls()
    }
}

// MARK: - Row Movement

extension SpawnSystem {

    private func moveRows(deltaTime: TimeInterval) {
        
        for (index, entity) in rowEntities.enumerated() {
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
            
            let firstEntity = rowEntities.removeFirst()
            rowEntities.append(firstEntity)
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
        let randomCol = Int.random(in: 5...(colCount - 8))
        vehicle.position = IsometricHelper.getScreenPosition(row: 0, col: randomCol)
        vehicle.zPosition = 100
        
        rowNode.addChild(vehicle)
    }
    
    private func spawnObstacle(on rowNode: RowNode) {
        // Area spawn aman
        let allowedCols = Array(5...(colCount - 8)).filter { col in
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

//MARK: -  Wall Movement & Recycling
extension SpawnSystem{
    //Movement
    private func moveWall(deltaTime: TimeInterval) {
        // Karena kecepatan sama, kita hitung dx dan dy sekali saja
        let dy = moveSpeed * CGFloat(deltaTime)
        let dx = dy * (IsometricHelper.tileWidth / IsometricHelper.tileHeight)
        
        // Gerakkan wall kiri
        for node in leftWallNodes {
            node.position.x -= dx
            node.position.y -= dy
        }
        
        // Gerakkan wall kanan
        for node in rightWallNodes {
            node.position.x -= dx
            node.position.y -= dy
        }
    }
    
    //Recycling
    private func recycleWalls() {
        // Threshold bisa disesuaikan dengan tinggi asli tekstur wall-nya
        let wallThresholdY: CGFloat = -1000
        
        // Recycle Kiri
        if let firstLeft = leftWallNodes.first, let lastLeft = leftWallNodes.last {
            if firstLeft.position.y < wallThresholdY {
                // Pindahkan posisi chunk paling bawah ke atas (menyambung chunk paling atas)
                firstLeft.position = CGPoint(
                    x: lastLeft.position.x + chunkOffsetX,
                    y: lastLeft.position.y + chunkOffsetY
                )
                
                // Pindahkan data dari depan ke belakang array (Looping)
                leftWallNodes.removeFirst()
                leftWallNodes.append(firstLeft)
                
                let firstEntity = leftWallEntities.removeFirst()
                leftWallEntities.append(firstEntity)
                
                // RESET SEMUA Z-POSITION (Solusi agar tidak hilang tenggelam)
                for (index, node) in leftWallNodes.enumerated() {
                    node.zPosition = CGFloat(150 - index)
                }
            }
        }
        
        // Recycle Kanan
        if let firstRight = rightWallNodes.first, let lastRight = rightWallNodes.last {
            if firstRight.position.y < wallThresholdY {
                // Pindahkan posisi
                firstRight.position = CGPoint(
                    x: lastRight.position.x + chunkOffsetX,
                    y: lastRight.position.y + chunkOffsetY
                )
                
                // Looping data
                rightWallNodes.removeFirst()
                rightWallNodes.append(firstRight)
                
                let firstEntity = rightWallEntities.removeFirst()
                rightWallEntities.append(firstEntity)
                
                // RESET SEMUA Z-POSITION (Solusi agar tidak hilang tenggelam)
                for (index, node) in rightWallNodes.enumerated() {
                    node.zPosition = CGFloat(150 - index)
                }
            }
        }
    }
}

