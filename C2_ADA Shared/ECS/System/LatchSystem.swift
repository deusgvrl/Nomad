//
//  LatchSystem.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 07/05/26.
//

import CoreGraphics
import SpriteKit

//// MARK: - Latch System
//
///// Checks whether an airborne player can attach back onto a vehicle.
/////
///// For this first backend version, latching uses frame intersection with a
///// generous inset. Later, this can become a more precise latch zone on the
///// vehicle sprite.
//final class LatchSystem {
//
//    // MARK: - Dependencies
//
//    private let configuration: GameConfiguration
//
//    init(configuration: GameConfiguration) {
//        self.configuration = configuration
//    }
//
//    // MARK: - Latch Attempt
//
//    func attemptLatch(player: PlayerEntity, onto vehicles: [VehicleEntity]) -> VehicleEntity? {
//        
//        for vehicle in vehicles {
//            if canLatch(player: player, onto: vehicle) {
//                player.attach(to: vehicle)
//                return vehicle
//            }
//        }
////        guard canLatch(player: player, onto: vehicle) else { return false }
////
////        player.attach(to: vehicle)
////        return true
//        return nil
//    }
//
//    // MARK: - Latch Detection
//
//    func canLatch(player: PlayerEntity, onto vehicle: VehicleEntity) -> Bool {
//        guard let scene = player.node.scene else { return false }
//        let playerSceneFrame = player.node.parent?.convert(player.node.calculateAccumulatedFrame(), to: scene) ?? .zero
//        let vehicleSceneFrame = vehicle.node.parent?.convert(vehicle.node.calculateAccumulatedFrame(), to: scene) ?? .zero
//        
//        let activeVehicleHitbox = vehicleSceneFrame.insetBy(dx: -configuration.latchDistance, dy: -configuration.latchDistance)
//        
//        let isAhead = vehicleSceneFrame.midY > playerSceneFrame.minY
//        let isVisible = vehicleSceneFrame.midY > -scene.size.height / 2
//        
//        return playerSceneFrame.intersects(activeVehicleHitbox) && isAhead && isVisible
//        
//        
////        let localPlayerFrame = player.node.calculateAccumulatedFrame()
////        let localVehicleFrame = vehicle.node.calculateAccumulatedFrame().insetBy(dx: -configuration.latchDistance, dy: -configuration.latchDistance)
////        
////        guard let playerParent = player.node.parent,
////              let vehicleParent = vehicle.node.parent,
////              playerParent !== vehicleParent else {
////            return localPlayerFrame.intersects(localVehicleFrame)
////        }
////    
////        
////        let convertedVehicleFrame = vehicleParent.convert(localVehicleFrame, to: playerParent)
//        //        return localPlayerFrame.intersects(convertedVehicleFrame)
//        
//        
////        let playerFrame = player.node.calculateAccumulatedFrame()
////        // Expanding the vehicle frame makes early prototype latching more forgiving.
////        let vehicleFrame = vehicle.node.calculateAccumulatedFrame().insetBy(
////            dx: -configuration.latchDistance,
////            dy: -configuration.latchDistance
////        )
//
//
//    }
//}



final class LatchSystem {
    
    // MARK: - Dependencies
    private let configuration: GameConfiguration
    
    init(configuration: GameConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Latch Attempt
    
    func attemptLatch(player: PlayerEntity, onto vehicles: [VehicleEntity]) -> VehicleEntity? {
        var validTargets: [(vehicle: VehicleEntity, distance: CGFloat)] = []
        
        for vehicle in vehicles {
            let evaluation = evaluateTarget(player: player, vehicle: vehicle)
            if evaluation.isValid {
                validTargets.append((vehicle: vehicle, distance: evaluation.distance))
            }
        }
        
        validTargets.sort { $0.distance < $1.distance }
        
        if let bestTarget = validTargets.first?.vehicle {
            player.attach(to: bestTarget)
            return bestTarget
        }
        
        return nil
    }
    
    private func evaluateTarget(player: PlayerEntity, vehicle: VehicleEntity) -> (isValid: Bool, distance: CGFloat) {
        guard let scene = player.node.scene else { return (false, 0) }
        
        let playerFrame = player.node.parent?.convert(player.node.calculateAccumulatedFrame(), to: scene) ?? .zero
        let vehicleFrame = vehicle.node.parent?.convert(vehicle.node.calculateAccumulatedFrame(), to: scene) ?? .zero
        
        let isAhead = vehicleFrame.midY > playerFrame.midY
        let isVisible = vehicleFrame.minY > -scene.size.height / 2
        
        let activeHitbox = vehicleFrame.insetBy(dx: -configuration.latchDistance, dy: -configuration.latchDistance)
        let intersects = playerFrame.intersects(activeHitbox)
        
        let isValid = intersects && isAhead && isVisible
        
        let dx = vehicleFrame.midX - playerFrame.midX
        let dy = vehicleFrame.midY - playerFrame.midY
        let distance = hypot(dx, dy)
        return (isValid, distance)
        
    }
    
    // MARK: - UI Proximity Check
    /// Scans the target without actually latching into the vehicle
    func getBestTarget(player: PlayerEntity, vehicles: [VehicleEntity]) -> VehicleEntity? {
        var validTargets: [(vehicle: VehicleEntity, distance: CGFloat)] = []
        
        for vehicle in vehicles {
            let evaluation = evaluateTarget(player: player, vehicle: vehicle)
            if evaluation.isValid {
                validTargets.append((vehicle: vehicle, distance: evaluation.distance))
            }
        }
        validTargets.sort { $0.distance < $1.distance }
        return validTargets.first?.vehicle
    }
}
