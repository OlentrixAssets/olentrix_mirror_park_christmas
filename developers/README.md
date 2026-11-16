# Mirror Park Christmas: for developers

This folder is the reference for people who want to change, extend or pick apart the map. If you just want it on your server, use the
**server** download instead (drag and drop, one `ensure` line).

## What the developer download contains

- `resources/`: every resource as its own folder, core and add-ons side by side (no category folders), so you can take only the
  pieces you want.
- `docs/REFERENCE.md`: each resource's dependencies, settings, commands, permissions, exports, events and state keys.
- The props pack is a separate download (`olentrix_mpc_props`): the market's props with no map placements or scripts.

## How the pieces fit

- `olentrix_mpc_mold` and `olentrix_mpc_ground` reshape the hill court; everything else stands on them. Keep both if you keep the market.
- `olentrix_mpc_market` is the village: models, textures and the map file. The scripted parts (`ambience`, `express`, `coaster`, `santa`,
  `seats`, `skating`, `iceshow`, `elf`) are separate resources and can be left out one by one.
- `olentrix_mpc_skatekit` holds the skate models and skating animations; `olentrix_mpc_skating` and `olentrix_mpc_iceshow` both need it.
- The add-ons (`houses`, `houses_snow`, `trees`, `streets`) are independent of the market. `trees` and `streets` replace the game's own
  tree, palm and street prop models across the whole map.
- Every script runs standalone: no framework is required. Shared things between resources go through GlobalState keys and exports,
  listed in the reference.

## Changing things

- Wording, prices, timings, positions and key bindings are in each resource's `config.lua`.
- Map files are binary `.ymap`; open them with CodeWalker or another GTA map tool to move or remove pieces.
- Resource names can be changed, but some resources refer to each other by name (see Dependencies and Exports used in the reference).
