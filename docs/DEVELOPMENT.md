# Development: carrying, scrap processing and recovered robot boxes

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
- Recovered robot boxes contain one whole robot and need one free platform. They reserve the slot immediately and complete after 3.8 seconds; partial scrap projects are not merged or consumed.
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

## Carrying, shredder and recovery (v0.7)

CarryPose applies local R6/R15 shoulder/elbow/wrist Motor6D transforms for all
nearby player characters. It restores the previous override before PreAnimation,
then blends over Animator's current transform during PreSimulation. Character
changes, dropping and player removal release the pose. ItemService positions the
server carrier root above the head using actual head height and item clearance.
All carry visuals remain noncolliding and massless.

CrusherBlueprint/CrusherBuilder replace the previous closed deposit surface
with an open twin-shaft shredder and a press. Accepted scrap invokes the server
onCrush hook before destroying the item; it broadcasts an authoritative Crusher
packet on Action and sets CrusherActiveUntil on the owning workshop. WorkshopEffects
handles local intake, scale/fade, offcuts, press travel, rotor speed, sparks and
light, bounded by distance. One intake model per workshop replaces older visual
intakes; all accepted deposits still count. Cosmetics never determine rewards.

CrateRules draws a result once on the server at spawn. Public crate attributes,
label and geometry contain only Mystery/Sealed Robot Box; rewardRarity stays in
the server record. Dropping/resetting does not reroll. Two boxes per district are
placed in tested free spaces outside the haul road. Their respawn is 35 seconds.
Stage-relative rolls: current tier 70%, previous tier 20%, next tier 9%, two tiers
higher 1%, clamped to the available tier range. These are free found items.

Inventory accepts a box only at its owner's workshop. Economy.reserveRobot
creates an opening project that counts toward platform capacity, earns nothing
and cannot receive scrap parts. The server delay verifies the same account,
project and workshop owner before settling OLD income and completing the robot.
Disconnects invalidate pending callbacks; character resets retain the account.
finishRecovery is idempotent. No client request names a robot reward or amount.

CrateBuilder displays the neutral box on its reserved platform. UnboxingEffects
animates its real flaps/tape and a local light/burst; server completion replaces
the box with the actual robot. Its short reveal uses the server RevealAt time.
WorldPivot is not replicated: rotor pivots and RevealOrigin are sent as explicit
attributes and applied locally before animation/scaling. Robot models stream
atomically. Effects clean up on stream-out and skip stale reveals.

Action now also carries a server-to-client Crusher packet (serial, time,
baseIndex, origin, start, rarity). Client-to-server requests remain only Drop and
BuyUpgrade, with their existing argument validation. No new remotes or uploaded
animation/audio/texture assets are required.

Additional checks execute actual item attach/drop/respawn code with mocked
geometry; verify sealed contents, replay safety, pickup callback identity and
head-relative carry height. Carry-pose mocks test R6/R15 joint discovery, blends,
pre-animation restoration and cleanup. Recovery service tests cover proximity,
liveness, foreign bases, capacity, delayed income, duplicate callbacks and
owner/disconnect changes. Shared geometry tests cover all crate positions and
motion bounds. Engine physics, avatar fitting, visual feel and FPS still need
Windows Studio playtests.
