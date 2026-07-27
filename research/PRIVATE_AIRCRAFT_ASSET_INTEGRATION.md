# Agent instruction: private aircraft asset integration

## Objective

Integrate one privately converted Sky Odyssey aircraft as a **visual-only,
local experiment** in the Open Odyssey Godot prototype. Keep gameplay physics,
controls, camera behavior, audio, and the existing collision shape unchanged
until the visual transform and aircraft configuration are verified.

Repository:

`C:\Users\imano\Github_Projects\open-odyssey`

Private aircraft assets:

`game/private-original-material/sky-odyssey`

Private format research and conversion tools:

`C:\Users\imano\Github_Projects\sky-odyssey-research`

## Non-negotiable boundaries

1. Read `research/CLEAN_ROOM_RULES.md` and `assets/README.md` before changing
   anything.
2. Treat every glTF, BIN, imported Godot resource, screenshot, preview, derived
   mesh, and configuration assembled from Sky Odyssey data as private
   copyrighted material.
3. Never stage, commit, upload, redistribute, or publish those files.
4. Do not add extracted assets beneath the tracked `assets/` directory.
5. Keep private integration scenes, scripts, import metadata, screenshots, and
   derived outputs beneath `game/private-original-material/`, which is excluded
   through `.git/info/exclude`.
6. Before finishing, prove with `git status --short` and `git check-ignore -v`
   that no original or derived game content is tracked.
7. Do not copy decompiled implementation or configuration logic into the
   public project. A generic asset-loading abstraction may be tracked only if
   it contains no original names, paths, data, or assumptions and still works
   when the private directory is absent.

## Known evidence and limitations

- There are eleven geometry-only aircraft conversions. Read the private
  `manifest.json` instead of inferring identities from directory names.
- Embedded tags include `bf109_tex`, `twin_tex`, `puls_tex01`, two `j7w_tex`
  records, `f117_tex`, `me262_tx01`, `cors_tx01`, `jai_tx01`, `ufo_tex`, and
  `ufo2_tex`.
- Each `full-hierarchy.gltf` preserves CXM nodes and transforms.
- A full hierarchy contains mutually exclusive upgrade/configuration branches.
  Rendering every branch simultaneously produces an overlaid or exploded
  aircraft. The correct branch-selection table is not decoded.
- Materials, textures, animation, movable control surfaces, collision roles,
  definitive scale, and coordinate conversion are unresolved.
- Open Odyssey uses X right, Y up, and negative Z forward.

Distinguish confirmed facts, hypotheses, and unknowns in every note or report.

## Required workflow

### 1. Establish a clean baseline

- Confirm that the repository is clean before editing.
- Run the existing verification command from `README.md`.
- Inspect `game/scenes/main.tscn`, `game/scripts/aircraft.gd`, and
  `game/tests/smoke_test.gd`.
- Confirm that `PlayerAircraft` remains the authoritative `RigidBody3D` and
  that its existing `CollisionShape3D` remains active.

Stop if the private manifest or selected glTF/BIN pair is missing, unreadable,
not ignored, or cannot be imported by Godot.

### 2. Begin with one controlled aircraft

- Use aircraft index 0 (`bf109_tex`) as the first experiment unless the user
  requests another index.
- Load its `full-hierarchy.gltf` from the ignored private directory.
- Create a private integration scene beneath
  `game/private-original-material/sky-odyssey/integration/`.
- Instantiate the tracked `game/scenes/main.tscn` from that private scene.
- Add a `Node3D` visual pivot beneath `PlayerAircraft` and instance the imported
  aircraft beneath the pivot.
- Hide the four primitive visual nodes (`Fuselage`, `Wing`, `TailPlane`, and
  `Fin`) only in the private integration scene. Do not remove them from the
  tracked main scene.
- Keep the prototype box collision unchanged. The extracted model is visual
  reference material, not collision geometry.

### 3. Resolve orientation and scale empirically

- Add private, editable pivot properties for scale, Euler rotation, and local
  translation.
- Align the model so its nose points along Open Odyssey's negative Z forward
  axis, wings lie across X, and vertical is positive Y.
- Determine scale by comparing the imported bounds against the current
  prototype aircraft dimensions and camera distance. Record the measured
  bounds and chosen transform.
- Do not bake or destructively rewrite source glTF/BIN files.
- Do not change mass, inertia, thrust, lift, drag, torque, camera offsets, or
  collision dimensions merely to make the visual model appear correct.

### 4. Select a coherent private branch set

- Read the aircraft entry's `root_branch_nodes` in the private manifest.
- Disable all mutually exclusive top-level branches first.
- Enable branches incrementally and capture a private node-selection manifest
  containing source aircraft index, source node indices, source hashes, and the
  reason each branch was selected.
- Use visual continuity, symmetry, hierarchy, and executable part-family
  evidence; do not label a branch as wing, tail, canopy, engine, or propeller
  unless evidence supports that label.
- If no coherent configuration can be selected confidently, leave the
  experiment as a branch inspector and report the blocker. Do not present an
  arbitrary combination as the default aircraft.

### 5. Validate gameplay isolation

- Run the private integration scene and confirm:
  - the aircraft visual follows `PlayerAircraft` without lag;
  - pitch, roll, and yaw axes are correct;
  - the chase camera remains unchanged;
  - the visual does not create extra physics bodies or collision shapes;
  - restart restores the visual with the aircraft;
  - audio and HUD still target `PlayerAircraft`;
  - flight-test behavior matches the tracked baseline.
- Run the normal project verification command again.
- Check the Godot output for import errors, invalid transforms, missing BIN
  files, and excessive node/surface counts.

## Deliverables

Keep these private and ignored:

- a private integration scene;
- any private loader or branch-selection script;
- a branch-selection/provenance JSON file;
- transform measurements and screenshots;
- derived meshes or Godot import artifacts.

The final report must state:

- aircraft index and embedded tag;
- source glTF and SHA-256 provenance;
- enabled source node indices;
- applied scale, rotation, and translation;
- Godot version and validation results;
- confirmed facts, hypotheses, unresolved items, and observed rendering defects;
- `git status --short` output proving no private content was staged.

Do not replace the public prototype aircraft or commit a tracked reference to
the ignored model unless the user explicitly changes the publication boundary.
