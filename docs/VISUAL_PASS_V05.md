# v0.5 visual pass

The visual direction is a weathered industrial salvage yard: rust, patched steel,
concrete, copper, warm work lights and restrained reactor colors. All custom game
text remains English.

## What changed

- Continuous 22-stud perimeter walls on both long sides, with layered salvaged
  sheet-metal cladding, reinforcement ribs, ragged scrap caps and safety patches.
- A reinforced entrance, enclosed workshop plaza and scrap-clad end wall, with
  silo/exhaust silhouettes beyond the playable area.
- Container roof seams, wheel hubs, damaged-vehicle trim, reactor bracing,
  concrete repairs, reflective oil patches and drainage grates.
- Patched workshop roofs/walls, cabinet vents, service conduits, robot rivets
  and shoulder/back details, plus extra drawers and reinforcement at Milo's stand.
- Recognizable eight-tooth gears, motor housings/coils/shafts and clamped glowing
  reactor cores. All use welded, massless visual parts around one invisible
  carrier root. Their individual ground clearance is calculated from geometry.
- Late-afternoon lighting, clouds, dust-colored atmospheric depth, gentle bloom,
  sun rays and restrained grading. Warm wall lamps and sparse smoke/sparks add
  activity. HUD and shop surfaces share the steel/amber palette.

## Runtime/rendering limits

The static yard/plaza blueprint contains **1,374 parts**, below its explicit
1,700-part budget. There are 96 collectible slots; each collectible uses at most
12 visual parts. Ambient effects have 27 sources; lights have no shadows and
particles emit at low rates. Client activation is bounded by distance and checked
every 0.4 seconds, not every rendered frame.

Workspace streaming is enabled (minimum radius 128, target 256). The large yard
is explicitly non-atomic. Small pickups and Milo's stand stream atomically.
Each owner's workshop is pinned for that player with PersistentPerPlayer, so
returning/resets do not depend on a distant base streaming back in first. Other
players' bases and distant decoration can stream normally. Reactor tweens are
cancelled on stream-out and restarted on stream-in. These are implementation
controls, not measured frame-rate or device-performance claims.

Drops outside playable perimeter bounds return to the original spawn. Cosmetic
panels, stains and ambient anchors do not add collision/query blockers.

## Validation

Portable checks cover lanes, spawn clearance, perimeter dimensions, part/effect
budgets, gear/motor/core ground clearance, and safe drop boundaries. Actual
service code is also executed across mocked engine boundaries to check income,
purchases, stat updates, light distance gating and reactor streaming cleanup.
All application Luau compiles and both place formats build.

Real Studio tests remain required: walk all zones, inspect materials/lighting,
pick up/carry/drop each new model, return to a fully built workshop from the far
end, reset the character, use Milo's shop, and compare high/low graphics and
mobile performance. This cloud environment cannot run Roblox Studio.

## Asset previews

![Yard at ground level](../downloads/scrapyard-ground-preview.png)

![Yard overview](../downloads/scrapyard-preview.png)

![New collectible models](../downloads/pickup-preview.png)

![Workshop model](../downloads/workshop-preview.png)

![Milo's mechanic stand](../downloads/mechanic-preview.png)

These are Blender renders of the shared model blueprints, **not Roblox Studio
screenshots**. Text, lighting, shadows, textures and particles can differ in-game.
Procedural preview surface noise is renderer-specific; the game uses native
Roblox materials. No external Toolbox models, paid assets or uploaded textures
are required. Smoke and spark textures use packaged Roblox particle textures.
