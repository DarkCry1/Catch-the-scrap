# Development — v1.5 stage guardians

The current baseline is the **user-uploaded v1.4 place**, recovered as 84 source
files with their embedded instance hierarchy. See [import record](IMPORTED_V14.md).
The current release adds seven stage guardians; it does not revert the game to
v1.0. The older release documents are historical.

Read [guardian design and verification](STAGE_GUARDIANS_V15.md) for the current
speed/size table, source mechanics, navigation and testing limits, and the
[Windows Studio guide](STUDIO_START_SV.md) for manual checks.

## Retained v1.4 game

- 61 Robotdex species, each belonging to a rarity and a Build or Box source.
  Completed builds roll species rather than selecting a blueprint in advance.
- Six starting platforms, maximum eight through rebirth. Rebirth retains the
  collection and permanent rewards; resets workshop robots, cash and upgrades.
- Gold ×2 and Rainbow ×4 mutations, collection milestones, cosmetics/titles,
  three daily quests and new-player guidance.
- Matching recipes: Common 5, Uncommon 7, Rare 10, Epic 12, Legendary 15,
  Mythic 18, Celestial 20. Base incomes 5/10/20/45/100/225/500; species,
  mutation, collection perks and rebirth determine final production.
- Persistent SaveService/SaveSchema using UpdateAsync and session locks,
  autosave, leave/shutdown handlers and session-only fallback if unavailable.
  DataStore keyspace/schema were not changed in this release.
- v1.4 two-hand carrying implementation, larger alternating workshops, rare
  box events, rarity cinematics, sound/mute, button effects and TopStack.
- Admin UserId 11824623188, local Studio test allowance and personal owner;
  all permissions, cash, upgrades, ownership and rewards checked on server.

## Structure

`src/shared` holds pure rules, layouts, palettes and native-part geometry.
`src/shared/Engine/CarryRigMath` is an engine-dependent shared helper, preserved
at its original embedded path. `src/server/Assets` builds models;
`src/server/Services` owns gameplay. `src/client` contains presentation and input.

There is one server Script, one LocalScript, 87 ModuleScripts and two
RemoteEvents (Action and Feedback). Guardians add no new client attack remote.
Models and scenery are generated at Play time. Eight players can own workshops.
The yard is 160 × 3360 studs, seven zones, with 64-stud perimeter walls. Main
HUD, game copy and prompts are English; user guidance is Swedish.

SecurityService now manages the seven walking guardians instead of the old
Epic+ drone groups. Existing Drone* packet/attribute names remain compatible
with retained Feel/audio/quest code, but visible text refers to guardians.
Generated world geometry is passed to static navigation grids. Motors animate
nearby on clients; server state alone decides catches and escaped-loot credit.

## Check and build

```sh
source /workspace/.catch-the-scrap-tools/activate.sh
python3 scripts/check.py
```

Requires Python 3, Rojo 7.7.1 and Luau CLI 0.744. Shared pure modules and current
portable tests are analyzed; every application source compiles. Engine-facing
code is not claimed as engine-typechecked. Actual service code is exercised
with simulated engine boundaries, including the new rig builder/animator and
SaveService. Real Studio tests remain required.

Current tests live directly under `tests/`. Seven suites with obsolete v1.0
contracts were moved to `tests/legacy-v1.0`. Three old service harnesses are
preserved in `scripts/legacy-v1.0`. These archives are not run or counted as
passing by the current check command. The original Claude test files were not
embedded in the uploaded place; new regression coverage verifies the imported
progression rules and source/model availability.

Checks build `build/Catch-the-scrap.rbxl` and `.rbxlx`, verify every source is
included exactly once, then bundle editable sources. Current release copies
are versioned in `downloads`. The original v1.4 attachment is archived there too.

Optional asset gallery (Blender, not Studio):

```sh
luau scripts/export-blueprints.luau > build/blueprints.json
blender -b -t 4 --python scripts/render-guardians.py
```

A full movement/teleport anti-cheat is not implemented. New guardian balance,
actual native motor/network interpolation, startup cost, DataStore API behavior
and mobile FPS need measurement in Roblox Studio/on devices.
