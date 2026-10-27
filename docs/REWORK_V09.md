# v0.9 — carrying rework, admin tools, compact HUD and randomized scrap

## Carrying has three independent paths

- **Auto:** native R15 two-hand IK, or native Tool hold for R6. Cargo is in front
  of the body. Failed IK construction falls back to Tool hold; CarryAssist also
  observes the actual hands and switches to Handheld if targeting fails for two
  seconds. This does not rely on a custom client shoulder pose.
- **Handheld:** explicitly uses a Roblox Tool/Handle and the native tool hold.
- **Harness:** mounts cargo behind the body with straps, without arm posing.

Choose a mode in **Details → Carry method**, even while holding an item. Server
ownership and crate contents do not change. Cleanup removes old controls,
targets, Tools, welds and straps on switching, drop, delivery or character cleanup.
Native avatar fitting and Tool animation still require actual Studio testing;
no result from a real engine run is claimed here.

## Admin access and controls

Open **F4 / Admin**. Server policy allows UserId **11824623188**, local Studio
test players and the personal experience owner. Group-owned experiences still
allow the explicit configured id. Everyone else is rejected on the server,
regardless of any client-visible CanAdmin attribute or fabricated menu.

| Control | Effect and limits |
|---|---|
| Set / Add cash | Personal server balance; 0–$1,000,000,000 |
| Set speed | Personal actual WalkSpeed, including carrying; 7–120 |
| Set strength | Personal carrying strength; 1–10,000 |
| Reset stats | Removes test overrides; restores normal purchased/base stats |
| Return to base | Moves your living character to your own workshop |
| Trigger event | Existing Rare–Celestial box event in stage 1–7 |

Events broadcast to the server. Other controls target only the caller. Event
live limits and occupied pads are respected; held boxes are never deleted to
make room. Commands are validated, throttled and session-only. No arbitrary
instance edits or other-player targets are accepted.

## HUD simplification

The old permanent 400×306 left panel is replaced with a **244×82 wallet** showing
cash, passive income and base. That is about 84% less permanent left-panel area.
A small bottom card shows one useful objective: current district recipe progress
or carried cargo and its destination. Drop appears only while carrying.

Recipes, robot count, speed, strength, weight and carry options are in Details.
Feedback appears briefly, then clears. Mobile details scroll. There is no
permanent empty-hands message, oversized title, seven-recipe list or session
warning covering the scene. Admin controls have their own authorized panel.

![HUD layout review](../downloads/hud-layout-v0.9.png)

This is a static UI layout illustration using approximate fonts, **not a Roblox
Studio screenshot**. Native rendering, mobile layout and interaction need testing.

## Randomized salvage placement

Initial pickups and replacement scrap positions are sampled within each rarity
area. Every replacement is at least **12 studs from its previous position**.
Candidates avoid collidable scenery, walls, the central road, other ground loot
and reserved event pads. The same geometry/spacing rules validate a grid fallback;
if no safe point exists, spawning waits rather than placing unreachable loot.

Normal scrap still respawns eight seconds after accepted deposit. Drops/reset
preserve the item and never create extra loot. Crate events retain their separate
rare schedule, known-tier guarantees, private variants and unboxing rewards.

## Verification

Automated checks execute actual native-rig setup/fallback/cleanup, item lifecycle,
admin service mutations, permission checks, forged client roles, cooldowns,
forced event parameters and random replacement. Pure placement tests repeatedly
fill/replace all seven districts against scenery bounds and spacing constraints.
All source compiles, binary/XML places build and exported source is checked.

This environment cannot run Roblox Studio. In the new file, test the same avatar
from the failed screenshots, all three carry methods, admin UI, two clients,
random respawn, resetting, streaming and mobile/low-graphics performance. The
independent Harness option is available directly if an avatar's arm rig is unusual.
