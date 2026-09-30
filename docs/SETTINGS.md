# Version 12: cursor settings

Entry point: **Options > Controls > Mouse Cursor Consoles**, while the mod is
enabled. Continuous values use the game's `PropNumber` control, including the
same gold bar/thumb artwork as the normal Controls screen.

All 15 settings appear at native Controls size in one left column without scrolling: normal speed,
absolute fast speed, cursor size, dead zone, response curve, smoothing, color,
remembered position and seven distinct button bindings. Back, Default and Apply
remain in the native bottom action bar. The large square test area is centered
in the right half of the screen and responds to the left stick immediately.
The corner is labeled **Test area**. Speed labels include **(px/s)** and Stick response
uses the same right-side `MarsRollover` tooltip as Smoothing. Other permanent
instructions and preview-status text remain removed; save/validation errors appear
only when needed. Toggle
choices are L3/R3 to keep ordinary menu navigation available. Analog triggers are
available for the polled boost modifier only. The README documents ranges/defaults.

## Version 12 validation (2026-09-29)

- Matched native Controls' uniform 35-unit rows and 13-unit gap. Visible slider
  values now use the name's zero padding and height limit, preventing taller rows.
- Preview-only `XImage.ImageRect` excludes transparent padding: read-only
  `D:/PROJS/SMR/fpks/Packs/UI/Cursors/cursor.tga` is 40x40, with an alpha bounding
  box of `(0, 0, 24, 26)`. The visible arrow reaches every edge without changing
  the original asset or gameplay cursor. Size changes invalidate measurement.
- Default boost is hold **L3 / Xbox LS click**; release restores normal speed.
  Schema-1 L2/LT defaults migrate on load if LS is free. Other bindings and LS
  conflicts are preserved. Apply saves schema 2, retaining future explicit L2/LT
  choices. Loading alone does not write preferences.
- `DEBUG_LOGS == true` gates row-layout and migration diagnostics, including
  conflict reasons and the applied boost button. Existing `DEBUG_INPUT == true`
  controls boost-transition logging together with `DEBUG_LOGS`.
- Host: **81 behavior + 56 settings/motion checks passed**, including LS hold,
  release without a button-up event, L2 no longer boosting by default, and migration.
- Actual Windows engine: **41 settings + 25 Controls-entry checks passed** with
  simulated controller input. Verified matching spacing/font/slider size, all 15
  rows without scrolling, square geometry, corner label, visible-image bounds,
  four cursor corners, held LS speed and release, Apply/Back/Default, preferences,
  entry alignment and restoration. Final screenshot reviewed at 3840x2043 shows
  speed units, the native right-side Stick response tooltip, and the arrow at
  the square's bottom-right edge. Reports/screenshots stay ignored in `tests/results`.
- `luac -p` passed for every payload Lua file and all changed test Lua files.
  Runtime load order is unchanged. Deployment copied/hash-verified all 11 payload
  files to `%APPDATA%/Surviving Mars Relaunched/Mods/MouseCursorConsoles`.
- Read-only references: `Lua/XDef/PropNumber.generated.lua`, native Options list
  layout, `CommonLua/X/XImage.lua`, `XWindow.lua`, `XRollover.lua`, and mod storage
  implementation. No game, third-party, generated, asset, or harness source changed.
- Logs read: `MarsDebug.exe-20260929-21.57.40-6aad2de6.log`,
  `MarsDebug.exe-20260929-22.07.51-6aad2de6.log`, retail startup log
  `Mars.exe-20260929-21.54.17-6aad2d75.log`, and matching debug harness logs.
  An earlier debug session hit native account-save sharing violations and modal
  interference; it was not counted as passing. Fresh debug-session final suites
  passed. Final session logs had no Lua-error/assertion/sharing-violation matches.
  Logs were retained; the user's retail game was not stopped.
- Physical PS5/Xbox hardware, console rendering and save/reload gameplay remain
  untested. Restart the game, check both speed labels and the response tooltip,
  hold/release LS in the preview, then move to all four edges. Confirm custom
  bindings survive and the Controls screen restores on Back.

