# Version 5: cursor settings

Entry point: **Options > Controls > Mouse Cursor Consoles**, while the mod is
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
- `mcc_settings_ui.lua` owns the modal and draft. `XWindowRecreated` adds a native
  menu button at the top of the Controls list before its selection index is rebuilt.
  Only lists inside an OptionsDlg in the Controls category are extended. Rebuilding
  creates exactly one row; shutdown and parent closure clear mod-owned entries.
  No vanilla method/class is overridden. There is no general Mod Options entry;
  the Controls page uses a private PropertyObject draft with the same 15 properties.
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
- Open settings modals and Controls entries are cleaned up on shutdown/reload.
  Parent closure removes the modal; focus loss exits preview testing.

Version in `metadata.lua` is **5**. Both manifests load eight code files in the same
order, with settings data before the cursor and settings UI before entry hooks.
`items.lua` registers code only. Private property definitions belong to
`mcc_settings.lua`; metadata advertises no generic options. Deployment has 11 files.

`DEBUG_LOGS=false` and `DEBUG_INPUT=false` remain explicit booleans. Settings logs
cover validation, loading, save errors/requests, applied values, and dialog lifecycle;
they use the existing debug gate. There is no unconditional mod debug output.
No original cursor artwork or TEST. NOT READY. preview image was changed.

## Version 5 verification (2026-09-27)

Removed native ModItemOption registrations, metadata defaults and the old
DialogSetMode route. The same property definitions now belong to the Controls
page. Drafts read validated runtime configuration, so the native loader clearing
its empty option cache cannot reset the displayed preferences. Schema 1 storage
and cursor motion, mappings, option ranges and artwork are unchanged.

- Lua syntax passed for payload and test files; 81 behavior + 48 settings host
  checks passed. All 14 native entry and 22 native settings checks passed, covering the unique Controls entry, absence
  from the general mod list, controller confirm/back/focus, cleanup, sliders,
  preview, persistence and resilience to native cache clearing.
- References inspected read-only: Mod.lua (native list properties, defaults and
  cache lifecycle), PropertyObject.lua and OptionsContentWindow.generated.lua.
- Logs reviewed: retail Mars.exe-20260927-20.17.17-6aad2d75.log and debug daemon
  20260928-002207.log (no Lua errors/assertion failures during the checks).
  Logs retained; game/harness/third-party sources untouched.
- Production files: metadata.lua, items.lua, mcc_settings.lua and mcc_settings_ui.lua.
  Existing DEBUG_LOGS and DEBUG_INPUT boolean gates remain false; settings open,
  close, validation, apply/save and Controls-entry diagnostics remain available.
- All 11 payload files deployed and hash-verified. User game process was left alone.
  AGENTS.md and CLAUDE.md remain excluded. Physical controller/console operation
  and in-colony save/load remain unverified by these Windows simulated-input tests.

Manual check: restart, verify only Options > Controls > Mouse Cursor Consoles
opens these settings, change a slider, Apply, and reopen to confirm the value.

Mouse Edge Scrolling is a vanilla PC option. ProjectOptions.lua registers it
with FilterNonConsoleOption; Lua/Config/_fixup.lua returns not Platform.console.
A controller attached to a PC does not make it a console build. The mod currently
adds no equivalent console edge-scroll option; this update does not change that.

## Historical version 4 verification (2026-09-27)

The missing menu in version 3 was caused by absent `metadata.default_options`:
native `ModDef:HasOptions()` and `HasModsWithOptions()` use that table to decide
whether to expose Mod Options. The previous entry test jumped directly to
`mod_choice`, bypassing the hidden category. Version 4 provides all 15 defaults
and adds the requested Controls route. No cursor motion or binding behavior changed.

- Syntax checks passed for every payload and test Lua file.
- Host checks: 81 behavior checks and 55 preference/motion checks passed. The new
  metadata/default contract failed against version 3 before the metadata fix.
- Native Windows engine: 18 entry checks passed, starting from the Options root,
  including Controls placement, controller confirm/back/focus return, rebuilds,
  shutdown/reinstallation, parent cleanup and the legacy Mod Options route.
- Native settings: all 21 slider, preview, validation and persistence checks passed.
  The test now explicitly binds its simulated controller to slot 0 in the mod
  environment and restores the previous value; the real active controller was 4.
  An initial fixture run incorrectly mixed that real slot with simulated slot 0.
- Main-menu Controls rendering was inspected using the real PGMainMenu Options
  mode, rather than overlaying a standalone OptionsDlg on the main menu.
- All 11 deployed files were hash-verified. Native packaging/unpacking matched
  all 11 source files. No store upload was performed; see PUBLISHING.md.
- Production changes are confined to metadata, settings UI, and the shutdown
  cleanup call. Controller motion, input mappings, assets and saved schema are unchanged.
- New `controls_entry_added` and `controls_entries_removed` diagnostics use the
  existing exact-boolean `DEBUG_LOGS` gate (default false). `DEBUG_INPUT` is unchanged.
- Read-only engine references: CommonLua/X/XDef.lua (`XWindowRecreated` timing),
  XWindow.lua (child sorting), XDialog.lua, CommonLua/Modding/Mod.lua,
  Lua/XDef/OptionsContentWindow.generated.lua, OptionsDlg.generated.lua,
  MenuEntrySmall.generated.lua and Lua/XTemplates/PGMainMenu.lua.
- Reviewed retail logs from 19:31 and 19:38 and debug daemon log 234357. The retail
  session loaded v3; its SuperBigMap terrain error is unrelated. Debug test-fixture
  errors were corrected (controller slot and package-output setup). Logs were retained.
- Repeated both native suites in a fresh owned debug process. All 39 checks passed;
  `MarsDebug.exe-20260927-19.47.49-6aad2de6.log` and daemon log 234749 contained
  no Lua errors or assertion failures through the final UI captures. The owned
  test process was stopped afterward; no user game process was stopped.
- Game installation, harness source, third-party mods and original assets were
  not edited. AGENTS.md and CLAUDE.md remain excluded from Git and deployment.
- Physical-controller operation, PS5/Xbox rendering and in-colony/save-load
  gameplay remain manual checks; Windows simulated-input tests do not certify them.

Manual check: restart with v4 enabled, open Options > Controls, select Mouse Cursor
Consoles, adjust a speed with D-pad Left/Right, choose Test cursor, then Apply.
Reopen to verify persistence; Circle/B should return to Controls. Repeat in a colony.

## Historical version 3 verification (2026-09-27)

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
