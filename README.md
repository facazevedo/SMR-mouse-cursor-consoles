# Mouse Cursor Consoles

A Surviving Mars: Relaunched Lua mod that toggles a left-stick mouse cursor and
temporarily uses the PC interface. Initial release: metadata version **1**.

| Action | PS5 | Xbox Series X/S |
| --- | --- | --- |
| Mouse mode on / off | R3 | Right-stick click |
| Move cursor | Left stick | Left stick |
| Left click / hold to drag | Cross | A |
| Right click | Circle | B |
| Wheel up | L1 | LB |
| Wheel down | R1 | RB |
| Menu / Escape | Options | Menu |

Activate the mod and open a colony before toggling mouse mode. A second press of
the same toggle restores the previous control style. The cursor starts in the
screen center each time. The right stick does not move it. Both native camera
sticks are locked while mouse mode is active; move to the screen edge for the
game's PC camera behavior. Other controller actions are suppressed in mouse mode
to avoid triggering both a mouse action and its original controller action.

**R3 normally pauses the game.** This mod reserves it for the toggle in a colony,
including while mouse mode is off. Use the HUD's pause control, or configure a
different toggle. Turning off the feature or unloading the mod restores R3 too.

This is a console-targeted implementation, **not a console-tested release**.
Windows engine tests used simulated controller input and a test UI. Physical
PS5/Xbox controllers, console rendering, colony selection/construction, native
camera scrolling, and save/reload gameplay still need the checks below. Exact
parity with every PC interaction is not yet established. Text entry and keyboard
shortcuts are outside this mod's mouse bindings.

## Install and configure

For local Windows testing, run `powershell -File tools/deploy.ps1` from this
project (Lua 5.4 `luac` must be on PATH), then enable **Mouse Cursor Consoles** in
the game mod manager. The script installs only `metadata.lua`, `items.lua`, and
the six files under `Code/` into `%APPDATA%/Surviving Mars Relaunched/Mods/MouseCursorConsoles`.
It verifies file hashes and does not delete destination files.

PS5/Xbox distribution needs the game's supported publishing/Paradox Mods path;
copying this Windows folder does not install it on a console. No mod-store
publication was performed. Paradox advertises cross-platform mod support on the
[official game page](https://www.paradoxinteractive.com/games/surviving-mars-relaunched/about),
but that does not certify this particular code mod on either console.

Edit `Code/mcc_config.lua` for bindings, speed, dead zone, double-click timing,
`ENABLE_MOUSE_MODE`, `DEBUG_LOGS`, and `DEBUG_INPUT`. Debug flags default to the
boolean `false`; input diagnostics require both debug flags to be exactly `true`.
Redeploy and reload the mod after editing. Bindings must be distinct engine
button names. Logging covers API/configuration failures, registration, toggles,
restoration reasons, input dispatch, and override ownership conflicts.

## Ownership and restoration

- `mcc_config.lua`: configuration and transient state in the mod environment.
- `mcc_debug.lua`: explicit boolean-gated diagnostics.
- `mcc_cursor.lua`: left-stick movement, software cursor, mouse-position query override.
- `mcc_input.lua`: input ownership, paired clicks, doubles, wheel repeats and toggle.
- `mcc_lifecycle.lua`: validation, apply/restore, input registration and removal.
- `MouseCursorConsoles.lua`: lifecycle message wiring.

`metadata.lua` is the canonical version and runtime load order; `items.lua`
contains the identical editor registration order. There are no external mod
dependencies, bundled libraries, new image assets, or persistent save variables.
The cursor uses the game's existing cursor images and rollover system.

The one function override, `terminal.GetMousePos`, returns the current software
position while active. Native tests found that a hardware warp can lag a frame.
The original function is retained and restored only if the mod still owns the
override; a later third-party wrapper is preserved with an inactive passthrough.
UI-style changes use `ChangeGamepadUIStyle`, never `SwitchControls`, so the user's
saved control preference is not overwritten. Camera lock ownership is additive.

Toggle-off releases held mouse buttons before removing the cursor. Map changes,
load-game notifications, end-game, loss of focus, controller disconnection,
external control-style changes, Lua reload and mod unloading also restore state.
Buttons held across a toggle must be released before producing a new mouse click.

## Verification

Run `lua tests/mcc_behavior.lua` for deterministic host checks. Native test helpers
under `tests/` are for a disposable Windows debug-game process using the local
`smr-harness`; they are excluded from the payload. See
[validation evidence and source references](docs/VALIDATION.md).

Before publishing, perform these checks separately on PS5 and Xbox Series X/S:

1. Enable the mod, start a colony, press R3, and confirm the cursor appears and
   the PC interface is usable. Move left stick in all directions; verify dead
   zone, screen edges and speed. Right stick must not move the cursor or camera.
2. Select a building, open tooltips and menus, double click, drag a slider and
   scrollbar, place/cancel construction, and issue a unit right-click command.
   Confirm exactly one action occurs at the cursor location.
3. Test both wheel buttons over lists and over the colony camera. Hold them to
   check repeat scrolling. Check Options/Menu opens or closes the expected menu.
4. Toggle off while holding each mouse button. Confirm no stuck drag/click and
   no leaked controller action on release. Toggle repeatedly and hold R3;
   holding it must not switch repeatedly. Confirm normal camera controls return.
5. Disconnect/reconnect the controller, switch maps, save and reload, and return
   to the main menu. Mouse mode must exit cleanly. Test an existing save too.
6. Test `ENABLE_MOUSE_MODE=false` and both debug flags on/off; verify ordinary R3
   behavior when disabled, quiet logs when debug is off, and no duplicated input
   targets/cursors after repeated enable/unload/reload.
7. Inspect fresh game logs before accepting console compatibility. Retain them;
   this project does not configure automatic log deletion.
