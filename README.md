# Mouse Cursor Consoles

A Surviving Mars: Relaunched Lua mod that toggles a left-stick mouse cursor and
temporarily uses the PC interface. Current release: metadata version **7**.

| Action | PS5 | Xbox Series X/S |
| --- | --- | --- |
| Mouse mode on / off | R3 | Right-stick click |
| Move cursor | Left stick | Left stick |
| Hold for 2.5x cursor speed | L2 | LT |
| Left click / hold to drag | Cross | A |
| Right click | Circle | B |
| Wheel up | L1 | LB |
| Wheel down | R1 | RB |
| Menu / Escape | Options | Menu |

Activate the mod and press R3 on any interactive game screen, including the first
main menu with Tutorial, New Game and Load Game. No colony needs to be loaded.
A second press of the same toggle restores the previous control style. The cursor starts in the
screen center on first activation and remembers its last position within the session
by default. Disable Remember cursor position to recenter on every activation. The right stick does not move it. Both native camera
sticks are locked while mouse mode is active; move to the screen edge for the
game's PC camera behavior. Other controller actions are suppressed in mouse mode
to avoid triggering both a mouse action and its original controller action.

By default, hold L2 / LT while moving the left stick to move 2.5 times faster. Release it
to return to normal speed (optional smoothing makes the transition gradual). This is a hold modifier, not a
toggle; it does not change click or wheel behavior. It has no effect outside
mouse mode. Holding it before entering mouse mode also enables the boost.

**R3 normally pauses the game in a colony.** This mod reserves it for the toggle on all screens,
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
the eight files under `Code/`, and `Images/test-not-ready.png` into
`%APPDATA%/Surviving Mars Relaunched/Mods/MouseCursorConsoles`.
It verifies file hashes and does not delete destination files.

