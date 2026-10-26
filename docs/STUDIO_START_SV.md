# Testa v0.5 på Windows

Alla spelets egna texter är nu på **engelska**. Vi använder svenska för instruktioner och samtal.

## Öppna rätt platsfil

1. Hämta **Catch-the-scrap-v0.5.rbxl** från `downloads` på GitHub-grenen `codex/scrapyard-visual-overhaul`. Klicka **Download raw file**, nedåtpilen vid filen.
2. Stoppa pågående Play i Roblox Studio. Öppna den **nya** filen via **File → Open from File… / Ctrl+O**.
3. Tryck **Play / F5**. Världen skapas vid spelstart; en tom editor före Play är normalt.
4. Öppna **Output** via View/Window om du behöver se felmeddelanden.

## Spela

- **WASD:** gå. **Mellanslag:** hoppa. Håll höger musknapp för att vrida kameran vid behov.
- Följ **gula pilar** mot skrotgården. **Turkosa pilar** inne i gården leder tillbaka.
- Gå nära en del och håll **E / Pick up**. Mobil använder upphämtningsknappen på skärmen.
- **Q / Drop [Q]** släpper delen och återställer farten.
- Gå in i din egen verkstad och håll **E / Deposit part** vid maskinen med orange kant.

Skrotgården är **160 studs bred och 1 440 studs lång**, med tre områden och 32 upphämtningsplatser i varje. Områdena heter **Sorting Yard**, **Machine Graveyard** och **Reactor Wrecks**. Föremål återkommer åtta sekunder efter inlämning. Släppta delar dupliceras inte.

## Matchande delar och robotar

| Robot | Delar som krävs | Inkomst |
|---|---:|---:|
| Common | 5 Common | $5/sek |
| Uncommon | 7 Uncommon | $10/sek |
| Rare | 10 Rare | $20/sek |

Common och Rare följer dina önskade recept. Uncommon-värdena är tills vidare testbalans. En Common-del kan aldrig ersätta en Rare-del.

Första inlämningen av en rarity startar ett projekt på en ledig robotplattform. Nästa del av samma rarity fortsätter det projektet. Det går att arbeta på flera rarities samtidigt. Varje projekt reserverar sin plattform, så andra robotbyggen inte kan ta platsen innan det är färdigt. Det finns fyra plattformar per spelare.

Robotmodellen har fem visuella monteringsgrupper: ben/fötter, kropp, armar, huvud samt reaktor/slutdetaljer. Common visar en ny grupp per del. Rare behöver två delar per grupp. Bara färdiga robotar ger pengar. HUD:ens rarity-räknare återgår till noll efter färdig robot och kan starta ett nytt projekt om det finns plats.

## Köp uppgraderingar av mekanikern

1. Bygg först en Common-robot av fem Common-delar. Den tjänar $5/sek.
2. Gå till **Milo the Mechanic** vid den högra sidan av skrotgårdens ingång. Det är en liten robot med skyddsglasögon och skiftnyckel bakom en verktygsdisk.
3. Gå nära och håll **E / Browse upgrades**. Köpmenyn visar saldo, nivå, nuvarande värde, nästa värde och pris.
4. Första **Speed** kostar **$75** och höjer grundfarten **24 → 26**. Den ökar också farten när du bär något.
5. Första **Strength** kostar **$100** och höjer bärstyrkan **30 → 40**. Den minskar viktens fartstraff och ändrar inte din obelastade grundfart.
6. Priserna ökar per nivå. Nästa Speed kostar $120 och nästa Strength $165. Båda har maxnivå 10.
7. Knappen är inaktiv om du saknar pengar eller redan nått maxnivån. Inkomsterna fortsätter medan du tittar på menyn.
8. Stäng med **X** eller genom att gå bort från Milo. Du måste stå vid honom för att köpa.

Första Speed kan betalas efter cirka 15 sekunders produktion från en Common-robot. Inkomsten fortsätter ticka under köp. Uppgraderingarna påverkar karaktären direkt, även om du bär en del. De finns kvar efter Reset Character men försvinner om du lämnar servern.

### Testlista för köp

- [ ] Milo står vid en egen disk, utanför huvudvägen och utan att krocka med någon bas.
- [ ] E öppnar menyn först när du är nära; båda erbjudandena har tydliga priser och statförändringar.
- [ ] För lite pengar ger inget köp eller negativt saldo.
- [ ] Ett Speed-köp drar det visade priset och ändrar fart och nivå direkt.
- [ ] Strength gör det lättare att bära en Rare-del; vanlig grundfart ändras inte av Strength.
- [ ] Upprepade snabba klick köper inte två nivåer till samma gamla pris.
- [ ] Att gå bort stänger menyn. Köp från långt håll nekas.
- [ ] X, bakgrundsklick och köpknappar fungerar utan att menyn stängs när du klickar på ett kort.
- [ ] Reset Character behåller de köpta nivåerna i samma serverbesök.
- [ ] Två spelare har separata saldon och nivåer och kan handla samtidigt.
- [ ] Menyn och köpknapparna går att använda i telefonläge, stående och liggande.

## Visuell genomgång av v0.5

Det nya bygget har höga skrotklädda väggar, lagad plåt, silor, markslitage, olje-/våtfläckar, avrinningsgaller, verkstadsljus och mer detaljerade fynd, baser, robotar och mekaniker. Ljuset ligger i sen eftermiddag. Rök och gnistor är sparsamma och aktiveras i närheten av spelaren.

