//
//  NomadAsset.swift
//  C2_ADA Shared
//
//  Created by Howie Homan on 12/05/26.
//

// MARK: - Nomad Asset Names

/// Planned asset names from the team's art list.
///
/// The current prototype still uses shape nodes, but these raw values are ready
/// for future `SKSpriteNode(imageNamed:)` calls once final assets are imported.
enum NomadAsset: String {
    // MARK: Player

    case playerLegsStraight = "PlayerLegsStraight"
    case playerLegsLeft = "PlayerLegsLeft"
    case playerLegsRight = "PlayerLegsRight"

    // MARK: Jeep

    case jeepNormal = "JeepNormal"
    case jeepPersonPoppingOut = "JeepPersonPoppingOut"
    case jeepPersonHitting1 = "JeepPersonHitting1"
    case jeepPersonHitting2 = "JeepPersonHitting2"

    // MARK: Van

    case vanNormal = "VanNormal"
    case vanPersonPoppingOut = "VanPersonPoppingOut"
    case vanPersonHitting1 = "VanPersonHitting1"
    case vanPersonHitting2 = "VanPersonHitting2"

    // MARK: Pickup

    case pickupNormal = "PickupNormal"
    case pickupPersonPoppingOut = "PickupPersonPoppingOut"
    case pickupPersonHitting1 = "PickupPersonHitting1"
    case pickupPersonHitting2 = "PickupPersonHitting2"

    // MARK: Monster Truck

    case monsterTruckNormal = "MonsterTruckNormal"
    case monsterTruckPersonPoppingOut = "MonsterTruckPersonPoppingOut"
    case monsterTruckPersonHitting1 = "MonsterTruckPersonHitting1"
    case monsterTruckPersonHitting2 = "MonsterTruckPersonHitting2"

    // MARK: Obstacles

    case rock = "Rock"
    case desertTree = "DesertTree"
    case cactus = "Cactus"

    // MARK: Background

    case floor = "Floor"
    case leftWall = "LeftWall"
    case rightWall = "RightWall"

    // MARK: Effects

    case sandSplash = "SandSplash"
    case smoke = "Smoke"
    case sandParticle = "SandParticle"
}
