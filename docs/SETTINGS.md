# Version 3: cursor settings

Entry point: **Options > Mod Options > Mouse Cursor Consoles**, while the mod is
enabled. Continuous values use the game's `PropNumber` control, including the
same gold bar/thumb artwork as the normal Controls screen.

The main view contains normal speed, absolute fast speed, cursor size, Test cursor,
Advanced, Reset, Apply and Cancel. Advanced contains dead zone, response curve,
smoothing, color, remembered position and seven distinct button bindings. Toggle
choices are L3/R3 to keep ordinary menu navigation available. Analog triggers are
available for the polled boost modifier only. The README documents ranges/defaults.

## Ownership and behavior

- `mcc_settings.lua` owns preference validation, read/apply/save, button labels and
  cursor styling. Preferences use `CurrentModStorageTable.settings`, schema 1,
  written with the supported `WriteModPersistentStorageTable` API. No direct
  account-storage access is attempted by the deployed mod.
- `mcc_settings_ui.lua` owns the modal and draft. `DialogSetMode` opens it for this
  mod's native entry only. No vanilla method/class is overridden for the settings
  page. The native option items remain registered so the mod appears in Mod Options.
- The actual cursor and test area share the same velocity calculation. Preview
  input never moves the game's mouse or dispatches clicks into the underlying UI.
- Opening settings releases held clicks and exits mouse mode, restoring its prior
  control style. Controller input then follows normal UI navigation. Closing the
  page leaves mouse mode off; press the configured toggle to resume it.
- Draft changes preview size/color and movement without changing gameplay.
  Invalid ranges, fast speed below normal, and duplicate bindings block Apply.
  Cancel discards edits. Reset changes the draft; Apply is required to save.
- Save failures report an error on the page and preserve previous settings.
  Unsupported or corrupt stored settings are rejected with boolean-gated diagnostics.
- Smoothing is off by default. It filters velocity, not cursor position, and stops
  immediately inside the dead zone. Frame deltas remain capped at 50 ms.
- Remembered position is enabled by default and lasts within the running mod
  session. It is clamped/scaled to the display on reactivation. Coordinates and
  UI objects are never persisted in colony saves.
- Pending-open threads and open settings modals are cleaned up on shutdown/reload.
  Parent closure removes the modal; focus loss exits preview testing.

Version in `metadata.lua` is **3**. Both manifests load eight code files in the same
order, with settings data before the cursor and settings UI before entry hooks.
`items.lua` also registers 15 native option definitions. Deployment has 11 files.

`DEBUG_LOGS=false` and `DEBUG_INPUT=false` remain explicit booleans. Settings logs
cover validation, loading, save errors/requests, applied values, and dialog lifecycle;
they use the existing debug gate. There is no unconditional mod debug output.
No original cursor artwork or TEST. NOT READY. preview image was changed.

## Verification performed (2026-09-27)

- Lua 5.4 syntax checks passed for all payload files and test helpers.
- Host suites: **81 input/lifecycle checks + 39 preference/motion checks** passed.
  New checks cover defaults matching the native metadata, invalid/duplicate
  bindings, numeric limits, response curves, independent fast speed, frame-rate
  and resolution scaling, smoothing/release, persistence loading and write failure.
- Windows native `MarsDebug.exe`, Lua revision 405907: mod load and runtime API
  validation passed without mod load errors.
- Native settings suite: **21 checks passed**, including the real gold slider,
  controller slider adjustment, readable Advanced labels, size preview, isolated
  movement, return from preview, binding validation, Reset/Cancel/Apply, supported
  persistent-storage readback, loading preferences and modal cleanup.
- Native menu-entry suite: **6 checks passed**, including the actual Mod Options
  listing, opening, return, reopening, pending-thread cancellation and parent close.
- Existing native input suite: **22 checks passed**, including native UI clicks,
  wheel input, boost/release, exact software/native cursor position agreement,
  remembered position, restoration, disconnection and reinstallation.
- Native tests simulate controller state; they do not use a physical controller.
  Test preference changes were restored afterward, along with the original control
  style. The user's enabled-mod list was restored by the load helper.
- Captured and visually inspected the main and Advanced pages, including reaching
  the bottom of the Advanced list. Captures under `tests/results/` are ignored by
  Git. This is Windows rendering evidence, not console rendering evidence.
- Built the final `.fpk` with native `AsyncPack` and unpacked with `AsyncUnpack`.
  All **11 files** matched repository sources by SHA-256. See PUBLISHING.md.
- Deployment copied/hash-verified all 11 files to the configured local Mods folder.

Early development checks exposed missing `Translate=true` on text controls,
attempted access to sandbox-blocked account storage, and translated option names
being printed as table addresses. Those were corrected. The first entry test also
needed to wait for the native list's asynchronous rebuild. The input fixture now
declares its own cursor image instead of asking the engine for an empty cursor.
The original failing evidence/logs were retained, not counted as passing tests.

Logs reviewed: `MarsDebug.exe-20260927-14.53.53-6aad2de6.log` and
`MarsDebug.exe-20260927-15.00.58-6aad2de6.log`, plus corresponding harness logs
`daemon-20260927-185353.log` and `daemon-20260927-190058.log`.
The fresh final session contains no `[LUA ERROR]`, `Assertion failed`, or
`blkPageCompress` matches. No logs were deleted.

## Read-only game references

- `CommonLua/Modding/Mod.lua`: native option definitions, editor context, sandbox,
  per-mod persistent storage and option-loading lifecycle.
- `Lua/XDef/PropNumber.generated.lua`: slider artwork, property binding and D-pad input.
- `Lua/XDef/OptionsContentWindow.generated.lua`, `OptionsDlg.generated.lua`:
  Mod Options listing, native page modes and controller navigation.
- `CommonLua/X/XDialog.lua`, `XList.lua`, `XImage.lua`: modal lifecycle, lists,
  image scaling and tint.
- `CommonLua/Modding/ModItem.lua`: translation of option metadata names.

All references are from the local game installation. No game-installation,
generated, protected, third-party or harness source files were edited. The two new
runtime modules and all helper code are mod-owned. AGENTS.md and CLAUDE.md remain
local/ignored and are excluded from both GitHub's current tree and the payload.

## Still requires console verification

The reported Xbox cursor jumping has not been reproduced or diagnosed. These
settings provide adjustment controls; they are not evidence that jumping is fixed.
Physical Xbox/PS5 controller behavior, console UI layout, full game-restart
preference persistence on console, colony interactions and actual save/reload
gameplay remain unverified. No store upload was performed.

On each console: enable the mod, open its settings without mouse mode, adjust each
slider, preview normal/boosted movement, scroll Advanced and change a binding.
Check invalid bindings are rejected, Cancel preserves old values, Reset requires
Apply, and settings survive quitting/relaunching the game. Then repeat the
README's gameplay/restoration checks and report whether the jumping changes.