## Ownership and behavior

- `mcc_settings.lua` owns preference validation, read/apply/save, button labels and
  cursor styling. Preferences use `CurrentModStorageTable.settings`, schema 2 (schema 1 remains readable),
  written with the supported `WriteModPersistentStorageTable` API. No direct
  account-storage access is attempted by the deployed mod.
- `mcc_settings_ui.lua` owns a transparent child page and draft inside the
  native Options shell. It reuses the shell safe margins, title and action-bar
  classes, retaining the existing animated background. The original Controls
  content, title and footer are hidden and folded while this page is open; their
  prior visibility/folding and entry focus are restored on close. The Options
  container stretches during the page and restores its original alignment on close. `XWindowRecreated`
  adds a native menu button at the top of the Controls list before its selection index is rebuilt.
  Only lists inside an OptionsDlg in the Controls category are extended. Rebuilding
  creates exactly one row; shutdown and parent closure clear mod-owned entries.
  No vanilla method/class is overridden. There is no general Mod Options entry;
  the Controls page uses a private PropertyObject draft with the same 15 properties.
- The actual cursor and test area share the same velocity calculation. Preview
  input never moves the game's mouse or dispatches clicks into the underlying UI.
- Opening settings releases held clicks and exits mouse mode, restoring its prior
  control style. The D-pad navigates and edits while the left stick drives the
  test-area cursor, including when tuning and binding rows are selected.
  Closing the page leaves mouse mode off; press the configured toggle to resume it.
- Draft changes preview size/color and movement without changing gameplay.
  Invalid ranges, fast speed below normal, and duplicate bindings block Apply.
  Back discards edits. Default changes the draft; Apply is required to save.
- Save failures report an error on the page and preserve previous settings.
  Unsupported or corrupt stored settings are rejected with boolean-gated diagnostics.
- Smoothing is off by default. It filters velocity, not cursor position, and stops
  immediately inside the dead zone. Frame deltas remain capped at 50 ms.
- Remembered position is enabled by default and lasts within the running mod
  session. It is clamped/scaled to the display on reactivation. Coordinates and
  UI objects are never persisted in colony saves.
- Open settings modals and Controls entries are cleaned up on shutdown/reload.
  Parent closure removes the modal; the preview ends with the page.

Version in `metadata.lua` is **11**. Both manifests load eight code files in the same
order, with settings data before the cursor and settings UI before entry hooks.
`items.lua` registers code only. Private property definitions belong to
`mcc_settings.lua`; metadata advertises no generic options. Deployment has 11 files.

`DEBUG_LOGS=false` and `DEBUG_INPUT=false` remain explicit booleans. Settings logs
cover validation, loading, save errors/requests, applied values, and dialog lifecycle;
they use the existing debug gate. There is no unconditional mod debug output.
No original cursor artwork or TEST. NOT READY. preview image was changed.

## Version 11 verification (2026-09-29)

Restored the controls from 85% to their native scale while retaining compact
row spacing. Removed permanent instruction/status labels. A mod-owned layout
callback uses the native `SetLayoutSpace` API to center the 1:1 preview at three
quarters of screen width and half of screen height, clear of the settings,
title and footer. Layout size/center diagnostics use `DEBUG_LOGS == true`.

Fixed incomplete preview travel: `XWindow.UpdateMeasure` includes margins in
`measure_width/height`, so subtracting those values also subtracted the cursor's
current offset. Preview bounds now subtract the rendered cursor box, clamp on
every frame, and account for the motion function's inclusive final pixel. The
shared gameplay cursor/motion implementation is unchanged.

Read-only game references: `XWindow.UpdateMeasure`, `SetBox`, `OnLayoutComplete`
and `SetLayoutSpace`, plus `XAspectWindow` and the exported `Min` API. No game,
protected, generated, third-party or image source was edited. Load order and
both explicit false debug flags are unchanged.

