# Bakgrundsmusik — v1.12

**Scrapyard Afterglow** är en nykomponerad, 80 sekunder lång bakgrundsloop för
Catch the Scrap. Den är lugn och elektronisk, med mjuk bas, luftiga ackord,
diskreta meloditoner och metalliska rytmer som passar skrotgården.

Musiken och inspelningen har skapats genom syntes från grunden. Inga lånade
inspelningar, tredjepartssamplingar, röster eller melodier har använts. Den
levereras under **CC0**, så du får använda den kommersiellt i ditt Roblox-spel
utan krav på attribution. [Licens och ursprung](../assets/music/README.md).

## Lyssna och hämta

- [MP3 för provlyssning](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/background-music-v112/downloads/Scrapyard-Afterglow.mp3)
- [WAV för uppladdning](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/background-music-v112/downloads/Scrapyard-Afterglow.wav)
- [Platsfil v1.12](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/background-music-v112/downloads/Catch-the-scrap-v1.12.rbxl)

WAV rekommenderas för loopen. MP3 är en mindre lyssningskopia. Bilder eller
existerande Roblox-musik behövs inte för att använda den egna kompositionen.

## Steget som behöver göras från ditt Roblox-konto

**Ljudet är färdigt och spelkopplingen är byggd, men musikens Roblox-ljud-ID är
ännu tomt.** Roblox kan inte spela en lokal WAV/MP3 direkt från en platsfil.
Uppladdning kräver ditt konto; någon Roblox-uppladdningsanslutning eller
inloggning finns inte i den här arbetsmiljön.

1. Ladda upp WAV-filen i **Creator Dashboard → Creations → Development Items →
   Audio → Upload Asset**. Välj samma ägare som spelet, exempelvis ditt konto
   eller din grupp. Menynamn kan skilja sig något mellan Roblox-versioner.
2. Vänta på godkännande. Kopiera **Audio Asset ID** och ge din upplevelse
   tillåtelse att använda ljudet via ljudets **Permissions / Experiences**.
   Använd upplevelsens Universe ID om Roblox frågar efter det.
3. Stoppa Play. Öppna nya platsfilen med **Ctrl+O**. I **Explorer → SoundService →
   ScrapyardMusic**, sätt egenskapen **SoundId** till `rbxassetid://DITT_LJUD_ID`.
   Spara platsen och tryck **F5**.

Det behövs ingen kodändring när du använder den förberedda Sound-instansen.
Som alternativ kan samma ID sättas i `src/shared/Config.luau`, `Music.SoundId`;
det konfigurerade ID:t har företräde framför Sound-instansen.

Om du använder Rojo efter att ha satt ID i editorn: lägg även ID:t i
`default.project.json` under SoundService/ScrapyardMusic/SoundId, eller i
Config.Music.SoundId, så nästa synk behåller det.

## Så fungerar musiken

- Den startar efter att ljudet laddats och tonar in under tre sekunder.
- Den loopar med låg volym, separat från effekternas ljudgrupper.
- **M** stänger av allt speljud och pausar musiken. Nästa tryck återupptar den
  från samma position, i stället för att starta låten från början.
- Under **GuardChase**, **DroneChase** och filmkameror blir musiken lägre så att
  varningar och reveal-effekter får plats. Volymen återgår mjukt efteråt.
- Vanlig karaktärsreset ska inte skapa fler musikspelare.
- `Config.Music.Volume` bestämmer grundvolymen; `DuckChase`, `DuckCinematic`,
  `FadeInSeconds` och `FadeSeconds` styr mixen. Håll larm tydliga när du justerar.

Innan ID har lagts in visas ett tydligt meddelande i Output. Det är väntat.
Privat, obehörigt eller ej godkänt ljud ger också ett meddelande. HUD och
vanliga speleffekter fortsätter fungera även om musikfilen inte kan laddas.

## Testa i Studio

- [ ] Ljudet är godkänt och upplevelsen har behörighet.
- [ ] Loopen börjar efter laddning, med mjuk start och låg volym.
- [ ] Spela i minst tre minuter och lyssna på övergången var 80:e sekund.
- [ ] Tryck M flera gånger. Ingen dubblerad musik; uppspelningen fortsätter från
  rätt position när ljudet slås på igen.
- [ ] Bli jagad av en vakt och prova en filmsekvens. Musiken dämpas och återgår.
- [ ] Reset Character och öppna/stäng Robotdex: samma enda loop ska fortsätta.
- [ ] Prova låg/hög enhetsvolym och mobilhörlurar; musiken ska inte maskera larm.

## Kontrollernas omfattning

De automatiska testerna kör den faktiska Audio/BackgroundMusic-koden med
simulerade motorgränser: laddning, dämpning, M-paus/återupptagning, sena svar,
ljudbyte, fel, städning och en enda aktiv loop. WAV-filen kontrolleras för
längd, stereoformat, nivå, klippning och liten nivåskillnad vid loopgränsen.
Alla spelkällor kompileras och båda platsformaten byggs.

Detta verifierar inte verklig Roblox-ljudbehörighet, uppspelning eller hur mixen
låter i Studio. Det återstår efter uppladdningen.

Utgångspunkten är användarens **v1.11**, återställd som 87 exakta skriptkällor.
Mutationer, Robotdex, sparning, vakter, progression och v1.11:s ljudeffekter
behålls. EMP och robotförsäljning ligger kvar i [att-göra-listan](BACKLOG.md).