- [ ] Öppna den **nya platsfilen**. Streaming- och ljusinställningar ingår i den; använd den som utgångspunkt även om du tidigare synkat koden till en äldre plats.
- [ ] Gå genom alla tre områden och bedöm ljus, material, väggarnas skrotklädsel och att text och upphämtningsdelar är tydliga.
- [ ] Kontrollera att mittvägen och alla upphämtningsplatser är fria från nya hinder.
- [ ] Plocka upp, bär, släpp och lämna in Common Gear, Uncommon Motor och Rare Core. Modellerna ska följa spelaren utan kollision, och släppta modeller ska ligga över markytan.
- [ ] Släpp en del nära ytterväggen: den ska hamna säkert eller återställas till sin ursprungsplats, inte bli oåtkomlig bakom väggen.
- [ ] Gå längst bort i banan och tillbaka. Den egna basen, robotarna och inlämningen ska fortfarande fungera.
- [ ] Reset Character från Rare-området ska ge en säker återkomst till den egna basen.
- [ ] Milo och köpmenyn ska fortfarande fungera efter en lång tur och återkomst.
- [ ] Ljus och partiklar ska dyka upp nära spelaren utan att blinka eller påverka kontrollerna. Reaktorpulser ska fungera efter att du lämnat ett område och kommit tillbaka.
- [ ] Testa både hög och låg grafiknivå och telefonläget. Mät faktisk prestanda i Studio/enhet; bilderna från modellrenderaren visar inte FPS.

Förhandsbilderna är Blender-renderingar av modellernas geometri. Roblox Studio använder andra ljus-, material- och texteffekter. De är inte skärmbilder från ett genomfört Studio-test.

## Testlista för detta bygge

- [ ] Inga stora svarta skyltpaneler svävar över banan. Världstexten har genomskinlig bakgrund.
- [ ] Gula pilar vid baserna pekar ut mot skrotgården, inte tillbaka mot verkstädernas bakre del.
- [ ] Gult och turkost pekar åt motsatta håll inne i skrotgården.
- [ ] All egen HUD, alla promptar, föremålsnamn, meddelanden och verkstadsskyltar är på engelska.
- [ ] Fem Common-delar bygger exakt en Common-robot och ger $5/sek.
- [ ] Nio Rare-delar ger ingen Rare-robot eller Rare-inkomst; den tionde ger en Rare-robot och $20/sek.
- [ ] Inlämning av Common påverkar inte Rare-progress och tvärtom.
- [ ] Färdiga robotar har rätt färg och rarity-text på sin plattform.
- [ ] Fyra reserverade platser nekar ett nytt projekt men låter dig slutföra ett redan påbörjat med rätt sorts del.
- [ ] Nekad inlämning behåller delen i händerna och ger inget extra antal eller pengar.
- [ ] Mittvägen genom skrotgården är fri. Inga upphämtningsdelar ligger inuti stora skrothögar eller containrar.
- [ ] Kameran, promptarna och de flytande texterna fungerar när du går genom hela banan.
- [ ] Reset Character återställer buren del till spawn och behåller redan inlämnad progress, robotar och pengar under samma serverbesök.

### Två spelare och mobil

Stoppa Play och använd Studios lokala **Server & Clients / Local Server** med två spelare. Kontrollera olika verkstäder, separata rarity-räknare och saldon, nekad inlämning i någon annans verkstad samt att bara en spelare kan ta samma del. Testa därefter telefon i **Device Emulator**, både stående och liggande, och prova rörelse, upphämtning, Drop och Deposit. Bekräfta på riktig mobil före publicering.

Åtta verkstäder finns. Testa med högst åtta spelare. Automatisk kö ingår inte.

## Begränsningar och felsökning

Delar, robotar och pengar gäller bara **aktuellt serverbesök**. Sparning, offlineinkomst, fler uppgraderingstyper, fiender och prestige kommer senare. Ett komplett system mot rörelse-/teleportfusk ingår inte.

Om något går fel: skicka **första röda feltexten i Output**, gärna med en bild och vad du gjorde precis före felet. Normal serverstart skriver en engelsk rad som börjar med `[Catch the Scrap] Scrapyard ready`.

## Källkod och lokal synk

Redigerbar källkod följer med som ZIP i `downloads`. Packa upp innan användning. För första testet behövs bara platsfilen, inget plugin.

För fortsatt kodsynk används **Rojo 7.7.1** lokalt på din Windows-dator med motsvarande officiella Studio-plugin. Öppna PowerShell i mappen med `default.project.json` och kör exempelvis:

```powershell
& 'C:\Tools\Rojo\rojo.exe' serve default.project.json
```

Stoppa Play, anslut pluginet till localhost:34872 och granska synkförslaget i en kopia av platsen. Molnets localhost är en annan dator än din Windows-dator.

Nytt platsbygge utan plugin:

```powershell
& 'C:\Tools\Rojo\rojo.exe' build default.project.json --output Catch-the-scrap.rbxl
```

Alla automatiska kontroller: `python scripts/check.py`, med Python 3, Rojo 7.7.1 och Luau 0.744 i PATH. Molnmiljön har redan verktygen.
