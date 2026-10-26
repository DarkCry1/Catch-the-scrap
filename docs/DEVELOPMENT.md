# Development: visual scrapyard, mechanic upgrades and rarity recipes

All custom game UI, prompts, signs, feedback and leaderboard columns are English.
Beginner-facing instructions in chat and STUDIO_START_SV.md remain Swedish.

## Current rules

- Common: **5 Common parts**, $5/sec per completed robot.
- Uncommon: **7 Uncommon parts**, $10/sec (provisional balance).
- Rare: **10 Rare parts**, $20/sec.
- Four platforms per player. The first part reserves a platform for its rarity.
  Matching parts continue the unfinished project. Capacity is checked before
  inventory consumption, and reserved projects can still finish when no slots
  remain. Completed robot provenance and income retain their rarity.
- Five visual assembly groups. Ten Rare parts reveal one group per two parts.
- Money is server-controlled and credited only for completed robots. Account
  time is settled at the old rate before a new robot begins production.
- Progress survives character resets but clears when leaving. No persistence,
  offline income, enemies or prestige yet. Speed/Strength spending is implemented below.

## World

The yard is **160 × 1440 studs** (formerly 44 × 360), divided into three 480-stud
zones. Each has 32 pickups. Original deterministic scenery includes containers,
car wrecks, tire bays, pipes, heaps, dismantled robots, reactors and overhead
cranes. The central 28 studs remain clear for walking. Version 0.5 adds solid scrap-clad perimeter walls, plaza boundaries, weathered surfaces and detailed collectible models; see VISUAL_PASS_V05.md for budgets and preview limitations. Pickup footprints are
checked against junk bounds. Fence-line piles fill the perimeter without
blocking pickups. Hidden tire details are omitted to limit part count.

Yellow arrows point toward positive Z, into the yard. Turquoise arrows point
negative Z, toward workshops. Both use the same tested endpoint geometry.
World labels use transparent, noncolliding anchors with bounded visibility.
Gate lintels are physical workshop structure; floating yard labels have no boards.

## Structure

- `src/shared/Economy.luau`: rarity projects, reservations and timed income.
- `src/shared/Inventory.luau`, `Movement.luau`: ownership and carrying rules.
- `src/shared/Navigation.luau`: tested chevron endpoints.
- `src/shared/ScrapyardBlueprint.luau`: pure scenery, signs and spawn layout.
- `src/shared/BaseBlueprint.luau`, `RobotBlueprint.luau`: original geometry.
- `src/server/Assets`: builders, floating text and navigation rendering.
- `src/server/Services`: map, pickups, player lifecycle, deposit and economy.
- `src/client`: English responsive HUD and reactor effects.

## Mechanic purchases

Milo's shared stand is on the front plaza at (55, 0, 7), facing the street. Its
geometry is in `MechanicBlueprint.luau`; its robot is scaled from the existing
original robot blueprint. The booth does not overlap the road or workshops.

`UpgradeRules.luau` owns offers and synchronous purchases. Speed starts at $75,
adds 2 base speed per level and uses a 1.6 price multiplier. Strength starts at
$100, adds 10 carrying strength and uses a 1.65 price multiplier. Prices round
up and both upgrades cap at level 10. Levels live in the same server-owned
account as cash and reset when leaving. Character resets retain levels.
`EconomyService` supplies authoritative movement stats; `CarryService` applies
them to a live humanoid on purchase and character changes.

Client request protocol on `Action`:

- `FireServer("Drop")`: no additional arguments.
- `FireServer("BuyUpgrade", kind, expectedLevel)`: exactly two arguments, with
  a whitelisted kind and a numeric expected current level. The client sends
  neither a price nor a requested stat value.

Server-to-client `Action` packets use the `MechanicShop` channel for offers,
receipts and closure. Opening requires a live nearby character with a workshop.
Every purchase rechecks distance/liveness, uses a per-player cooldown, settles
income, computes server prices, checks cash/cap/current level, debits and raises
one level without yielding. A stale expected level cannot purchase an unseen
next level. Leaving clears shop state. Character removal or walking away closes
the client dialog. A manually closed dialog does not reopen for a delayed receipt.

The only other remote is `Feedback`. Pickup/deposit prompts independently
validate character, distance, ownership, base and capacity. There is no complete
movement/teleport anti-cheat. Eight workshop allocations exist; extra players
must join a server with room.

## Checks and export

Tools: Rojo 7.7.1, Luau 0.744, Python 3. In the prepared cloud environment:

```sh
cd /workspace/Catch-the-scrap
source /workspace/.catch-the-scrap-tools/activate.sh
python3 scripts/check.py
```

Checks cover portable rules, actual service code with mocked engine boundaries,
arrow direction, five assembly groups, rarity isolation, slot reservation,
walkable lanes, pickup clearance, part budget and legacy Swedish text detection. Upgrade checks cover prices, atomic debits, caps, replay rejection, proximity and actual humanoid stat updates across a mocked engine boundary.
All application Luau is compiled and all sources are checked in the exported
place. Shared modules/tests are typechecked. Roblox-facing code is not claimed
as engine-typechecked, and simulated service tests do not replace Studio.

Ignored build outputs: binary/XML places and source ZIP in `build/`. Versioned
user downloads live in `downloads/`; explicitly replace them after a validated
build when sharing a new version. The world is generated at Play time.

Optional geometry previews (not runtime screenshots):

```sh
luau scripts/export-blueprints.luau > build/blueprints.json
blender -b -t 4 --python scripts/render-yard.py
blender -b -t 4 --python scripts/render-preview.py
blender -b -t 4 --python scripts/render-mechanic.py
blender -b -t 4 --python scripts/render-pickups.py
```

Blueprints are shared with the game, but renderer lighting, text, materials and
camera differ from Roblox. There are no imported Toolbox models or asset IDs.

## Streaming and ambient graphics

Workspace streams at min/target radii 128/256. The yard is Nonatomic; small pickups and the mechanic stand are Atomic. Workshop models use PersistentPerPlayer and are pinned/unpinned by WorldService on assignment/release. Client ambient tags activate lights/particles within Config.Visuals.EffectDistance and clean up on stream-out. Reactor tweens restart safely when instances return. These behaviors need actual Studio and device testing.

PickupBlueprint supplies both welded visual geometry and ground clearance. Item roots are invisible, anchored when resting, and welded to the character when carried. PlacementRules rejects ground outside the new perimeter before placing a dropped item. Gameplay recipe, account and upgrade values were not rebalanced in this pass.
