# Development

This first slice implements pickup, one carried item, weight-based speed, drop,
and deposit into the player's assigned base. No persistence, economy, crafting,
NPCs, or prestige is implemented. The design brief remains in README.md.

## Layout

- `default.project.json`: Rojo DataModel mapping and remotes.
- `src/shared/Config.luau`: adjustable prototype values and three test items.
- `src/shared/Movement.luau`: pure movement formula.
- `src/shared/Inventory.luau`: synchronous ownership/deposit state machine.
- `src/server/Main.server.luau`: bootstrap, player lifecycle and remote boundary.
- `src/server/Services/WorldService.luau`: runtime map and eight owned bases.
- `src/server/Services/ItemService.luau`: visuals, prompts, carry weld, respawns.
- `src/server/Services/CarryService.luau`: server-side context and state changes.
- `src/client/Main.client.luau`: Swedish HUD, keyboard/touch drop request.
- `tests/core.spec.luau`: portable state and movement checks.
- `docs/STUDIO_START_SV.md`: Windows instructions and engine test checklist.

## Checks and build

Tools used: Rojo **7.7.1**, Luau **0.744**, Python **3**. No third-party
runtime modules or paid/external assets are required by the game.

In this prepared cloud environment:

```sh
cd /workspace/Catch-the-scrap
source /workspace/.catch-the-scrap-tools/activate.sh
python3 scripts/check.py
```

The check script analyzes the pure shared modules and tests, executes their
assertions, compiles every Luau source, builds binary and XML Roblox places,
checks that each source is embedded exactly once, and bundles editable sources.
An unsuccessful command fails the script. The standalone analyzer does not
supply Roblox engine globals: engine-facing scripts are compiled, not claimed
as engine-typechecked. Run the manual Studio checklist for runtime coverage.

Generated, ignored outputs:

- `build/Catch-the-scrap.rbxl`: open in Studio for the first test.
- `build/Catch-the-scrap.rbxlx`: inspectable XML equivalent.
- `build/Catch-the-scrap-source.zip`: editable source plus docs and tests.

The map is generated at runtime rather than stored in the place. Editor-mode
emptiness is expected until Play. Do not mix manual map edits with generated
geometry without first deciding which source owns those changes.

For local source sync, run `rojo serve default.project.json` on the same machine
as Studio with the matching Rojo plugin. Cloud loopback is not desktop loopback.
No public endpoint or Roblox authentication is needed to build these artifacts.

## Authority and lifecycle

Clients can request only `Action:FireServer("Drop")` without extra arguments.
Pickup and deposit use server-created ProximityPrompt callbacks, with independent
server checks for live character, distance, base allocation, carrying state and
base ownership. All requests share a per-player cooldown. Ownership checks and
transitions do not yield, so contested pickups have a single winner.

Carried visuals are massless and noncolliding; the inventory is authoritative,
not the visual's position or client metadata. Dropped loot is anchored on
server-raycast ground; unsafe drops return to the original spawn. Death,
character replacement, or disconnect returns held loot to its original spawn.
Deposits consume one item, count once, and schedule one replacement after eight
seconds. Session counts survive character death and clear when a player leaves.
There is no complete movement/teleport anti-cheat; proximity validation does not
prove that a replicated character reached that position legitimately.

Eight bases are allocated for this prototype; configure private playtests for
at most eight players. Extra players cannot pick up loot until rejoining a
server with a free base. Live-session queueing is deferred.
