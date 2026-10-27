# Testa v1.0 på Windows

Spelets egna texter är på **engelska**. Här använder vi svenska.

## Öppna nya platsfilen

1. [Hämta Catch-the-scrap-v1.0.rbxl](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/rarity-cinematics-robot-index/downloads/Catch-the-scrap-v1.0.rbxl).
   Om GitHub visar filsidan: klicka **Download raw file** / nedåtpilen.
2. Stoppa gamla Play i Roblox Studio. Öppna **den nya filen** med **Ctrl+O**.
3. Tryck **Play / F5**. Banan byggs vid spelstart; en tom editor före Play är normalt.
4. Öppna **Output** via View/Window för eventuella felmeddelanden.

## Nytt: färger och robotindex

- Common är silver, Uncommon grön, Rare blå, **Epic lila**, **Legendary guld**,
  Mythic rosa/röd och **Celestial animerad RGB**.
- Epic+ skrot och boxar får ljus och partiklar. Celestials regnbåge rör sig längs
  boxens ram och fortsätter i öppningseffekter och indexets ram.
- Tryck **I** eller välj **Details → Robot Index**. Rarity-knappen växlar område.
  Det finns **tio modeller per rarity**, totalt 70 samlingsposter.
- Klicka en modell för 3D-förhandsvisning och inkomst. **Use for next build** väljer
  vilket bygge du vill starta med nästa del. Det ger ingen gratis robot.
- Första inlämningen låser modellen för det projektet. Ett nytt val påverkar
  nästa bygge. Färdig robot eller färdig boxöppning registrerar upptäckten.
- Rare och högre har byggexklusiva modeller, boxexklusiva modeller och några som
  finns på båda sätten. Common/Uncommon har alla tio som byggbara modeller.
- Vid din egen inlämningsmaskin: **Your Platforms → Retire → Confirm Retire** tar
  bort en färdig robot och frigör platsen. Ingen återbetalning; inkomsten från
  roboten upphör. Upptäckten finns kvar under serverbesöket. Påbörjade byggen
  och aktiva öppningar kan inte tas bort.

**Allt sparas bara under aktuellt serverbesök**, även samlingsindexet. Reset
Character behåller framsteg i samma server; att lämna spelet rensar dem.

## Testa effekterna direkt med admin

Ditt UserId **11824623188** är tillagt. Studio tillåter också lokala testspelare;
i publicerat spel gäller ditt id och den personliga spelägaren.

1. Tryck **F4 / ADMIN**. Under **Spawn robot box event** välj **Epic**, område **1**
   och **Trigger event**. Område 1 ligger nära baserna, även för en hög rarity.
2. Hämta den annonserade boxen med **E / Recover box**. Den ska vara lila och lysa.
3. Bär hem, ha en ledig robotplattform och håll **E / Deliver scrap or box**.
4. Kontrollera laddning, luckor, hologram, energiringar, kristaller och avslöjande.
   Epic tar 7 sekunder; Legendary 8, Mythic 9 och Celestial 10,5.
5. Epic+ använder en särskild kamera för ägaren. **Mellanslag / Skip Camera**
   återställer kameran; öppningen och belöningen fortsätter. På kontroll används B.
6. Frigör en plattform genom att pensionera en färdig robot vid maskinen. Upprepa
   för **Legendary** (guld) och **Celestial** (rörlig RGB-ram och regnbågseffekter).
7. Det finns högst två levande eventboxar. Leverera eller invänta gamla boxar om
   admin säger att eventet inte kan startas.

Rare har också öppningseffekter men tar inte över kameran. Bara slutresultatet
är belöningen; hologrammen är förhandsvisningar. En annonserad Epic-box ger
alltid Epic. Släpp/reset ändrar inte dess hemliga modell.

Admin kan även sätta/lägga till egna pengar, sätta speed 7–120 och strength
1–10 000, återställa stats och återvända till basen. Maxsaldo $1 miljard.
Pengar/stats gäller dig; boxeventet visas för hela servern.

## Samla, bygga och uppgradera

**WASD** går, **E** plockar upp/lämnar in och **Q / Drop** släpper. Gula pilar
leder mot skrotgården, turkosa tillbaka. Mobil använder skärmknappar.

| Rarity | Matchande delar | Basinkomst per sekund |
|---|---:|---:|
| Common | 5 | $5 |
| Uncommon | 7 | $10 |
| Rare | 10 | $20 |
| Epic | 12 | $45 |
| Legendary | 15 | $100 |
| Mythic | 18 | $225 |
| Celestial | 20 | $500 |

Inkomsten multipliceras med vald modell. En byggd Rare Volt Runner ger $23/sek;
samma modell från box ger $92/sek. Indexet visar rätt värden för respektive väg.
Fyra robotplattformar finns. Endast färdiga robotar ger pengar.

