# Agent instruction: private terrain asset integration

## Objective

Integrate a small, controlled selection of privately converted Sky Odyssey CXL
terrain geometry into an **ignored local Open Odyssey test scene**. Establish
correct transform, collision, performance, and streaming behavior before
attempting a larger map assembly.

Repository:

`C:\Users\imano\Github_Projects\open-odyssey`

Private terrain assets:

`game/private-original-material/sky-odyssey/terrain`

Private format research and conversion tools:

`C:\Users\imano\Github_Projects\sky-odyssey-research`

## Non-negotiable boundaries

1. Read `research/CLEAN_ROOM_RULES.md` and `assets/README.md` before changing
   anything.
2. Treat all converted terrain glTF/BIN files, derived scenes, collisions,
   screenshots, previews, and assembled maps as private copyrighted content.
3. Never stage, commit, upload, redistribute, or publish them.
4. Keep private integration code, scenes, import data, caches, and derived
   outputs beneath `game/private-original-material/`.
5. Do not add extracted terrain beneath the tracked `assets/` directory.
6. Before finishing, prove with `git status --short` and `git check-ignore -v`
   that no private or derived content is tracked.
7. A generic streaming or terrain-loading abstraction may be tracked only if it
   contains no original names, paths, map layouts, hashes, or data and functions
   correctly when the private directory is absent.

## Known evidence and limitations

- `SO.MPD` contains 2,800 active members.
- The private conversion produced 788 geometry-bearing glTF tiles containing
  12,454 mesh groups and 894,769 triangles.
- Fourteen irregular topology variants remain unconverted and are listed under
  `unsupported_tiles` in the private manifest.
- Sample tiles use local X/Z bounds near `0..4000`, but the relationship between
  source units and Open Odyssey metres is not confirmed.
- The executable path and member count support a 56 × 50 grid, but the index
  ordering is unresolved. The manifest preserves both `index=x*50+z` and
  `index=z*56+x`.
- Materials and textures are unresolved.
- Node roles, object-versus-terrain classification, transforms, collision
  geometry, and definitive LOD selection are unresolved.
- Some indexed tiles can contain overlapping runtime detail groups.
- Ordered displaced-grid tiles use reconstructed two-triangle cells.

Do not assemble a world using either grid formula as though it were confirmed.

## Required workflow

### 1. Establish a clean baseline

- Confirm the repository is clean.
- Run the existing verification command from `README.md`.
- Inspect `game/scenes/main.tscn`, its primitive `Ground`, the runway,
  `PlayerAircraft`, and the smoke tests.
- Read the private terrain `manifest.json` and verify the selected glTF/BIN
  pair's source offset and hash.

Stop if the manifest is missing, a selected tile is unsupported, the glTF/BIN
pair is incomplete, the files are not ignored, or Godot cannot import them.

### 2. Start with one clean displaced-grid tile

- Use tile 1571 for the first collision-capable experiment. Its private
  conversion is a 51 × 51 displaced grid with 5,000 triangles and produced a
  clean surface preview.
- Create a private integration scene under
  `game/private-original-material/sky-odyssey/terrain-integration/`.
- Instantiate the tracked `game/scenes/main.tscn` inside that private scene.
- Instance `tile-1571/geometry.gltf` beneath a dedicated `Node3D` terrain pivot.
- Keep the tracked primitive ground enabled until visual placement is verified.
- Make scale, rotation, and translation private editable properties. Do not bake
  them into the source glTF.

### 3. Determine a local transform without assuming world placement

- Inspect the imported AABB.
- Center the tile around the private test origin using its measured X/Z bounds.
- Translate its source elevation into the prototype's test altitude without
  altering vertex data.
- Verify that X/Z form the horizontal plane and Y is vertical. If an axis or
  handedness correction is required, record it explicitly.
- Choose scale by comparing the 4,000-unit tile extent, terrain relief, current
  aircraft dimensions, runway dimensions, camera range, and physics speeds.
- Record the evidence and uncertainty. Do not claim source units are metres
  merely because the result looks plausible.

### 4. Add collision conservatively

- Generate collision only for the clean tile-1571 displaced-grid mesh.
- Place the collision under a `StaticBody3D` in the private scene.
- Prefer one simplified or concave static collision surface; never attach
  terrain collision to a dynamic rigid body.
- Verify triangle count and startup cost before generating collision for
  another tile.
- Disable the tracked flat ground collision only in the private integration
  scene after the terrain collision is confirmed stable.
- Test aircraft spawn clearance, ground contact, sliding, restart, and absence
  of tunneling.
- Do not generate collision from indexed tiles that visibly contain overlapping
  LOD/detail groups until those roles are decoded.

### 5. Inspect one indexed tile separately

- Use tile 370 as an indexed-format visual inspection case.
- Keep it visual-only.
- Provide controls or a private inspector to show individual imported mesh
  groups and all groups together.
- Identify overlapping surfaces, giant coarse triangles, object-like geometry,
  or likely LOD layers. Record observations as hypotheses.
- Do not delete or merge source groups destructively and do not select a
  "correct" LOD without evidence.

### 6. Build a bounded streaming experiment

- After single-tile validation, load at most a small configurable neighborhood,
  initially no more than nine tiles.
- Keep every tile as a separate transformable chunk.
- Implement distance-based loading/unloading or visibility before increasing
  the neighborhood.
- Avoid importing or instantiating all 788 tiles at startup.
- Keep both grid-index formulas selectable in the private harness and compare
  seam continuity, elevation continuity, recognizable coastline/terrain
  structure, and neighboring AABBs.
- Treat a formula as confirmed only if repeated seams and independent evidence
  agree. Otherwise leave world assembly unresolved.
- Never include the fourteen unsupported entries as empty placeholder meshes;
  read their provenance from `unsupported_tiles`.

### 7. Validate

- Run the private scene and verify:
  - Godot imports every selected glTF/BIN pair without errors;
  - terrain remains stationary;
  - visual and collision transforms match;
  - aircraft physics, controls, HUD, camera, audio, and restart still work;
  - frame time and memory remain acceptable for the configured neighborhood;
  - unloading a tile removes its visual and collision safely.
- Run the normal Open Odyssey verification command.
- Re-run the private representative import test if the converter output is
  regenerated.

## Deliverables

Keep these private and ignored:

- private terrain integration and inspector scenes;
- private loader/streaming scripts;
- generated collision resources;
- transform and grid-hypothesis configuration;
- screenshots, previews, performance captures, and derived meshes.

The final report must include:

- selected tile indices and source hashes;
- whether each tile uses indexed or displaced-grid conversion;
- measured AABBs and applied transforms;
- collision-generation method and triangle count;
- active grid-index hypothesis, clearly labeled as hypothesis unless proved;
- streaming radius, peak loaded tile count, memory/frame-time observations;
- Godot version and validation results;
- unsupported or defective tiles encountered;
- `git status --short` output proving no private content was staged.

Do not replace the public prototype ground or commit a tracked map layout based
on the original game unless the user explicitly changes the publication
boundary.