PS5/Xbox distribution needs the game's supported publishing/Paradox Mods path;
copying this Windows folder does not install it on a console. No mod-store
publication was performed. Paradox advertises cross-platform mod support on the
[official game page](https://www.paradoxinteractive.com/games/surviving-mars-relaunched/about),
but that does not certify this particular code mod on either console.

Version 7 is deployed locally as a **TEST BUILD - NOT READY** release. Required
metadata and the preview are present. The last verified native `.fpk` package is
version 5; rebuild it before publishing version 7. See [publishing validation](docs/PUBLISHING.md).
Use the Mod Editor's Paradox upload action while signed in to publish the deployed
mod. Store acceptance and console functionality still require verification.

## Cursor settings

Enable the mod, restart the game after installing an update, then open
**Options > Controls > Mouse Cursor Consoles** (the first Controls row).
This also works on PC with a connected controller, including a PS5 controller
recognized by the game. This is the only settings entry; the general Mod Options
list does not include this mod.
The page stays in the native left-side Options layout, retains the animated
menu background, and shows **OPTIONS / CONTROLS / MOUSE CURSOR CONSOLES**.
Action rows, instructions, test area and status align with the slider labels from
page opening and remain aligned during hover and focus.
It uses the game's gold slider bars and supports controller navigation
with mouse mode off. Opening it switches mouse mode off and releases held clicks;
press your configured toggle again after closing settings to resume.

The basic page has **Normal cursor speed**, **Fast cursor speed**, and **Cursor
size %**, plus **Test cursor** and **Advanced settings**. The native bottom bar
provides **Back**, **Default**, and **Apply**. D-pad Up/Down selects a row; Left/Right adjusts
a slider or choice. Mouse dragging works on sliders too. Fast speed is an absolute
speed and must be at least normal speed, not a fixed multiplier.

| Slider | Range | Default |
| --- | --- | --- |
| Normal speed (pixels/sec at 1080p) | 50-4,000 | 900 |
| Fast speed (pixels/sec at 1080p) | 50-8,000 | 2,250 |
| Cursor size | 50-300% | 100% |
| Stick dead zone (out of 32,767) | 0-16,000 | 6,000 |
| Smoothing | 0-150 ms | 0 (off) |

**Advanced** adds the dead-zone and smoothing sliders, Linear/Gradual stick
response, White/Yellow/Cyan cursor tint, Remember cursor position, and all seven
button bindings. Gradual response makes small movements finer without changing
full-stick speed. Smoothing softens changes in velocity but adds delay; releasing
inside the dead zone stops immediately. Every binding must be distinct. Trigger
bindings are supported for the hold-to-boost action only. The toggle is restricted
to L3/R3 stick clicks so normal menu navigation remains available. Native construction
modifiers (multiple placement/show range) are not emulated by these mouse bindings.

Select **Test cursor** to move an isolated preview with the left stick and your
boost button. Circle/B or Escape returns to settings. Preview size/color changes
appear immediately; changes affect the real cursor only after Apply. A connected
controller is required for movement testing, but not for editing the sliders.
Back from the basic page discards the draft and returns focus to Controls.
Back from Advanced returns to basic settings. Default restores draft defaults;
Apply saves them and returns to Controls. On a controller, use Circle/B for Back,
Triangle/Y for Default, and Square/X for Apply.

Preferences use the game's supported per-mod persistent storage and survive
restarts. Cursor coordinates are transient and are never written into colony saves.
The reported Xbox jumping is **not diagnosed or claimed fixed** by these controls.
Console testing of the settings and original gameplay checklist remains necessary.

Developer-only feature/debug flags remain in `Code/mcc_config.lua`:
`ENABLE_MOUSE_MODE=true`, `ENABLE_SPEED_BOOST=true`, `DEBUG_LOGS=false`,
`DEBUG_INPUT=false`. Input diagnostics require both debug flags to be exactly
`true`. Settings logging reports validation, apply/save and dialog lifecycle;
no unconditional runtime logging is added. Use the settings page for user
preferences; the private Controls-page definitions are in `mcc_settings.lua`.

## Ownership and restoration

- `mcc_config.lua`: configuration and transient state in the mod environment.
- `mcc_debug.lua`: explicit boolean-gated diagnostics.
- `mcc_settings.lua`: validation and versioned per-mod preferences.
- `mcc_settings_ui.lua`: native settings entry, draft UI and isolated live preview.
- `mcc_cursor.lua`: left-stick movement, software cursor, mouse-position query override.
- `mcc_input.lua`: input ownership, paired clicks, doubles, wheel repeats and toggle.
- `mcc_lifecycle.lua`: validation, apply/restore, input registration and removal.
- `MouseCursorConsoles.lua`: lifecycle message wiring.

`metadata.lua` is the canonical version and runtime load order; `items.lua`
contains the identical editor registration order. There are no external mod
dependencies, bundled libraries, or colony-save variables. Preferences use mod storage. The publishing
preview is `Images/test-not-ready.png`, displaying "TEST. NOT READY.".
The cursor uses the game's existing cursor images and rollover system.

The one function override, `terminal.GetMousePos`, returns the current software
position while active. Native tests found that a hardware warp can lag a frame.
The original function is retained and restored only if the mod still owns the
override; a later third-party wrapper is preserved with an inactive passthrough.
UI-style changes use `ChangeGamepadUIStyle`, never `SwitchControls`, so the user's
saved control preference is not overwritten. Camera lock ownership is additive.

Toggle-off releases held mouse buttons before removing the cursor. Mouse mode
stays active across new-game, load-game, map-change and return-to-menu transitions;
these transitions release held clicks and cancel repeat scrolling to avoid stale
drags. Engine loading screens may temporarily hide the cursor or block input.
Loss of focus, controller disconnection, external control-style changes, Lua
reload and mod unloading restore the previous controls and turn mouse mode off.
Buttons held across a toggle must be released before producing a new mouse click.

## Verification

Run `lua tests/mcc_settings_behavior.lua` for both deterministic host suites. Native test helpers
under `tests/` cover input, settings and the Controls entry in a disposable Windows debug-game process using the local
`smr-harness`; they are excluded from the payload. See
[validation evidence and source references](docs/VALIDATION.md).

Also verify controller navigation, slider dragging, preview movement/boost, Advanced
scrolling, Default, Back, conflicting bindings, and preference persistence after
a full restart on each console. See [settings validation](docs/SETTINGS.md).

Before promoting the test build to a stable release, perform these checks
separately on PS5 and Xbox Series X/S:

1. Enable the mod, press R3 on the first Tutorial / New Game / Load Game menu,
   and confirm the cursor works there and in setup screens. Start a colony and
   verify mouse mode stays on. Move left stick in all directions; verify dead
   zone, screen edges and speed. Right stick must not move the cursor or camera.
   Hold L2 / LT and confirm faster travel; release it and confirm normal
   speed immediately resumes. Test toggle-off and disconnect while holding it,
   and verify `ENABLE_SPEED_BOOST=false` prevents acceleration.
2. Select a building, open tooltips and menus, double click, drag a slider and
   scrollbar, place/cancel construction, and issue a unit right-click command.
   Confirm exactly one action occurs at the cursor location.
3. Test both wheel buttons over lists and over the colony camera. Hold them to
   check repeat scrolling. Check Options/Menu opens or closes the expected menu.
4. Toggle off while holding each mouse button. Confirm no stuck drag/click and
   no leaked controller action on release. Toggle repeatedly and hold R3;
   holding it must not switch repeatedly. Confirm normal camera controls return.
5. Switch maps, save and reload, and return to the main menu. Mouse mode must
   remain active without stuck clicks or drags. Test an existing save too.
   Disconnect/reconnect the controller and verify mouse mode exits cleanly.
6. Test `ENABLE_MOUSE_MODE=false` and both debug flags on/off; verify ordinary R3
   behavior when disabled, quiet logs when debug is off, and no duplicated input
   targets/cursors after repeated enable/unload/reload.
7. Inspect fresh game logs before accepting console compatibility. Retain them;
   this project does not configure automatic log deletion.
