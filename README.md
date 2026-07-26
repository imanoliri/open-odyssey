# Open Odyssey

An original adventure-flight game prototype informed by behavioral research into
classic flight-adventure design.

This repository contains:

- `game/` — the Godot 4 prototype
- `docs/` — design brief and acceptance criteria
- `research/` — empty templates and behavioral notes safe for version control
- `assets/` — original or properly licensed game assets
- `tools/` — verification scripts
- `website/` — the future browser catalogue
- `PLAN.md` — the working roadmap

Raw game dumps, extracted assets, disassembly, save states, recordings, and other
copyrighted original material must remain outside this repository.

## Run

Open `game/project.godot` with Godot 4.7.1 and run the main scene.

From PowerShell:

```powershell
& "C:\Users\imano\Games\Godot\Godot_v4.7.1-stable_win64.exe" --editor --path ".\game"
```

## Prototype controls

| Control | Keyboard |
|---|---|
| Pitch | W / S |
| Roll | A / D |
| Yaw | Q / E |
| Throttle | R / F |
| Restart | Enter |

Hold `R` to increase throttle. Near 30 m/s, use `W` gently to pitch upward.

### PS2 USB controller

The prototype uses Godot's standard gamepad layout:

| Control | PS2-style controller |
|---|---|
| Pitch and roll | Left analog stick |
| Yaw | Right analog stick, horizontal |
| Throttle down/up | L1 / R1 |
| Restart | Start |

Pull the left stick down to pitch upward. The HUD displays the controller name
that Godot detects. Some unbranded PS2-to-USB adapters expose nonstandard button
numbers; run the controller probe below if the mapping does not respond.

```powershell
& "C:\Users\imano\Games\Godot\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path ".\game" --script "res://tests/controller_probe.gd"
```

### Camera

The camera follows the aircraft's position using a constant world-space offset.
Its viewing rotation stays completely fixed: aircraft pitch, roll, yaw, and
direction do not rotate it. The offset, rotation, and position smoothing remain
editable on the `CameraRig` node.

## Verify

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\verify_project.ps1" `
  -GodotCommand "C:\Users\imano\Games\Godot\Godot_v4.7.1-stable_win64_console.exe"
```

The initial scene intentionally uses primitive geometry. It tests physics,
camera, ground interaction, controls, telemetry, and restart behavior before art
production.
