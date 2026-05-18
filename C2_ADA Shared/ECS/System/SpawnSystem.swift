//
//  SpawnSystem.swift
//  C2_ADA iOS
//
//  Created by Derick Norlan on 12/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

/// Sistem utama yang mengatur:
/// - Movement row isometric
/// - Recycling row
/// - Spawn obstacle dan vehicle
class SpawnSystem {

    // MARK: - Core Properties
    
    /// Parent node tempat seluruh row ditampilkan
    private let worldNode: SKNode
    
    /// Ukuran scene game
    private let sceneSize: CGSize
    
    /// Menyimpan waktu frame sebelumnya
    /// Digunakan untuk menghitung deltaTime
    private var lastUpdateTime: TimeInterval = 0
    
    /// Menyimpan entity row untuk logic movement
    private var rowEntities: [RowEntity] = []
    
    /// Menyimpan visual row yang tampil di scene
    private var rowNodes: [RowNode] = []
    private(set) var vehicleEntities: [VehicleEntity] = []

    // MARK: - Grid Configuration
    
    /// Total row aktif yang dirender
    private let totalRows: Int = 25
    
    /// Total kolom tile dalam satu row
    private let colCount: Int = 20

    // MARK: - Movement
    
    /// Kecepatan movement diagonal row
    private let moveSpeed: CGFloat = 150

    // MARK: - Obstacle
    
    /// Menghitung jumlah row sejak obstacle terakhir spawn
    private var rowsSinceLastObstacle: Int = 0
    
    /// Minimal jarak aman antar obstacle
    /// agar player masih memiliki ruang bergerak
    private let minSafeRows = 4
    
    /// Maksimal jumlah row kosong berturut-turut
    /// Digunakan untuk mencegah layar terlalu kosong
    private let maxEmptyRows = 6
    
    /// Peluang obstacle untuk spawn
    private let spawnChance = 0.8
    
    /// Menyimpan posisi kolom obstacle terakhir
    private var lastObstacleCol: Int = -1
    
    /// Menyimpan pola obstacle sebelumnya
    /// Digunakan untuk mencegah pola spawn monoton
    private var lastObstacleSum: Int = -1

    // MARK: - Vehicle Spawning Rules
    
    /// Menghitung jumlah row sejak vehicle terakhir spawn
    private var rowsSinceLastVehicle: Int = 0
    
    /// Minimal jarak row antar vehicle
    private let minRowsBetweenVehicles: Int = 5
    
    /// Maksimal jarak row antar vehicle
    private let maxRowsBetweenVehicles: Int = 10
    
    /// Target row berikutnya untuk spawn vehicle
    /// Nilai akan diacak ulang setelah vehicle berhasil spawn
    private var nextVehicleRowTarget: Int = 6
    
    /// Menyimpan posisi kolom vehicle terakhir
    private var lastVehicleCol: Int = 10
    
    /// Menyimpan posisi kolom vehicle sebelumnya
    /// Digunakan untuk menghindari pola spawn berulang
    private var previousVehicleCol: Int = -1
    
    /// Maksimal perpindahan kolom vehicle
    /// Agar tetap dapat dijangkau player
    private let maxColJumpRange: Int = 4
    
    // MARK: - Wall Data
    private let totalWallChunks = 12
    private var leftWallEntities: [WallEntity] = []
    private var leftWallNodes: [WallNode] = []
    private var rightWallEntities: [WallEntity] = []
    private var rightWallNodes: [WallNode] = []
    
    // Jarak sambungan antar chunk (Dibuat lebih rapat agar overlap)
    private let chunkOffsetX:CGFloat = 176
    private let chunkOffsetY:CGFloat = 304
    
    /// Inisialisasi sistem spawn
    ///
    /// - Parameters:
    ///   - worldNode: Parent node untuk seluruh row
    ///   - sceneSize: Ukuran scene game
    init(worldNode: SKNode, sceneSize: CGSize) {
        self.worldNode = worldNode
        self.sceneSize = sceneSize

        setupInitialRows()
        setupInitialWalls()
    }
}

