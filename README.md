# PROJECT MAYHEM

A third-person 3D action roguelite built in **Godot 4.7.2 Stable** with GDScript. The long-term goal is a **1–4 player cooperative** game featuring randomized loot, stackable upgrades, challenging bosses, and permanent progression.

## Current version — v0.1 gameplay prototype

This first commit includes:
- A primitive 3D arena and controllable third-person character
- WASD movement and mouse-look camera
- Left-click / Space hitscan shooting
- Waves of chasing enemies with attacks
- XP and three-choice level-up upgrades
- Seven upgrades, including multishot, vampirism, and chain lightning
- Boss encounter after 75 seconds
- Saved earned gold in `user://progress.json`

**Not yet implemented:** network co-op, player-owned inventory, loot drops, class selection, animations, hub, and permanent upgrades. Saved gold is groundwork for the future hub economy.

### Running the prototype

1. Clone or download this repository.
2. Open **Godot 4.7.2 Stable**.
3. Click **Import** and choose the repository's `project.godot`.
4. Press **F5** to run.
5. If the editor reports a parse or runtime error, copy the exact error into a GitHub issue.

### Controls

| Control | Action |
| --- | --- |
| WASD | Move relative to the camera |
| Mouse | Look / aim |
| Left Mouse Button or Space | Shoot |
| Esc | Release / capture mouse |
| R | Restart run |

### Project structure

```text
project.godot
scenes/
  main.tscn
scripts/
  game.gd
  player.gd
  enemy.gd
```

### Planned milestones

1. Validate and improve the combat vertical slice.
2. Convert primitive entities into reusable scenes and systems.
3. Implement authoritative ENet host/join co-op for 1–4 players.
4. Add proper loot drops, inventory, rarity and equipment.
5. Implement boss patterns, revives and stage progression.
6. Add a hub, character classes and permanent unlocks.

## Development process

Changes should be introduced on feature branches, reviewed through pull requests, and tested in Godot before release. Don't commit the generated `.godot/` cache or credentials.

> This is an initial source prototype and has **not yet been run/tested in the Godot editor** by the assistant. It uses original primitive geometry and no third-party art.
