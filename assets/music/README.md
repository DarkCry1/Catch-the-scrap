# Scrapyard Afterglow

Original background composition and recording created for Catch the Scrap.

- 80 seconds, 96 BPM, stereo, 44.1 kHz.
- Warm synthesized pads, soft bass, a sparse mallet motif and quiet industrial
  percussion/room texture. No vocals, third-party samples or borrowed melodies.
- Synthesized from mathematical oscillators and deterministic noise by
  `scripts/compose-background.py`. NumPy/SciPy process the generated signal;
  ffmpeg encodes the optional MP3 listening copy.
- The WAV has wrapped musical tails for looping. Playback uses a three-second
  fade-in and a quiet game mix. Upload WAV for the best loop boundary.

## Rights

The composition and rendered recording in this directory are dedicated under
**CC0 1.0 Universal**, to the extent applicable rights exist. Commercial use,
modification and use in Roblox are permitted without attribution. No ownership
or license claim is made over unrelated game code, Roblox or third-party marks.
See [the full CC0 dedication](LICENSE-CC0.txt) and
https://creativecommons.org/publicdomain/zero/1.0/ .

## Files and reproduction

- `scrapyard-afterglow.wav`: original upload master, 16-bit PCM stereo.
- `scrapyard-afterglow.mp3`: 192 kbit/s listening/upload alternative.
- `track-info.json`: duration, levels, synthesis provenance and loop metrics.

```sh
python3 scripts/compose-background.py
```

The editable source ZIP includes this notice, the license, metrics, composer and
MP3; the larger WAV is supplied as a separate download. Reproduction requires
Python, NumPy, SciPy and optionally ffmpeg.

## Roblox setup

Roblox requires an uploaded audio asset and permission for the experience.
A WAV/MP3 file cannot become a playable SoundId by embedding its bytes in a
place. This repository does not contain a pre-approved audio ID or an upload
credential. Upload the supplied original recording under the correct owner,
grant your experience access and put its ID in
`SoundService.ScrapyardMusic.SoundId` (or `Config.Music.SoundId`).

See [Swedish setup and testing](../../docs/BACKGROUND_MUSIC_SV.md).
