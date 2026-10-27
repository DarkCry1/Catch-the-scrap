# Development: native carrying, admin tools, compact HUD and randomized salvage

All custom game UI, prompts, signs, feedback and leaderboard columns are English.
Beginner-facing instructions in chat and STUDIO_START_SV.md remain Swedish.

## Current rules

- Common: **5 Common parts**, $5/sec per completed robot.
- Uncommon: **7 Uncommon parts**, $10/sec (provisional balance).
- Rare: **10 Rare parts**, $20/sec.
- Epic: **12 Epic parts**, $45/sec.
- Legendary: **15 Legendary parts**, $100/sec.
- Mythic: **18 Mythic parts**, $225/sec.
- Celestial: **20 Celestial parts**, $500/sec. New values are provisional balance.
- Recovered robot boxes contain one whole robot and need one free platform. They reserve the slot immediately and complete after 5.6 seconds; partial scrap projects are not merged or consumed.
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

The yard is **160 × 3360 studs** (formerly 44 × 360), divided into seven 480-stud
zones. Each has 32 pickups. Original deterministic scenery includes containers,
car wrecks, tire bays, pipes, heaps, dismantled robots, reactors and overhead
cranes. The central 28 studs remain clear for walking. Version 0.6 raises scrap-clad walls to 64 studs and adds turbine/furnace/void/star-engine scenery. See STAGES_V06.md for current budgets and preview limitations. Pickup footprints are
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
blender -b -t 4 --python scripts/render-delivery.py
```

Blueprints are shared with the game, but renderer lighting, text, materials and
camera differ from Roblox. There are no imported Toolbox models or asset IDs.

## Streaming and ambient graphics

Workspace streams at min/target radii 128/256. The yard is Nonatomic; small pickups and the mechanic stand are Atomic. Workshop models use PersistentPerPlayer and are pinned/unpinned by WorldService on assignment/release. Client ambient tags activate lights/particles within Config.Visuals.EffectDistance and clean up on stream-out. Reactor tweens restart safely when instances return. These behaviors need actual Studio and device testing.

PickupBlueprint supplies both welded visual geometry and ground clearance. Item roots are invisible, anchored when resting, and welded to the character when carried. PlacementRules rejects ground outside the new perimeter before placing a dropped item. Existing three recipes and mechanic upgrade prices are retained; four new recipes are configured in Config. All districts are open, with four total robot slots; replacement/recycling is not implemented.

## Camera and salvage presentation (v0.6)

`Config.Stages` is the ordered authority for districts, spawn types, labels,
server progress publication and recipe HUD. Shared `CameraBounds` clips the
focus-to-camera ray against the union of the plaza and the narrower yard. It
stops at the first boundary rather than jumping across an entrance corner.
`CameraGuard` runs after the default Roblox camera, includes near-plane padding,
limits ordinary zoom to 32 studs and skips Scriptable cinematic cameras.
StarterPlayer uses Zoom occlusion. This is camera containment, not anti-cheat.
Wall and ground segments are at most 480 studs long, below Roblox's 2048-stud
part dimension limit. No invisible giant colliders are needed.

PickupBuilder creates one Motor6D from the server carrier root to a massless
visual pivot, plus a stationary segmented ground halo. PickupAnimator adjusts
only local C0 and halo transparency within 110 studs. Shared PickupMotion is a
continuous upward bob, slow spin and small tilt. CarrierUserId changes stop the
idle effect immediately, while the server also hides carried halos. Distance
checks run every 0.2 seconds; per-frame work visits nearby rigs. Stream-out
removes records and attribute connections. Gameplay prompts, item coordinates,
weights, server ownership and rewards are independent of the cosmetic motion.

`check-presentation.py` executes the actual camera/animation adapters with
mocked signals, vectors and camera transforms. It verifies orbit containment,
carry/drop, distance gating and stream cleanup. Shared tests sweep camera
corners/entrance seams and ground clearance across motion phases; service tests
complete and publish all new recipes. These cannot verify engine joint physics,
camera feel, GUI clipping or GPU performance; test those in Windows Studio.

## Carrying, shredder and rare recovery (v0.8)

CarryRig is server-built and uses native IKControl chains for R15. It welds
cargo in front of the torso and targets both hands at grip attachments. R6 and
explicit Handheld mode use a real Roblox Tool/Handle and native tool hold.
A body-mounted harness is the independent fallback. Style switching clears old
IK, attachments, welds, tools and straps before attaching again. Drop, deposit,
reset and death use the same cleanup. No uploaded animation is needed.
CarryAssist observes actual client hand/target distance; an Auto IK pose that
fails for two seconds requests Handheld once for that item. Players can also
choose any mode in Details. The old CarryPose module and its synthetic pose math
check were removed after real Studio reports showed the approach did not work.
Native solver/tool fitting still needs actual avatar tests.

CrusherBlueprint/CrusherBuilder and WorkshopEffects handle accepted scrap
intake, press, counter-rotating blades, sparks and offcuts. The server awards
ordinary scrap at acceptance; presentation never authorizes any reward.

RareBoxService alone schedules robot boxes. ItemService.start spawns only normal
scrap. The map exposes 14 candidate crate positions, not 14 live crates. Initial
event delay is 60 seconds; subsequent intervals are 240–420 seconds. Live limit
is two, including carried items. Unclaimed ground boxes expire after 180 seconds;
held boxes refresh the ground deadline and cannot disappear from a player's hands.
Consuming/expiring a crate does not schedule an ordinary item replacement.

Event tiers: Rare 70%, Epic 22%, Legendary 6%, Mythic 1.8%, Celestial 0.2%.
CrateRules.definition publishes the actual tier. ItemService stores the exact
variant only in its server record. RobotCatalog selects among six weighted
models, excluding the immediately previous server box's model. Dropping/resetting
never rerolls. The actual tier promised by an event is always the reward tier.

Recovered projects reserve a free slot, preserve partial scrap builds and earn
nothing during their 5.6-second opening. The completion timer checks the same
account/project/base owner before settling old income and completing exactly
once. Recovered income is round(recipe income × 4 × variant multiplier). Crafted
robots use their original recipe income. RobotVariants supplies distinct model
geometry used by RobotBuilder, unboxing holograms and the optional Blender gallery.
Full robot name, Variant and Income are exposed only on the final built model.

RareBoxSpawned is broadcast on Action and includes event id, actual tier,
district and time. NextRareBoxAt and two active-event snapshots are replicated as
attributes so late clients can recover announcements. Clients deduplicate ids.
RobotUnboxed is owner-only and carries the final model name and actual income.
Client requests include Drop, BuyUpgrade, SetCarryStyle and the server-authorized Admin command. Only admins may request existing events or personal stat/cash changes. There are still only two remotes.

UnboxingEffects renders charging, hinged flaps, cycling holograms, energy arcs,
launched carton panels, a particle burst and the actual robot reveal. Preview
holograms are cosmetic and do not choose the reward. All temporary effects are
local, distance-limited and cleaned on stream-out. No camera takeover or uploaded
assets are required. Model pivots are explicitly replicated through attributes.

Checks execute the real schedule, item lifecycle, finance/recovery services and
native carry configuration across mocked engine boundaries. Tests cover event intervals,
exact announced tiers, live caps, expiry, late-join state, no ordinary respawn,
variant incomes, no immediate model repetition, separate reservations, duplicate
callbacks and ownership/disconnect guards. Native carry tests cover R15 IK, R6 Tool hold, forced engine failures, harness fallback and cleanup. CarryAssist tests distinguish successful hand targeting from failed poses.
These do not replace the real avatar/graphics/device tests listed in STUDIO_START_SV.md.

Optional current model gallery:

```sh
luau scripts/export-blueprints.luau > build/blueprints.json
blender -b -t 4 --python scripts/render-variants.py
```

## Admin and randomized spawns (v0.9)

AdminConfig is server-only. It includes UserId 11824623188 and local Studio
allowance; personal experience creators are also allowed. AdminService rechecks
the server policy on every request and never trusts CanAdmin or any client role
attribute. Commands are whitelisted and finite/integer/range checked, with a
0.3-second per-player throttle. Cash changes settle accrued income and publish
server account/leaderstats together. Test speed overrides the final carry speed;
strength overrides feed normal weight calculations. ResetStats clears both.
No player target or arbitrary instance/path is accepted. Event requests specify
only a configured rarity and stage and retain normal occupancy/live-box limits.

Action client protocol additions:

- SetCarryStyle(style): exactly one argument, Auto/Handheld/Harness only.
- Admin(command, value): exactly two arguments. SetCash/AddCash accept integer
  0..1e9; SetSpeed 7..120; SetStrength 1..10000; ResetStats/Home require 0;
  Event requires a validated {rarity, stage} table.
- AdminResult is a server-to-client status packet. CanAdmin controls UI visibility
  only; authorization uses server configuration each time.

SpawnRules converts collidable scenery near pickup height to conservative X/Z
obstacles. Reserved crate pads are added. ItemService samples initial and
replacement points in the original rarity district, outside the 28-stud road,
with geometry margins, seven-stud ground-item spacing and 12-stud distance from
that slot's previous spawn. A validated grid fallback is used only if random
attempts fail; if no point exists, spawning retries later rather than using an
unsafe point. Ground positions use per-model clearance. Held items are excluded
from ground occupancy. RareBoxService separately avoids occupied candidate pads.
Drops do not reroll or duplicate items; replacement timers remain authoritative.

Main.client now starts cosmetic modules independently and keeps the compact HUD
available even if a presentation module errors. The always-visible wallet is
244x82 rather than 400x306. A contextual bottom card shows one current goal;
Details contains the seven recipes, stats and carry choices and scrolls on small
screens. Typed admin inputs do not trigger Q/Drop. Mechanic modal integration
continues hiding/restoring the main HUD. UI layout review images are not engine
screenshots.

Tests cover authorization/forged attributes, cash mutations, throttles, speed/
strength reset, forced event parameters and occupancy. Randomized placement
checks fill all seven zones, then repeatedly replace points while checking all
obstacles and spacing. Actual ItemService tests verify replacement movement.
The full place build still checks every embedded source and exactly two remotes.
