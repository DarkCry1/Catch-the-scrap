# Catch-the-scrap

Current build **v0.3**: an English-only game UI, a 160 × 1440-stud scrapyard,
transparent floating signs, corrected route arrows and rarity-specific robots.
Common needs 5 Common parts ($5/sec), Uncommon 7 ($10/sec), Rare 10 ($20/sec).
Four robot platforms per player; progress is session-only.

[Download v0.3](downloads/Catch-the-scrap-v0.3.rbxl) · [Scrapyard geometry preview](downloads/scrapyard-preview.png) · [Windows test guide (Swedish)](docs/STUDIO_START_SV.md) · [Development](docs/DEVELOPMENT.md)

Build with `python3 scripts/check.py`. Actual Studio testing is still required.
The brief below records the original design plan; current requested changes
and rules are described in the development guide.

CATCH THE SCRAP — Project Brief / Game Design Document

Version: 0.1 planning draft | Date: 2026-10-26
Status: Concept approved for initial prototype, details subject to testing.

1. Project intent

Build an original Roblox game in Roblox Studio using Luau, with Codex assisting development. The creator has around 1–2 hours per day and wants a small but commercially viable game, starting with a playable prototype and expanding after playtests. Working title: Catch the Scrap.

Core promise: Run far down a long shared track, find increasingly rare scrap parts or abandoned robots, and get your prize safely back to your base. Heavier prizes slow you down. Some high-value items trigger an enemy robot chase. Assemble robots or recover complete ones, place them in base slots to earn cash per second, upgrade movement/carrying ability, and eventually prestige to expand the base.

Inspirational genre reference: games like “Catch an Egg,” but mechanics, assets, designs and branding must be original.

2. Core gameplay loop

1. Spawn at or return to your own base, where placed robots generate passive in-game currency ($/second).

2. Run onto a long shared track divided into zones with generally increasing item rarity and risk.

3. Collect scrap parts or pick up abandoned complete robots. Carry only what the current prototype permits (start with one carried item to keep scope manageable).

4. The carried object’s weight reduces movement speed; Strength mitigates weight penalties, while Speed increases unencumbered/base running speed.

5. Some special pickups trigger enemy security robots that chase the player. Escape with loot, or drop it to recover mobility. On being caught, lose the currently carried loot, not previously banked progress.

6. Safely deposit loot in the base. Combine components to craft a robot, or directly place recovered robots into a free base slot.

7. Robots earn currency per second. Spend currency on Speed, Strength, and later additional upgrades.

8. Progress to increasingly rare zones and ultimately prestige to unlock more base slots and an income multiplier. Repeat.

3. Rarity tiers

In increasing order: Common, Uncommon, Rare, Epic, Legendary, Mythic, Galaxy. A potential “Secret” tier is for a later update, not initial MVP.

Visual identity: instantly recognizable rarity colors, simple Roblox-friendly low-poly robots and scrap pieces, readable at a distance, performance-conscious on mobile.

Track should not be long and empty. Include pickups and meaningful events frequently. Balancing of zone distances, spawn rates and tiers is provisional and should be data-driven.

4. Robot acquisition and base economy

Two distinct routes:

● Crafted robot: Collect Head, Body, Arms, Legs components and assemble at a station. Component tiers influence output stats; exact recipes/rules to be balanced.

● Recovered robot: Find a complete abandoned robot on the track and carry it back.

Each robot has a rarity and a cash-per-second generation rate. Player starts with a base containing four slots in the proposed initial design. Place/remove/swap robots; consider an index/collection journal in a later milestone. Idle progression rules must be decided: the simplest MVP may grant passive cash only while in the server (no offline cash until tested).

Example only: Common Scrap Bot MK-I generates $5/s. This is NOT a final balancing number.

5. Weight, Strength, and Speed

Separate upgradeable stats:

● Speed: movement without burden.

● Strength: reduces the penalty of carried weight.

● Each item/robot has a weight value.

A draft prototype formula (not yet final):
effectiveSpeed = max(7, baseSpeed / (1 + (itemWeight / strength)^1.25 * 0.45))
The UI demonstration used baseSpeed ~24, Strength ~30, and sample weights 10 / 60 / 150. Calibrate across real playtests. Prevent impossible/sluggish runs. The authoritative server must validate pickups, item possession, stat purchases, deposits and currency earnings; character speed changes must not enable exploits.

6. Enemy robot chase

● Only qualifying rare/special items trigger an alarm/chase, not every pickup.

● Clear warning and fair reaction window.

● Enemies pursue the carrier; player may flee, navigate cover/obstacles, or drop the item to escape.

● When caught, player loses only current carried loot (not collected money/owned robots).

● Enemies return to patrol/zone afterward.

● Avoid unavoidable failure: enemy speed, pathfinding and obstacles need careful balance.