Passed 35 native settings and 25 native entry/restoration checks. New assertions
compare text/slider sizes with native Controls, verify square geometry and screen
centering, drive the cursor to all four corners, and retain visible validation
errors. All 15 rows remain visible without scrolling. Visual review at 3840x2043
confirmed a 1398x1398 square centered at (2880,1022), with no preview text.
Ignored evidence: `tests/results/settings-v11-centered-square.png`,
`native-settings-v11.json` and `native-entry-v11.json`.

All 17 payload/test Lua files passed syntax checks, along with 81 behavior and
48 settings/motion host checks. All 11 deployment files were hash-verified.
Reviewed retail startup log `Mars.exe-20260929-21.42.12-6aad2d75.log` and debug log
`MarsDebug.exe-20260929-21.50.05-6aad2de6.log`; the latter had no Lua errors or
assertions. Logs were retained.

Manual check: restart, open the cursor settings, compare option size with Controls,
and move the stick to every corner of the centered square. Confirm all rows fit,
then check Default, Apply and Back. Physical console controllers, console rendering
and other display sizes remain unverified.

## Historical version 10 verification (2026-09-29)

Removed the Advanced page and scrollbar. Native controls at 85% scale fit all 15
rows in the left column; the right preview uses the native `XAspectWindow` with
`Aspect=point(1,1)` and fits the available space as an exact square. The original
Options container alignment is saved and restored when the page closes.
All numeric controls use native `dpad_only` metadata, and choice rows accept
D-pad adjustment while the left stick remains dedicated to the preview.

Read-only references: `PropNumber`, `MenuEntrySmall`, `OptionsContentWindow`,
`XWindow`, `XScroll`, `XAspectWindow` in `XControl.lua`, and `PGMainMenu`.
No game, generated, protected, third-party or image source was edited.
The existing `DEBUG_LOGS=false` gate covers row count, layout and controller
diagnostics; `DEBUG_INPUT=false` is unchanged.

Passed 27 native settings checks and 25 native entry/restoration checks,
including all rows fitting above the footer, reaching the last row without
scrolling, equal preview width/height, immediate movement and restoration of
the native container alignment. The actual PGMainMenu page was visually checked
at 3840x2043: the preview measured 1219x1219 pixels. Screenshot and reports are
ignored under `tests/results/settings-v10-square.png`, `native-settings-v10.json`
and `native-entry-v10.json`. All 17 payload/test Lua files passed syntax checks;
81 behavior and 48 settings/motion host checks passed. All 11 payload files were
deployed and hash-verified. The final debug game log
`MarsDebug.exe-20260929-21.32.01-6aad2de6.log` had no Lua errors or assertions;
it and the recent retail startup log were reviewed and retained.

Manual check: restart, open Options > Controls > Mouse Cursor Consoles and verify
all 15 rows are visible, the preview is square, and the left stick stays inside
it while the D-pad edits any row. Check Apply, Default and Back. Physical console
controllers, console rendering and other display sizes remain unverified.

## Historical version 9 verification (2026-09-29)

The basic page now polls the active controller's left stick as soon as it opens.
It uses the existing isolated preview motion and draft settings, including the
hold-to-boost binding. The Test cursor row and its focus mode were removed.
Native `XList.LeftThumbScroll=false` and the three basic `PropNumber` fields'
supported `dpad_only` metadata reserve the left stick for preview movement;
the D-pad still navigates and edits. Advanced restores native stick navigation.
The test-area label now describes the immediate control. Controller connection
changes are logged only when `DEBUG_LOGS == true`.

All 24 native settings checks passed with simulated controller state, including
immediate movement, absence of the Test cursor row, D-pad adjustment, unchanged
basic selection/slider values under stick input, and Advanced navigation. All
24 native Controls-entry checks also passed. Lua syntax passed for 17 payload
and test files; host suites passed 81 behavior and 48 settings/motion checks.
The debug game loaded version 9; all 11 payload files were hash-verified in the
local deployment. The rendered basic page was reviewed with four rows and the
updated test-area instruction. An exploratory screenshot-helper command caused
an unrelated `rawset` argument error in the first debug log. A fresh debug run
passed both native suites, and its game log had no Lua errors or assertions.
Game, protected, generated and third-party sources were not edited. Game and
harness logs were reviewed and retained.
Physical PS5/Xbox controller and console rendering remain to be checked.