Under **Details** finns recept, stats och bärsätten **Auto**, **Handheld** och
**Harness**. Auto använder R15-IK med Tool-reserv; R6 använder Tool. Harness
fäster fyndet i en lastsele. Du kan byta medan du bär. Avatarpassning måste
fortfarande kontrolleras i Studio.

**Milo the Mechanic** står till höger om gårdens entré. **E / Browse upgrades**
öppnar köpmenyn. Första Speed kostar $75 och ökar grundfart 24→26. Första
Strength kostar $100 och ökar styrka 30→40. Båda har tio nivåer. Stäng med X
eller gå bort. Inkomster fortsätter medan du handlar.

Banan är 160×3 360 studs och har sju områden med 32 vanliga fynd vardera.
Vanligt skrot får en ny säker slumpad position vid start och återkomst, minst
12 studs från förra positionen. Normal återkomst är åtta sekunder efter leverans.
Naturliga boxevent börjar efter cirka 60 sekunder och sedan var 4–7 minut.
Obevakade markboxar försvinner efter tre minuter; burna boxar försvinner inte.

## Studio-testlista

- [ ] Kontrollera alla sju färger på fynd, text, index och färdiga robotar.
- [ ] Kontrollera lila/guld-ljus och partiklar på Epic/Legendary samt rörlig RGB
  längs Celestials boxram före och under öppning.
- [ ] Välj en byggmodell, lämna första delen, byt val och slutför. Det pågående
  projektet ska behålla första valet; nästa projekt ska använda det nya.
- [ ] Boxexklusiv modell ska inte gå att välja som bygge. Byggexklusiva modeller
  ska inte visas som möjliga boxresultat. Slutresultatet ska markera en upptäckt.
- [ ] Pensionera en färdig robot medan en annan box öppnas. Den öppningen ska
  avslutas på sin flyttade plattform och ge rätt modell/inkomst.
- [ ] Skippa kameran, dö/Reset Character och gå bort under separata öppningar.
  Vanlig kamera, HUD, promptar och synfält ska återställas utan extra belöning.
- [ ] Testa med två spelare: båda ser boxannonsen och närliggande 3D-effekter;
  bara ägaren får roboten och filmkameran. Fel verkstad/full bas behåller boxen.
- [ ] Testa **I / Details**, rarity-byte, 3D-preview, scroll och pensionering i
  Device Emulator, stående och liggande. Kontrollera på riktig mobil också.
- [ ] Prova R6/R15, alla tre bärsätt, Q, leverans, död och reset. Inga gamla
  Tools, selar eller handmål ska ligga kvar.
- [ ] Gå genom streaminggränser, återvänd till basen och prova låg/hög grafik.
  Kontrollera att effekter städas och återkommer; mät faktisk FPS på enheten.
- [ ] Rotera/zooma kameran vid långväggar, basernas bakvägg och entréhörn.
  Vanlig kamera ska hållas innanför väggarna, med högst 32 studs utzoomning.

Tvåspelartest: stoppa Play och använd **Server & Clients / Local Server** med
två spelare. Åtta verkstäder finns; automatisk kö ingår inte.

## Källkod och felsökning

[Modeller, färgprofiler och regler](RARITY_COLLECTION_V10.md) ·
[Redigerbar källkod](../downloads/Catch-the-scrap-v1.0-source.zip)

Bilderna i dokumentationen är Blender-renderingar av geometri, inte Studio-
skärmbilder. De automatiska testerna kör regler och simulerade motorgränser;
Roblox-kamera, ljus, avatarpassning, GUI och mobilprestanda behöver testas här.
Sparning, offlineinkomst, fiender, prestige och fullständigt skydd mot rörelsefusk
ingår ännu inte.

Vid fel: skicka den **första röda feltexten i Output** och vad du gjorde före
felet. Normal serverstart skriver en rad med `[Catch the Scrap] Scrapyard ready`.

ZIP-filen packas upp före redigering. För kodsynk kan du använda Rojo 7.7.1 och
motsvarande officiella Studio-plugin lokalt på Windows. PowerShell i mappen:

```powershell
& 'C:\Tools\Rojo\rojo.exe' serve default.project.json
```

Stoppa Play, anslut pluginet till localhost:34872 och granska synken i en kopia.
Molnets localhost är en annan dator än din Windows-dator. Ett nytt platsbygge:

```powershell
& 'C:\Tools\Rojo\rojo.exe' build default.project.json --output Catch-the-scrap.rbxl
```

Automatiska kontroller: `python scripts/check.py` med Python 3, Rojo 7.7.1 och
Luau 0.744 i PATH. Molnmiljön har dessa verktyg.
