# Testa v1.12 på Windows

Det här bygget utgår från din senaste **v1.11** och förbereder egenkomponerad
bakgrundsmusik. Robotdex, mutationer, auror, sparning, vakter och spelbalans
behålls från den filen.

**Musiken behöver först laddas upp till Roblox från ditt konto och få ett
ljud-ID.** [Hämta musikfilerna och följ stegen här](BACKGROUND_MUSIC_SV.md).
Platsfilens ljud-ID är tomt tills uppladdningen är klar.

1. [Hämta Catch-the-scrap-v1.12.rbxl](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/background-music-v112/downloads/Catch-the-scrap-v1.12.rbxl).
2. Stoppa gamla Play och öppna nya filen med **Ctrl+O**.
3. I Explorer: **SoundService → ScrapyardMusic → SoundId**. Klistra in
   `rbxassetid://DITT_LJUD_ID` från din godkända ljuduppladdning. Upplevelsen måste
   ha tillåtelse till ljudet. Spara platsen.
4. Tryck **Play/F5**. Världen byggs vid spelstart; en tom editor före Play är normalt.
5. Musiken ska tona in försiktigt och loopa. **M** stänger av ljudet och pausar
   musiken; nästa tryck återupptar den. Jakt och filmsekvenser dämpar musiken.

Lyssna i minst tre minuter och prova M, Reset Character, Robotdex och jakt.
Ingen dubblerad musik ska uppstå. Vanliga effekter ska höras tydligt. Kontrollera
med hörlurar/mobil också. Automatisk kontroll ersätter inte lyssning i Studio.

**Övriga kontroller:** WASD går, E plockar upp/lämnar in, Q släpper, I öppnar
Robotdex, F4 öppnar admin för ditt UserId 11824623188/lokala Studio-testare.
BASE/DETAILS-panelerna är borta i v1.11; ljudet styrs med M.

Om musiken saknas: se första meddelandet i Output. Ett tomt ID ger en förklaring;
ett privat/ej godkänt ID behöver korrekta ljudbehörigheter. Skicka ID och första
felmeddelandet om du behöver hjälp.

Sparning använder fortfarande samma DataStore. I Studio krävs publicerad
upplevelse och **Game Settings → Security → Enable Studio Access to API
Services** för verklig sparning. Vid otillgänglig DataStore blir besöket
session-only och spelet meddelar det.

[Musik, licens och uppladdning](BACKGROUND_MUSIC_SV.md) ·
[Redigerbar källkod](../downloads/Catch-the-scrap-v1.12-source.zip) ·
[Utvecklingsdokumentation](DEVELOPMENT.md)

För kodsynk: Rojo 7.7.1 med motsvarande Studio-plugin. Packa upp källkoden och
kör i PowerShell i projektmappen:

```powershell
& 'C:\Tools\Rojo\rojo.exe' serve default.project.json
```

Stoppa Play, anslut till localhost:34872 i en kopia och bevara ditt musik-ID även
i default.project.json eller Config.Music.SoundId före nästa synk.

Kontroller: `python scripts/check.py` med Python 3, Rojo 7.7.1, Luau 0.744 samt
WAV-filen från musiknedladdningen i assets/music/scrapyard-afterglow.wav.