Manual check: restart the game, open Options > Controls > Mouse Cursor Consoles,
move the left stick without selecting a row, then hold the configured boost
button. Confirm the cursor stays inside the test area, the D-pad edits sliders,
and Apply and Back behave normally. Enter Advanced and return to the basic page
to confirm preview movement resumes.

## Version 8 verification (2026-09-29)

The Mouse Cursor Consoles entry in native Controls now uses the same mod-owned
menu-row builder as the aligned Test cursor and Advanced settings rows. That
builder removes unused inherited label/icon spacing and keeps the label margin
stable during hover. The entry retains its ID, first-row order, controller
activation, rebuild cleanup and settings route. Cursor and preference behavior
are unchanged.

The first owned `MarsDebug.exe` process crashed during startup before the mod
loaded. Its WER report records an `ntdll.dll` heap exception (`c0000374`);
there is no Lua error or UI execution in its 628-byte game log. The crash evidence
was preserved under `smr-harness/logs/incidents/20260930-011006-18d9f3ffc391e28c/`.
A fresh owned process loaded version 8 and passed all 24 native Controls-entry
checks, including initial, hover and focus alignment, controller opening,
return focus, and cleanup. The actual PGMainMenu Controls rendering was
visually reviewed: the mod entry and Invert Mouse Wheel label both measured
x=313 at 3840x2043. The final debug log had no Lua errors or assertions.
Evidence is ignored under `tests/results/native-entry-v8.json` and
`tests/results/controls-v8-aligned.png`.

Lua syntax passed for all payload files and tests; host suites passed 81
behavior and 48 settings checks. All 11
payload files were deployed and hash-verified in the local mod folder. The
existing `DEBUG_LOGS=false` gate covers the Controls-entry alignment diagnostic;
`DEBUG_INPUT=false` is unchanged. The read-only game references were
MenuEntrySmall, PropNumber and OptionsContentWindow. Game, protected, generated,
third-party and image files were not edited. Reviewed game and harness logs were
retained. No v8 native package or mod-store upload was made.

Manual check: restart the game, open Options > Controls, and compare Mouse Cursor
Consoles with Invert Mouse Wheel before selecting anything; then hover/select it
and confirm the left edge remains aligned. Console rendering remains unverified.

## Historical version 7 verification (2026-09-29)

Test cursor, Advanced settings, the D-pad instructions, test-area label and
preview status now share the Normal cursor speed text column on initial opening.
Mod-owned menu rows omit unused inherited label/icon layout space and keep their
margin on hover/focus. Instructions account for the native scrollbar's reserved
width and use explicit horizontal text padding. Cursor motion, preferences,
background, vertical spacing, assets and load order are unchanged.

Read-only references: MenuEntrySmall, ScrollbarNew and PropNumber definitions;
XButton, XLabel, XImage, XControl and XText. Only mod-owned UI instances change;
no game, generated, protected or third-party source was edited. The existing
DEBUG_LOGS=false gate reports `label_alignment=controls_column` when enabled;
DEBUG_INPUT=false is unchanged.

Lua syntax passed for the payload. A native layout probe measured all six text
origins at x=313 on opening, hover and focus (3840x2043 Windows rendering), and the
rendered page was visually reviewed. Native entry and settings suites passed
21 and 22 checks. Local ignored evidence: `tests/results/alignment-v7.json`,
`native-entry-v7.json`, `native-settings-v7.json`, and `settings-v7-aligned.png`.
All 11 payload files were copied and hash-verified in the configured local mod
folder. No package or store upload was made.