// MARK: - Initial Setup

extension SpawnSystem {
    
    /// Membuat seluruh row awal
    /// dan menyusunnya secara diagonal isometric
    private func setupInitialRows() {

        let tileWidth = IsometricHelper.tileWidth
        let tileHeight = IsometricHelper.tileHeight

        for index in 0..<totalRows {
            
            /// Entity untuk movement logic
            let entity = RowEntity(speed: moveSpeed)
            
            /// Visual row
            let rowNode = RowNode(
                rowIndex: 0,
                colCount: colCount
            )
            
            /// Posisi diagonal isometric
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
    
    /// Dipanggil setiap frame dari GameScene
    ///
    /// - Parameter currentTime: Waktu frame saat ini
    func update(_ currentTime: TimeInterval) {

        let deltaTime: TimeInterval
        
        /// Frame pertama tidak memiliki deltaTime
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = currentTime - lastUpdateTime
        }
        
        /// Simpan waktu frame sekarang
        lastUpdateTime = currentTime
        
        /// Update movement dan recycle row
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
    
    /// Mengecek apakah row paling depan
    /// sudah keluar layar dan perlu didaur ulang
    private func recycleRowsIfNeeded() {

        guard let firstRow = rowNodes.first,
              let lastRow = rowNodes.last else {
            return
        }
        
        /// Threshold saat row dianggap keluar layar
        let thresholdY = -IsometricHelper.tileHeight

        if firstRow.position.y < thresholdY {

            let tileWidth = IsometricHelper.tileWidth
            let tileHeight = IsometricHelper.tileHeight
            
            /// Pindahkan row ke posisi paling belakang
            firstRow.position = CGPoint(
                x: lastRow.position.x + (tileWidth / 2),
                y: lastRow.position.y + (tileHeight / 2)
            )
            
            /// Hapus seluruh obstacle dan vehicle lama
            /// agar tidak menumpuk saat row digunakan kembali

            firstRow.children.forEach { child in
                if child.name == "vehicle" {
                    vehicleEntities.removeAll { entity in
                        entity.node === child
                    }
                    child.removeFromParent()
                } else if child.name == "obstacle" {
                    child.removeFromParent()
                }

            }
//            firstRow.children.forEach { child in
//                if child.name == "obstacle" || child.name == "vehicle" {
//                    child.removeFromParent()
//                }
//            }
            
            /// Spawn obstacle atau vehicle baru
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
    
    /// Mengatur logic spawn obstacle dan vehicle
    ///
    /// Prioritas:
    /// 1. Spawn vehicle jika target row tercapai
    /// 2. Spawn obstacle jika memenuhi aturan spawn
    ///
    /// - Parameter rowNode: Row target spawn
    private func trySpawnObstacle(on rowNode: RowNode) {

        rowsSinceLastObstacle += 1
        rowsSinceLastVehicle += 1
        
        /// Cek apakah vehicle sudah waktunya spawn
        if rowsSinceLastVehicle >= nextVehicleRowTarget {
            
            spawnVehicle(on: rowNode)
            
            /// Reset counter setelah vehicle spawn
            rowsSinceLastVehicle = 0
            rowsSinceLastObstacle = 0
            
            /// Acak target row vehicle berikutnya
            nextVehicleRowTarget = Int.random(
                in: minRowsBetweenVehicles...maxRowsBetweenVehicles
            )
            
            return
        }
        
        /// Cek apakah obstacle boleh spawn
        if rowsSinceLastObstacle >= minSafeRows {
            
            /// Paksa spawn obstacle jika terlalu banyak row kosong
            let effectiveChance =
                rowsSinceLastObstacle >= maxEmptyRows
                ? 1.0
                : spawnChance
            
            if Double.random(in: 0...1) < effectiveChance {
                
                spawnObstacle(on: rowNode)
                
                /// Reset counter obstacle
                rowsSinceLastObstacle = 0
            }
        }
    }
    
    /// Spawn vehicle baru
    ///
    /// - Parameter rowNode: Row target spawn
    private func spawnVehicle(on rowNode: RowNode) {
        
        let vehicle = VehicleNode(type: .car)
        
        vehicle.name = "vehicle"
        
        let absoluteMin = 5
        let absoluteMax = colCount - 8
        
        /// Mengambil seluruh kolom valid untuk vehicle
        let allowedCols = Array(absoluteMin...absoluteMax).filter { col in
            
            /// Pattern jalur vehicle
            let isPatternMatch = (col - absoluteMin) % 2 == 0
            
            /// Membatasi perpindahan vehicle
            let isInJumpRange =
                abs(col - lastVehicleCol) <= maxColJumpRange
            
            /// Hindari spawn di posisi vehicle sebelumnya
            let isNotSameAsLastVehicle =
                col != lastVehicleCol
            
            /// Hindari pola bolak-balik
            let isNotSameAsPreviousVehicle =
                col != previousVehicleCol
            
            /// Hindari tabrakan dengan obstacle
            let isNotSameAsObstacle =
                col != lastObstacleCol
            
            return isPatternMatch
            && isInJumpRange
            && isNotSameAsLastVehicle
            && isNotSameAsPreviousVehicle
            && isNotSameAsObstacle
        }
        
        /// Pilih kolom random yang valid
        let randomCol = allowedCols.randomElement() ??
                       Array(absoluteMin...absoluteMax)
                        .filter { ($0 - absoluteMin) % 2 == 0 }
                        .randomElement() ??
                       absoluteMin
        
        /// Posisi vehicle di grid isometric
        vehicle.position = IsometricHelper.getScreenPosition(
            row: 0,
            col: randomCol
        )
        
        vehicle.zPosition = 100
        
        let vehicleEntity = VehicleEntity(node: vehicle)
        vehicleEntities.append(vehicleEntity)
        
        rowNode.addChild(vehicle)
        
        /// Simpan histori vehicle
        previousVehicleCol = lastVehicleCol
        lastVehicleCol = randomCol
    }
    
    /// Spawn obstacle baru
    ///
    /// - Parameter rowNode: Row target spawn
    private func spawnObstacle(on rowNode: RowNode) {
        
        let absoluteMin = 5
        let absoluteMax = colCount - 8
        
        /// Mengambil seluruh kolom valid untuk obstacle
        let allowedCols = Array(absoluteMin...absoluteMax).filter { col in
            
            /// Jarak aman dari obstacle sebelumnya
            let isFarFromLastObstacle =
                abs(col - lastObstacleCol) >= 3
            
            /// Jarak aman dari vehicle
            let isFarFromVehicle =
                abs(col - lastVehicleCol) >= 4
            
            /// Hindari pola obstacle monoton
            let isDifferentPattern =
                (rowNode.rowIndex + col) != lastObstacleSum
            
            return isFarFromLastObstacle
            && isFarFromVehicle
            && isDifferentPattern
        }
        
        if let randomCol = allowedCols.randomElement() {
            
            /// Random tipe obstacle
            let randomType =
                ObstacleType.allCases.randomElement()
                ?? .small
            
            let obstacle = ObstacleNode(type: randomType)
            
            obstacle.name = "obstacle"
            
            /// Posisi obstacle di grid isometric
            obstacle.position = IsometricHelper.getScreenPosition(
                row: 0,
                col: randomCol
            )
            
            obstacle.zPosition = 100
            
            rowNode.addChild(obstacle)
            
            /// Simpan histori obstacle
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

// MARK: - Vehicle Adoption
extension SpawnSystem{
    
    func adopt(oldVehicle: VehicleEntity) {
        guard let targetRow = rowNodes.first, let scene = oldVehicle.node.scene else { return }
        
        let scenePos = oldVehicle.node.parent?.convert(oldVehicle.node.position, to: scene) ?? oldVehicle.node.position
        
        oldVehicle.node.removeFromParent()
        oldVehicle.node.position = scene.convert(scenePos, to: targetRow)
        targetRow.addChild(oldVehicle.node)
        
        vehicleEntities.append(oldVehicle)
        
        oldVehicle.node.zPosition = 100
    }

}
