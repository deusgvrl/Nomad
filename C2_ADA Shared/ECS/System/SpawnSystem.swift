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
    private var RowEntities: [RowEntity] = []
    
    /// Menyimpan visual row yang tampil di scene
    private var rowNodes: [RowNode] = []
    
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
    
    // MARK: - Initialization
    
    /// Inisialisasi sistem spawn
    ///
    /// - Parameters:
    ///   - worldNode: Parent node untuk seluruh row
    ///   - sceneSize: Ukuran scene game
    init(worldNode: SKNode, sceneSize: CGSize) {
        self.worldNode = worldNode
        self.sceneSize = sceneSize
        
        setupInitialRows()
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
            
            /// Simpan entity dan row
            RowEntities.append(entity)
            rowNodes.append(rowNode)
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
    }
}

// MARK: - Row Movement

extension SpawnSystem {
    
    /// Menggerakkan seluruh row secara diagonal
    ///
    /// - Parameter deltaTime: Selisih waktu antar frame
    private func moveRows(deltaTime: TimeInterval) {
        
        for (index, entity) in RowEntities.enumerated() {
            
            guard let movementComponent =
                    entity.component(ofType: MovementComponent.self)
            else {
                continue
            }
            
            let rowNode = rowNodes[index]
            
            let speed = movementComponent.speed
            
            /// Movement vertikal
            let dy = speed * CGFloat(deltaTime)
            
            /// Menyesuaikan movement horizontal
            /// agar tetap sejajar tile isometric
            let dx = dy * (
                IsometricHelper.tileWidth /
                IsometricHelper.tileHeight
            )
            
            /// Gerakan diagonal kiri bawah
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
                if child.name == "obstacle" || child.name == "vehicle" {
                    child.removeFromParent()
                }
            }
            
            /// Spawn obstacle atau vehicle baru
            trySpawnObstacle(on: firstRow)
            
            /// Update urutan queue row
            rowNodes.removeFirst()
            rowNodes.append(firstRow)
            
            /// Update urutan queue entity
            let firstEntity = RowEntities.removeFirst()
            RowEntities.append(firstEntity)
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