Reviewed the available startup portion of the active retail log
`Mars.exe-20260929-20.54.54-6aad2d75.log`, plus debug log
`MarsDebug.exe-20260929-21.01.07-6aad2de6.log` and harness log
`daemon-20260930-010107.log`. The debug checks had no Lua errors or assertions.
Logs were retained, and the user's retail game process was left running.

Manual check: restart, open the page, and confirm the five requested labels align
with Normal cursor speed immediately and while hovering/selecting the action
rows. Physical-console rendering and in-colony behavior remain untested.

## Historical version 6 verification (2026-09-29)

Replaced the centered opaque screen with a child page in the existing Options
shell. The title reads OPTIONS / CONTROLS / MOUSE CURSOR CONSOLES; Advanced adds
one more breadcrumb. Sliders retain native Controls alignment and spacing.
The footer now owns Back/Default/Apply and their native controller shortcuts.
This changes presentation/navigation only: cursor motion, bindings, preference
validation, storage schema, and gameplay lifecycle are unchanged.

- Lua 5.4 syntax checks passed for all payload and test files. The host suites
  passed 81 behavior and 48 settings/motion checks.
- The Windows debug engine passed 21 native entry checks and 22 native settings
  checks: shared shell, transparency, breadcrumb, row alignment, native footer,
  repeated open, restored visibility/focus, parent cleanup, preview, validation,
  defaults, cancel, apply and persistence. Controller events/state were simulated.
- Visually inspected the actual PGMainMenu Options route, basic page, Advanced,
  and the bottom of the scrolling Advanced list. The Mars video remained visible
  and animated across captures. Evidence is ignored under `tests/results/`.
- An initial integration run caught reserved space from the hidden native title
  and an incorrect focus lookup. The fix restores both visibility and folding
  and resolves the return entry through its owning list. Subsequent checks pass.
- The load helper now forces item reload after refreshing mod definitions and
  waits for the new environment. Its earlier stale-environment test errors are
  retained in the first debug log; they were test-fixture failures.
- Read-only engine references: OptionsDlg, OptionsContentWindow, DialogTitleNew,
  ActionBarNew, NewOverlayDlg and PropNumber generated definitions; XDialog,
  XWindow, XDesktop, Mod.lua and PGMainMenu. No game, generated, harness or
  third-party source was edited. Original assets and manifest load order remain
  unchanged.
- Existing boolean DEBUG_LOGS (false) gates `open_rejected`, page-open layout and
  background information, `controls_restored` and close diagnostics. DEBUG_INPUT
  remains false and unchanged.
- Reviewed retail logs `Mars.exe-20260929-19.53.03-6aad2d75.log` and
  `Mars.exe-20260929-19.51.45-6aad2d75.log`: v5 loaded, no relevant Lua error.
  Reviewed the first debug session `MarsDebug.exe-20260929-19.58.20-6aad2de6.log`
  for the fixture errors above. The final debug log
  `MarsDebug.exe-20260929-20.05.21-6aad2de6.log` and harness log
  `daemon-20260930-000520.log` contain no Lua errors or assertion failures through
  the final checks and captures. Logs are retained; no deletion workflow is configured.
- All 11 payload files were deployed and SHA-256 verified in the configured local
  MouseCursorConsoles folder. No store upload or v6 package build was performed.

Manual checks: restart the game and open Options > Controls > Mouse Cursor
Consoles. Check the animated background and complete breadcrumb, adjust a slider,
use Default and Apply, reopen to check persistence, then use Back twice through
Advanced and verify focus returns to Controls. Repeat in a colony and on PS5/Xbox.
Physical controllers, console rendering and in-colony/save-load behavior were
not verified by this Windows menu test.

## Historical version 5 verification (2026-09-27)

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
slider, preview normal/boosted movement, and change a binding in the single left column.
Check invalid bindings are rejected, Cancel preserves old values, Reset requires
Apply, and settings survive quitting/relaunching the game. Then repeat the
README's gameplay/restoration checks and report whether the jumping changes.