● Begin with one simple enemy type and a deterministic test trigger; expand later.

7. Prestige / base expansion

Initial proposed values, only examples:

|Prestige|Robot slots|Income multiplier|
|-------:|----------:|----------------:|
|0       |4          |1.00x            |
|1       |6          |1.25x            |
|2       |8          |1.50x            |
|3       |10         |1.75x            |
|4       |12         |2.00x            |
|5       |14         |2.50x            |

Prestige resets normal cash and selected upgrades, but preserves the robot collection so rare findings are not lost. Prestige eligibility could require reaching a cash threshold and discovering enough robots. Precise values and reset semantics need product decisions and testing.

8. Planned monetization (NOT part of initial prototype)

Free-to-play, optional passes and/or developer products after fun and retention are validated. Ideas: cosmetics, base decorations, storage expansion, convenience features or timed boosts. Avoid pay-to-win pressure and avoid designing gameplay frustration to force purchases. Treat prices as placeholders and use Roblox platform rules and server-side purchase validation.

9. MVP and milestones — target 1–2 hours per day

v0.1, weeks 1–2 (vertical slice):

● Simple Roblox place / long test track with 3 rarity zones.

● Spawn and pick up one carried scrap/robot item; display its rarity/weight.

● Apply slowed movement while carrying, simple Speed/Strength parameters.

● Drop/deposit mechanism.

● Four base robot slots; at least one recovered robot earns cash/sec.

● One enemy chase on picking up a specific test item.

● Complete test loop: base -> track -> pickup -> chase/return -> deposit -> place robot -> earn cash.

v0.2, weeks 3–5:

● All 7 rarity zones, multiple item types.

● Four-part robot crafting and full economy/upgrades.

● Persistence via DataStoreService, safe server-side validation.

● Basic prestige and base expansion.

● Clear HUD and tutorial/onboarding.

v0.3, weeks 6–8 (conditional beta):

● More robot models; animations, sounds, UI, feedback.

● Mobile performance and controls; multiplayer reliability.

● External playtesting, bug fixes, balancing, basic analytics.

● Optional monetization only if foundation is fun and stable.

● Publish public beta only after quality checks. Schedule is aspirational, not a promise.

10. Technical conventions

Platform: Roblox Studio; programming language: Luau. Use source-controlled code in Git, with Codex handling modular scripts. Choose a reliable Roblox Studio source-sync workflow (native Script Sync or Rojo, depending on compatibility) and clearly explain setup to a beginner.

Suggested services/module responsibilities (final names flexible):

● ItemService: item definitions, rarity, spawn, pickup eligibility.

● CarryService: server-verified carrying/drop/deposit, weight and movement.

● RobotService: robot definitions, crafting, ownership and slots.

● EconomyService: cash/sec and upgrades.

● EnemyService: one robot chase NPC with clear states.

● PrestigeService: prestige requirement and rewards.

● DataService: safe player persistence.

Prefer configuration tables for rarity, weight, robot income, spawn rates, costs and stats. Avoid a monolithic code file. Use secure RemoteEvents/RemoteFunctions with server-side verification of player actions. Avoid trusting client-sent money, owned robots, coordinates, inventory or prestige. Add basic debug tooling and test cases. Support both PC and mobile where feasible.

11. Gameplay & success checks

Prototype success = first robot collectible and deployable within a few minutes; complete loop feels satisfying; chase is exciting but fair; no game-breaking progression errors. Later quantitative working targets: ~10–15 minutes average session, 20–25% day-one retention, 80% onboarding completion, zero critical game blockers. These are planning targets, NOT known benchmarks.

12. What Codex should do FIRST

Do not generate the entire game in one pass. Start by:

1. Summarize the MVP and flag only truly blocking technical decisions.

2. Propose minimal project structure and select Roblox Studio sync path; distinguish files Codex can write from actions that require the user in Studio.

3. Create a small v0.1 scaffold / relevant Luau modules for pickup + carrying + drop + deposit with clear setup instructions.

4. Include a manual Roblox Studio test checklist and show how to use Studio Output for debugging.

5. Stop after this vertical slice for user testing before adding income, enemy NPCs, prestige and advanced rarity.

The user is relatively new to Roblox development. Explain each Studio click and where scripts go, step by step, in Swedish. Ask for screenshots or exact errors if stuck. Keep scope strictly controlled; prioritize working code over grand architecture.

13. Known design decisions NOT YET finalized

How long the track is; how zones scale; exact rarity probabilities; crafted robots’ part mixing rules; if robots are stolen or traded (not planned for MVP); offline income; extra inventory capacity; whether enemies can enter safe base; exact rebirth reset rules and balance; monetization/prices; final aesthetic and original assets. Treat all numbers above as adjustable prototypes. Do not silently turn suggestions into fixed product rules.
