# Development — v1.12 original background music

This release starts from the user's **v1.11 uploaded place**, recovered as 87
exact script sources. See [import record](IMPORTED_V111.md). It supersedes the
earlier Codex v1.5 snapshot. The active task adds original background audio;
no progression, mutation, enemy or economic balance changes are included.

## Background audio

Read [Swedish music setup](BACKGROUND_MUSIC_SV.md). `assets/music` contains the
original 80-second stereo loop, provenance, measured levels and CC0 dedication.
`scripts/compose-background.py` synthesizes every voice from oscillators/noise;
there are no third-party recordings or samples. It uses NumPy/SciPy and optional
ffmpeg for the MP3 copy. The game does not run Python or synthesize the audio.

**A Roblox audio upload and experience permission are still required.** The
shipped SoundId is empty because this workspace has no authenticated Roblox
asset-upload connection. The place does not yet contain a playable music ID.
A local waveform cannot be embedded directly into a Roblox SoundId.

`SoundService.ScrapyardMusic` is the prepared editor template. Set its SoundId
after upload, or set Config.Music.SoundId. For source sync, also preserve that
ID in default.project.json or Config; a later Rojo sync can reset an editor-only
property. The configured ID takes precedence over the template.

Client BackgroundMusic preloads a single local looping Sound, routes it through
a dedicated Music SoundGroup under the existing Audio master, fades it in and
ducks it for either GuardChase/DroneChase or a Scriptable cinematic camera.
M uses the existing Audio.setMuted flow; the loop pauses and resumes at its
previous position. Source changes replace the loop; late loads cannot start old
sounds. Failures warn without stopping other presentation or gameplay. Invalid,
missing, foreign URL and data-URI IDs are not played. The module is idempotent
and survives ordinary character resets without another music instance.

## Retained v1.11 systems

61 species and six collection versions (Normal plus five mutations), 2–8×
mutation income, auras, six initial/eight maximum platforms, Robotdex entry
rewards and milestones, persistent saving with offline fallback, rebirth, daily
quests, guide, giant guards, existing drones, carrying and the simpler v1.11
sound set remain. M still mutes the whole game. Both guard controllers are
retained as in the upload; consolidating them is a separate gameplay task.

The SoundId and music mix are local presentation. No remotes were added. There
is one server Script, one LocalScript, 87 ModuleScripts and two RemoteEvents.
DataStore namespace/schema, prices and monster speed values are unchanged.
All game copy remains English; beginner instructions are Swedish.

## Check and build

```sh
source /workspace/.catch-the-scrap-tools/activate.sh
python3 scripts/check.py
```

Python 3, Rojo 7.7.1 and Luau CLI 0.744 are required. For waveform checks the
original assets/music WAV must be present. To regenerate it, install NumPy and
SciPy, then run the composer. ffmpeg creates the MP3 listening copy.

Current tests live directly under tests. They cover music ID/mix rules,
actual Audio/BackgroundMusic against simulated audio boundaries, PCM format/
levels/loop boundary, the imported 61-species progression and five mutation
pools, saving rules, compatible inventory/upgrade/yard rules and cinematic
camera lifecycle. All application Luau compiles; pure root shared modules and
current tests are analyzed. Engine/CarryRigMath uses native Roblox types and
is compiled, not claimed as CLI engine-typechecked.

Historical tests/helpers for superseded v1.0 and the earlier Codex v1.5 live in
legacy-v1.0 and legacy-v1.5 directories. They are not run or counted as passing
against v1.11. The original Claude tests were not included in the place upload.

Checks build both .rbxl and .rbxlx, verify all 89 sources appear exactly once and
bundle editable sources, docs, composer, license and MP3. The larger WAV is a
separate download and is omitted from the source ZIP. Rendered places do not
contain audio bytes. All files in downloads are explicit release snapshots.

Native audio approval, permission, playback, loop audibility and device mix
need Roblox Studio testing after the owner's upload. No native Studio test or
Roblox asset publication was performed here.
