# Test-build publishing validation

## Current: version 10 (local payload)

The single-page settings and large square test area are deployed locally.
Required metadata and the existing TEST BUILD - NOT READY image are retained.
No v10 native package or store upload was produced. Rebuild the package before publishing;
the verified v5 package below contains the previous settings layout.
See [settings validation](SETTINGS.md).

## Historical: version 5

Controls is now the only entry for this mod's settings. General Mod Options
registration was removed without changing saved preferences or cursor behavior.

- Lua syntax, 129 host checks and 36 native menu/settings checks passed.
- Native pack/unpack: **435,210 bytes**, **11 files**, all hashes match source.
- SHA-256: `5B76A7A79E52536B38D24F5E9B7D067362B7C970E27D9BDD7171E218DC4C0640`.
- Local evidence: `tests/results/package-v5-20260927/`.
- Deployed locally; no mod-store upload performed. Physical-console operation
  remains unverified. Existing TEST BUILD - NOT READY preview retained.

## Historical: version 4

The Controls-menu update is deployed locally and prepared as a test build; it has
not been uploaded to a mod store. See [settings validation](SETTINGS.md).

- Native pack/unpack: **435,224 bytes**, **11 files**, all SHA-256 identical to source.
- Package SHA-256: `43834E31BF32126DBCCEF00EF01F689571049BBB9ACCF93E9191E826F2469992`.
- Local evidence: `tests/results/package-v4-20260927/`.
- Lua syntax, 136 host checks and 39 native menu/settings checks passed.
- Metadata version 4 includes the 15 option defaults required for native menu
  visibility. Eight code modules and the existing test-preview image are included.
- Store acceptance and physical console operation remain unverified.

## Historical: version 3

The settings update is prepared for upload as a test build. See
[settings implementation and validation](SETTINGS.md) for the new behavior and
console test checklist. It has not been uploaded to a mod store.

- Required metadata and the existing 421,009-byte preview passed native checks.
- Native `AsyncPack` produced a **433,963-byte** `ModContent.fpk`; `AsyncUnpack`
  recovered all **11 files**, SHA-256 identical to the current repository payload.
- Package SHA-256:
  `CCE1D05B3DD7AB91D9565A9802D5D5E150D7E8026B7C4DEE02FCF58FEC6441B5`.
- Local package/report/hash evidence: `tests/results/package-v3-final-20260927/`.
- Both manifests contain eight ordered code modules; items.lua additionally
  registers the 15 settings. Tests, docs, tooling and instruction files are excluded.
- Syntax, 120 host checks and 49 native checks passed. Physical consoles and
  store acceptance remain untested. The test preview and description remain in place.

Upload the deployed mod through the game's Mod Editor while signed in to Paradox.
The editor builds its own package. The verification above uses the same native
packer directly; it does not perform authentication or network publication.

## Historical: version 2

Checked on 2026-09-27 using Windows MarsDebug.exe, Lua revision 405907.
Version **2** is prepared for upload as a test build. No Paradox upload was made;
account authentication, store acceptance and console execution are unverified.

## Metadata and package

- Added the required `short_description` with an explicit TEST BUILD - NOT READY
  label and the console-testing requirement. It is below the 200-character limit.
- Title, description, Lua revision and preview reference were checked against the
  loaded native ModDef. Preview: 421,009 bytes, below the uploader's 2 MB limit.
- Built `ModContent.fpk` with the engine's `AsyncPack`, using the same source/dest
  index format as `CreatePackageForUpload` in `CommonLua/Classes/GedModEditor.lua`.
  The output is 422,271 bytes, below the publisher's 5 GB limit.
- Unpacked it with native `AsyncUnpack`; SHA-256 comparison verified all nine
  unpacked files byte-for-byte against repository sources. No extra files exist.
- Package SHA-256:
  `6E930359D212F603EAAE8AF06EE11A5D63A450993740A5CEC9FA1C978966C7C7`.
- Evidence and package are retained locally in
  `tests/results/package-20260927-124423/` (ignored by Git).

The package contains metadata.lua, items.lua, the six registered Code scripts and
Images/test-not-ready.png. AGENTS.md, CLAUDE.md, tests, docs and tooling are excluded.
Both instruction files remain excluded from GitHub's current tree too.

`tests/mcc_native_package.lua` is an optional native package check, excluded from
deployment. In an owned debug-game process, set `MCCPackageOutput` to a new,
project-owned absolute directory, then run the helper through smr-harness.
Read `MCCPackageReport` after `complete` becomes true; `passed` must be true.
Compare each unpacked file's hash with its source as a separate host-side check.
The helper refuses an existing output directory and unsaved editor changes.

The native packer was used directly to preserve an existing unrelated package in
the publisher's shared temporary directory. No engine override or compression
workaround was used. This checks the payload's native packing/unpacking; it does
not exercise the editor's save/reload steps, authentication or network upload.

## Validation and ownership

- `luac -p` passed for all eight payload Lua files and the new package helper.
- Existing host suite: 79 behavioral checks passed.
- Deployment verified hashes for all nine files in the configured local
  `Surviving Mars Relaunched/Mods/MouseCursorConsoles` directory; no deletion.
- Read the fresh game log `MarsDebug.exe-20260927-08.44.23-6aad2de6.log` and harness
  log `daemon-20260927-124423.log`; no `[LUA ERROR]`, `Assertion failed`, or
  `blkPageCompress` matches. Shutdown messages include a missing shader hook and
  one uncleaned video, with an orderly exit code 0. Logs were retained.
- Two early diagnostic CLI expressions had quoting/argument syntax errors;
  corrected file-based probes and the actual package check succeeded.
- The owned test process (PID 62736) was stopped. No enabled-mod preferences were
  changed, and no other game process was stopped.
- Read-only API references: `CommonLua/Classes/GedModEditor.lua`,
  `CommonLua/Libs/Paradox/ParadoxMods.lua`, `CommonLua/Modding/Mod.lua`, and
  `CommonLua/LuaExportedDocs/Global/AsyncOp.lua` in the local game sources.
- Gameplay, load order, artwork and debug flags (`DEBUG_LOGS=false`,
  `DEBUG_INPUT=false`) are unchanged. No runtime logs were added. Canonical
  metadata version remains 2 because this only adds publishing metadata/tooling.
- No game-installation, protected, third-party or harness source files were edited.

## Upload and console handoff

Open the deployed Mouse Cursor Consoles mod in the game's Mod Editor, sign in to
Paradox, and use its Paradox upload action. The game builds its own upload package.
Keep the test-build description and TEST. NOT READY. preview until testing passes.
After publication, confirm the listing is available to the tester on each target
console. GitHub availability alone is not console installation support.

The tester should follow the README's console checklist: first main-menu toggle,
left-stick movement, hold/release L2/LT speed boost, click/drag/right click/wheel,
toggle-off restoration, controller disconnect, colony play and save/load.
These hardware and gameplay checks are still pending.
