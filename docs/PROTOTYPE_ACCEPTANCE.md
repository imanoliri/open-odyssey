# Grey-box prototype acceptance criteria

## Functional

- The project opens in Godot 4 without missing resources.
- The aircraft responds to pitch, roll, yaw, and throttle.
- Lift increases with forward airspeed.
- Drag opposes movement.
- Below the configured stall threshold, lift and control authority degrade.
- The aircraft collides with the ground and runway.
- The camera follows without being rigidly attached.
- The chase camera follows heading while keeping a fixed pitch and level horizon.
- The HUD displays airspeed, altitude, throttle, and stall state.
- A connected standard gamepad is identified in the HUD.
- Left stick controls pitch/roll; right stick controls yaw; L1/R1 control throttle.
- Restart restores the initial scene.

## Experience

- Inputs produce predictable, smooth reactions.
- The player can distinguish low energy from high energy without reading code.
- A stall is signaled before or as control is lost.
- Camera movement communicates speed without obscuring aircraft attitude.
- Tuning values are exported and editable in the Godot inspector.

## Verification record

| Check | Result | Date | Notes |
|---|---|---|---|
| Project import | Passed | 2026-07-26 | Godot 4.7.1 headless editor import |
| Parser/runtime | Passed | 2026-07-26 | Scene ran for 180 physics frames |
| Propulsion smoke test | Passed | 2026-07-26 | 20.74 m travel; 21.07 m/s; full throttle |
| Keyboard controls | Pending | | Requires interactive test |
| Fixed-angle camera | Pending | | Requires interactive visual test |
| PS2 USB controller detection | Passed | 2026-07-26 | Device 0 detected as `XInput Controller` |
| PS2 USB controller mapping | Pending | | Requires interactive stick/button test |
| Takeoff | Pending | | |
| Stall/recovery | Pending | | |
| Landing | Pending | | |
| Restart | Pending | | |
