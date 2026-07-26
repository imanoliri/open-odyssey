# Open Odyssey working plan

## Goal

Create an original adventure-flight game that preserves the physical tension,
terrain reading, exploration, and expedition feeling that make *Sky Odyssey*
special. Private research informs a new implementation; it does not supply
publishable code or assets.

## Guiding decision

Build a spiritual successor first. Treat complete PS2 decompilation as an
optional, long-term preservation project rather than a prerequisite.

```text
Lawfully owned game + PCSX2
             |
             v
Private observations and experiments
             |
             v
Behavioral specification
             |
             v
Original Godot implementation
             |
             +-- Desktop build
             +-- Browser build and catalogue website
```

## Tracks

### A. Private research

Use controlled play sessions, recordings, save states, and reproducible tests
to characterize flight response, camera behavior, hazards, mission rules,
damage, upgrades, and pacing. Use debugger or executable inspection only when
ordinary observation cannot answer an important question.

### B. Original implementation

Use Godot 4 and original or properly licensed assets. Begin with a five-minute
mission: depart a coastal runway, traverse a turbulent mountain pass, and land
at an expedition camp.

### C. Playable website

After the vertical slice works, package the Godot web export in a catalogue with
controls, fullscreen support, development notes, comparisons, and changelogs.

## Phases and exit criteria

### Phase 0 — Define the target

- Write the product brief.
- Identify the five essential experience pillars.
- Record clean-room and content boundaries.
- Define measurable acceptance criteria for the first aircraft.

Exit: the team can decide whether a feature belongs in the successor without
copying the original expression.

### Phase 1 — Establish the research laboratory

- Configure PCSX2 and controller mapping.
- Record game version and disc hashes without committing disc contents.
- Catalogue missions and controls.
- Create repeatable flight experiments.
- Observe one aircraft's takeoff, turn, climb, stall, glide, and landing.

Exit: another tester can repeat the experiments and compare results.

### Phase 2 — Grey-box flight prototype

- Implement thrust, lift, drag, gravity, and control torque.
- Add throttle, pitch, roll, yaw, camera, telemetry, and restart.
- Add ground contact and a simple runway.
- Tune for enjoyable response before pursuing detailed fidelity.

Exit: the aircraft can complete a circuit and land, and its parameters are
editable without changing the controller script.

### Phase 3 — Comparison harness

- Define acceleration, takeoff, turn, climb, glide, stall, and landing tests.
- Record prototype telemetry in a consistent unit system.
- Compare ranges and response curves with private observations.
- Document every deliberate deviation.

Exit: flight tuning is evidence-based and repeatable.

### Phase 4 — Vertical-slice mission

- Add an original island, mountain pass, and destination strip.
- Add checkpoints, wind, turbulence, fuel, damage, success, and failure.
- Add readable audio and visual feedback.
- Conduct outside playtests.

Exit: a new player can understand, finish, and replay a five-minute mission.

### Phase 5 — Browser and website

- Export with Godot's Compatibility renderer.
- Profile loading time, memory, frame rate, and controller support.
- Create the game page and catalogue.
- Publish controls, accessibility notes, version, and changelog.

Exit: the mission loads reliably from a URL on supported desktop browsers.

### Phase 6 — Targeted reverse engineering

Investigate only questions that improve the behavioral specification, such as
mission data organization, flight-state variables, update rates, upgrade
effects, or the camera state machine. Keep extracted material private.

### Phase 7 — Full original game

Expand to multiple aircraft classes, connected regions, expedition progression,
payload and fuel decisions, upgrades, severe weather, secrets, and branching
missions.

## First sprint

- [x] Create separated research and implementation directories.
- [x] Save roadmap, design brief, and clean-room rules.
- [x] Create experiment, mission, and flight-test templates.
- [x] Scaffold a Godot 4 grey-box aircraft, camera, runway, and telemetry HUD.
- [x] Install Godot 4 and import the project.
- [x] Run automated import, parser, and propulsion smoke tests.
- [ ] Run the first interactive prototype flight.
- [ ] Configure a controller and test keyboard fallback.
- [ ] Record the first baseline flight.
- [ ] Observe one comparable maneuver in the original game.
- [ ] Tune one parameter at a time and record the result.

## First vertical-slice definition

The player begins on a coastal runway, takes off, passes through a marked
mountain corridor with turbulence, and lands at a remote expedition strip.
Initial scope is one aircraft, one environment, one weather profile, one mission
path, one failure condition, and one complete restart loop.

## Risks

- A full decompilation can consume years without producing a playable game.
- Asset extraction can distract from behavioral understanding.
- Browser constraints may require reduced terrain complexity and single-threaded
  physics.
- A technically plausible flight model can still feel poor if camera and
  feedback are neglected.
- Public use of original assets, names, music, dialogue, maps, or executable
  code creates avoidable legal and distribution risk.
