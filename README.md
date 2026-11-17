# BRAINROT BAZAAR

A Rojo-first 3D Roblox collection game for make.fun's roblox-brainrot-01 bounty.
This foundation commit contains the static plaza and character construction.
Conveyor movement, player base assignment, income, carrying, stealing, locks,
tsunamis, rebirths and the HUD are scheduled for subsequent build turns.

## Source layout

- `src/shared/GameConfig.luau`: immutable tiers, prices, income, mutation odds,
  world dimensions and 18 original character part recipes. Mutation probabilities
  are absolute, with the remaining probability normal; only one mutation applies.
- `src/server/CharacterFactory.luau`: `Create(characterId, mutationId?)` returns
  an unparented, root-welded Model. Its pivot is at ground level and it faces -Z.
  Bodies scale from 3.1 to 5 studs by tier. Mutations affect parts, trim and glow;
  every character has a three-line name/rarity/income billboard.
- `src/server/WorldBuilder.luau`: builds `Workspace.BrainrotBazaar` at server
  startup, including the diagonal belt, six unclaimed plots with six pads each,
  owner signs, lock pedestals, reserved expansion areas and a neutral spawn.
  `Build()` returns the plot and conveyor references without claiming anything.
- `src/server/GameState.luau`: sole server runtime state home; typed empty
  player/character maps, base references and world references. No persistence yet.
- `src/server/init.server.luau`: builds the world and stores its references.
- `src/client/Game.client.luau`: placeholder for future controllers; default
  Roblox camera and movement are enabled, with the square demo removed.

All place Script, LocalScript and ModuleScript sources live under `src/` and
are mounted by `default.project.json`. No scripts are generated at runtime.
`game.rbxl` must be rebuilt from these sources after every build turn:

```sh
rojo build default.project.json --output /tmp/smoke.rbxl
rojo build default.project.json --output game.rbxl
```

`PLAY.json` identifies the owner's published experience. Rebuilding locally does
not publish changes to Roblox. The inherited screenshots and `TOUR.json` still
show the kit starter and will be replaced when the game is ready to capture.

`main.ts` remains the kit's Node 22 submission entrypoint, using the unchanged
vendored dossier helper. It copies `game.rbxl`, `src/`, `screenshots/` and
`PLAY.json` to the output directory and describes the resulting place.

```sh
mkdir -p out
MAKEFUN_OUTPUT_DIR=out node main.ts
```
