# Development

The current slice implements pickup/carry/drop/deposit, player-owned salvage
workshops, incremental robot assembly and server-authoritative passive income.
The original design brief remains below the quick start in README.md.

## Rules

Each successfully deposited item supplies **one scrap**, regardless of rarity or
weight. **10 scrap** automatically finish a Scrap Bot MK-I and consume that
recipe. Each completed robot earns **$5 per second**, up to **four robot slots**
per player. These values are prototype balance in `Config.Robot`. A full workshop
rejects further deposits before consuming inventory; the player keeps the item.
Money is credited directly. Spending, upgrades, offline rewards and DataStore
persistence are not part of this slice. Session progress survives character
reset/death and clears when leaving the server.

## Code

- `src/shared/Inventory.luau`: synchronous loot ownership and deposit rules.
- `src/shared/Movement.luau`: pure movement formula.
- `src/shared/Economy.luau`: recipe, capacity, fractional time and cash accounting.
- `src/shared/BaseBlueprint.luau`, `RobotBlueprint.luau`: original geometry.
- `src/server/Assets`: workshop/robot builders and incremental display.
- `src/server/Services/WorldService.luau`: map, eight assigned workshops.
- `src/server/Services/ItemService.luau`: pickups, carry welds and replacement spawns.
- `src/server/Services/CarryService.luau`: character context and validated deposits.
- `src/server/Services/EconomyService.luau`: per-player accounts and Heartbeat timing.
- `src/client`: Swedish responsive HUD, drop input and reactor effects.
- `tests`: portable ownership, movement, economy and geometry checks.

The only client action remote remains `Action:FireServer("Drop")` with no payload.
Pickup/deposit use server-created prompts and check distance, live character,
carried ownership, base allocation and base owner. Robot counts, scrap and cash
are never accepted from the client. All ownership transitions and capacity
checks are synchronous. Income is settled at the old robot rate before a new
robot starts earning. Partial dollar amounts survive frame boundaries.

There is no complete movement/teleport anti-cheat. Proximity checks do not prove
a replicated character reached that position legitimately. Eight bases are
available; additional players must rejoin a server with space. No live queue.

## Checks and artifacts

Tools: Rojo **7.7.1**, Luau **0.744**, Python **3**.

```sh
cd /workspace/Catch-the-scrap
source /workspace/.catch-the-scrap-tools/activate.sh
python3 scripts/check.py
```

This analyzes pure shared modules and tests, runs every test file, compiles all
application Luau, builds XML and binary places, verifies all source embedding,
and bundles editable sources. Engine-facing scripts are compiled, not claimed
as engine-typechecked. Actual physics, prompt visibility, UI layout, reactor
animation and multiplayer need Studio testing per `STUDIO_START_SV.md`.

Ignored outputs: `build/Catch-the-scrap.rbxl`, `.rbxlx`, and
`build/Catch-the-scrap-source.zip`. Published test builds live in `downloads/`.
After source changes, regenerate and explicitly replace the shared download;
the checked-in downloadable artifact is a versioned snapshot, not an automatic
side effect of every test run.

The map is generated at Play time, so editor-mode emptiness is expected. For
local sync, run `rojo serve default.project.json` on the same computer as Studio.
Cloud loopback is a different machine from the user's Windows PC.

Optional asset preview (Blender is not a game/build dependency):

```sh
luau scripts/export-blueprints.luau > build/blueprints.json
blender -b -t 4 --python scripts/render-preview.py
```

This renders the actual shared geometry with example robot progress. It is an
asset preview, not a Roblox runtime screenshot. References and access limitations
are documented in `DESIGN_REFERENCES_SV.md`. No external models are imported.
