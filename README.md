<a id="readme-top"></a>

<div align="center">

# Nomad

### Find your line through a moving world.

An iOS game prototype built around isometric rows, vehicle steering, and an entity-component-system architecture.

<p>
  <a href="https://github.com/deusgvrl/Nomad">
    <img src="https://img.shields.io/badge/Repository-181717?style=for-the-badge&logo=github&logoColor=white" alt="Open the Nomad repository on GitHub" />
  </a>
  <img src="https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/SpriteKit-000000?style=for-the-badge&logo=apple&logoColor=white" alt="SpriteKit" />
  <img src="https://img.shields.io/badge/GameplayKit-000000?style=for-the-badge&logo=apple&logoColor=white" alt="GameplayKit" />
</p>

</div>

## About the project

Nomad is an exploration of how a small mobile game can combine tactile input, readable motion, and a data-driven gameplay structure.

The current prototype places the player in a moving isometric world. The player rides a vehicle, steers it through touch input, and navigates rows containing vehicles, obstacles, walls, and collision rules.

## Core loop

1. The game creates an isometric world from reusable rows and entities.
2. Touch input is translated into holding, dragging, releasing, or idle phases.
3. Dragging steers the vehicle along its configured movement axis.
4. The player stays attached to the vehicle while it moves.
5. Spawn, movement, collision, launch, and latch systems update the world every frame.

## What is inside

- **Entity-component-system architecture** — GameplayKit entities and components separate gameplay state from SpriteKit presentation.
- **Isometric world movement** — rows move diagonally, recycle, and are continuously populated to keep the scene moving.
- **Touch-driven steering** — a small input state machine turns raw touches into predictable gameplay phases.
- **Player and vehicle coupling** — the player attaches to the vehicle and follows its position and ride offset.
- **Procedural spawning rules** — obstacle and vehicle spacing rules help avoid repetitive or unreachable patterns.
- **Collision and state systems** — dedicated systems handle collision, latching, launching, movement, and spawning.
- **Custom visual language** — the project includes bundled fonts and dedicated render-layer, asset, shape, and haptics helpers.

## Built with

<p>
  <img src="https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/SpriteKit-000000?style=flat-square&logo=apple&logoColor=white" alt="SpriteKit" />
  <img src="https://img.shields.io/badge/GameplayKit-000000?style=flat-square&logo=apple&logoColor=white" alt="GameplayKit" />
  <img src="https://img.shields.io/badge/UIKit-2396F3?style=flat-square&logo=apple&logoColor=white" alt="UIKit" />
  <img src="https://img.shields.io/badge/Xcode-147EFB?style=flat-square&logo=xcode&logoColor=white" alt="Xcode" />
</p>

## Getting started

### Requirements

- macOS with Xcode installed
- An iOS simulator or connected iPhone
- A device size that can display the portrait-oriented game scene

### Run locally

1. Clone the repository:

   ```sh
   git clone https://github.com/deusgvrl/Nomad.git
   cd Nomad
   ```

2. Open `C2_ADA.xcodeproj` in Xcode.
3. Select the iOS app target and a simulator or connected device.
4. Build and run.

## Controls

Touch and drag across the game scene to steer the vehicle. The current input system tracks the gesture from its starting point through movement and release.

## Project structure

```text
Nomad/
├── C2_ADA.xcodeproj     # Xcode project
├── C2_ADA Shared/       # Shared ECS, entities, systems, helpers, and UI
│   ├── ECS/
│   ├── Helper/
│   ├── Resources/
│   ├── State/
│   └── UI/
└── iOS App/             # App delegate, SpriteKit view controller, and fonts
```

## Current status

This repository is an active game prototype. The README is intentionally a draft; add approved screenshots, the confirmed game objective, and the final device/support matrix before treating it as release documentation.

<div align="center">
  <sub>Move carefully. Keep going.</sub>
</div>

<p align="right"><a href="#readme-top">Back to top ↑</a></p>
