# Testa v0.9 på Windows

Alla spelets egna texter är nu på **engelska**. Vi använder svenska för instruktioner och samtal.

## Öppna rätt platsfil

1. Hämta **Catch-the-scrap-v0.9.rbxl** från `downloads` på GitHub-grenen `codex/carry-admin-hud-random-spawns`. Klicka **Download raw file**, nedåtpilen vid filen.
2. Stoppa pågående Play i Roblox Studio. Öppna den **nya** filen via **File → Open from File… / Ctrl+O**.
3. Tryck **Play / F5**. Världen skapas vid spelstart; en tom editor före Play är normalt.
4. Öppna **Output** via View/Window om du behöver se felmeddelanden.

## Spela

- **WASD:** gå. **Mellanslag:** hoppa. Håll höger musknapp för att vrida kameran vid behov.
- Följ **gula pilar** mot skrotgården. **Turkosa pilar** inne i gården leder tillbaka.
- Gå nära en del och håll **E / Pick up**. Mobil använder upphämtningsknappen på skärmen.
- **Q / Drop [Q]** släpper delen och återställer farten.
- Gå in i din egen verkstad och håll **E / Deliver scrap or box** vid maskinen med orange kant.

Skrotgården är **160 studs bred och 3 360 studs lång**, med sju områden och 32 upphämtningsplatser i varje. Områdena heter **Sorting Yard**, **Machine Graveyard**, **Reactor Wrecks**, **Turbine Foundry**, **Golden Furnace**, **Void Salvage** och **Starforge Ruins**. Vanliga skrotdelar återkommer efter åtta sekunder på nya slumpade positioner. Släppta delar dupliceras inte.

## Nytt i v0.9: välj bärsätt, admin, mindre HUD och slumpat skrot

### Bärandet är ombyggt

Den gamla klientposen med upplyfta armar är borttagen. Fyndet bärs nu framför kroppen eller i en sele bakom ryggen.

Öppna **Details** i den lilla pengapanelen och välj:

- **Auto:** R15 använder Roblox tvåhands-IK. R6 använder vanlig Tool-hållning. Om IK misslyckas används Tool som reserv; klienten kontrollerar även om händerna faktiskt når målen och kan byta till Handheld.
- **Handheld:** vanlig Roblox Tool-hållning direkt.
- **Harness:** fyndet fästs i en lastsele bakom ryggen och kräver ingen arm-animation.

Du kan byta medan du bär utan att tappa fyndet eller ändra dess innehåll. **Q / Drop** och inlämning fungerar som tidigare. Rätt bärsätt och handplacering måste fortfarande provas med din avatar i Studio; Harness finns som ett oberoende alternativ.

### Adminmenyn

**Ditt UserId 11824623188 är tillagt.** Tryck **F4** eller klicka **ADMIN** uppe till höger.

- **Cash / Set:** sätter ditt saldo. **Add:** lägger till beloppet.
- **Speed:** sätter din faktiska gångfart, även när du bär. Tillåtet 7–120.
- **Strength:** sätter din bärstyrka. Tillåtet 1–10 000.
- **Reset stats:** tar bort adminvärden och återgår till vanliga/köpta stats.
- **Return to base:** flyttar dig till din verkstad.
- **Spawn robot box event:** välj Rare/Epic/Legendary/Mythic/Celestial genom att klicka rarity-knappen. Ange område **1–7** och tryck **Trigger event**. Område 1 är Common-området, även om själva boxen är Rare.

Pengar och stats ändras bara för dig. Eventet är servergemensamt. Högst två boxar får finnas; menyn raderar inte någon annans buren box för att skapa plats. Maxsaldo är $1 000 000 000. Alla adminvärden gäller bara serverbesöket.

I **Studio** tillåts lokala testspelare så menyn fungerar direkt. I det **publicerade spelet** gäller det angivna UserId:t och spelets personliga ägare. Att visa en falsk admin-knapp i en modifierad klient ger ingen serverbehörighet.

### Ny HUD

Pengapanelen visar bara **saldo, inkomst och bas**. Det lilla målfältet visar en aktuell robotprogress eller vad du bär och vart det ska lämnas. **Drop** visas när du bär. Alla recept, robotantal, stats och bäralternativ ligger under **Details**. Meddelanden visas kort och försvinner.

### Slumpmässiga skrotpositioner

Vanligt skrot får en ny, slumpad position vid serverstart och efter inlämning/respawn. Det stannar i rätt rarity-område. En ersättningsdel hamnar minst **12 studs** från den förra positionen och undviker mittvägen, hinder, andra markfynd och reserverade boxplatser. Normal respawntid är fortfarande åtta sekunder efter godkänd inlämning. Släpp/död skapar inte extra delar.

### Testa detta bygge

1. Öppna den nya platsfilen. Den lilla pengapanelen visar att v0.9 laddats.
2. Plocka upp en Common-del. Prova **Auto**, **Handheld** och **Harness** under Details. Spring, hoppa, släpp, plocka upp igen och lämna in.
3. Öppna **F4 / Admin**, sätt exempelvis cash till 10 000 och speed till 60. Kontrollera direkt effekt och prova Reset stats.
4. Trigga **Rare / Stage 1**. Hämta boxen, testa bärsätten och lämna in på en ledig robotplattform.
5. Samla och lämna in flera skrotdelar. Återkom efter åtta sekunder: ersättningarna ska dyka upp på andra fria platser i området.
6. Testa R6/R15, Reset Character, två spelare, mobilvy och gång genom streaminggränser. Kontrollera att gamla IK-kontroller, Tools eller selremmar försvinner när de inte används.

[HUD-layout och tekniska detaljer](REWORK_V09.md). Förhandsbilden är en UI-illustration, inte en Studio-skärmbild.

### Sällsynta robotboxar

- Det ligger inte längre 14 boxar på kartan vid start. **Första eventet kommer efter ungefär 60 sekunder**. En liten räknare högst upp visar tiden.
- Därefter sker ett event ungefär **var 4–7 minut**, med högst två levande boxar inklusive sådana som bärs.
- Alla får en stor annons, till exempel **“A Rare Robot Box has spawned!”**, med rätt område. Följ den färgade ljuspelaren i området.
- En **Rare Robot Box innehåller alltid en Rare-robot**. Epic, Legendary, Mythic och Celestial-boxar kan också förekomma. Modellen är hemlig tills öppningen är klar.
- Boxar som ligger obevakade på marken försvinner efter tre minuter. En buren box försvinner inte ur händerna. Om den släpps börjar marktimern om.

### Öppna en box hemma

1. Håll **E / Recover box**, bär hem och lämna in med **E / Deliver scrap or box**.
2. Du behöver **en ledig robotplattform**. Påbörjade skrotprojekt får vara kvar.
3. Öppningen tar **5,6 sekunder**: laddning, skakningar, tejp som brister, luckor som öppnas, hologram som växlar, energiringar och kartongpaneler som flyger isär.
4. Den riktiga roboten avslöjas med namn och inkomst. Först då börjar den tjäna pengar.

| Modell | Rare-inkomst |
|---|---:|
| Iron Bastion | $80/sek |
| Volt Runner | $92/sek |
| Drillmaster | $108/sek |
| Magnetron | $120/sek |
| Orbital Warden | $144/sek |
| Sunforge Sentinel | $180/sek |

Modellerna har olika geometri: tung rustning, smal sprintkropp, borrarm, banddrift/magnet, svävande kropp eller solvingar/extra armar. Inkomsterna är testbalans. Samma modell upprepas inte i två på varandra följande serverboxar. Släpp/reset ändrar aldrig innehållet.

### Testa detta bygge

- [ ] Öppna den nya filen och kontrollera bärposen med avataren från bilden.
- [ ] Vänta på första eventet i en ny Play-session och se att annons och ljuspelare stämmer med boxens rarity och område.
- [ ] Testa med två spelare: båda får samma annons, en spelare kan ta boxen och bara ägaren får roboten efter leverans.
- [ ] Anslut en andra spelare efter spawn: en kvarvarande obevakad box ska också annonseras för den spelaren.
- [ ] Kontrollera hela öppningen, namnet, rätt modell och rätt inkomst enligt tabellen. Hologrammen under avläsningen är förhandsvisningar; bara slutresultatet är belöningen.
- [ ] Släpp och plocka upp boxen igen. Innehållet och den annonserade rarityn ska inte ändras.
- [ ] Full bas eller fel verkstad ska behålla boxen i händerna. Ett nytt event ska inte starta genom snabb inlämning eller mark-expiry.
- [ ] Kontrollera att armarna återgår normalt efter Q, inlämning, död och reset, och att andra spelare ser bärposen.
- [ ] Prova låg grafik, telefonläge, streaming och återkomst till basen. Inga gamla hologram, ringar eller armposer ska ligga kvar.

[Bilder på de sex modellerna och eventdetaljer](RARE_EVENTS_V08.md). Bilden är en Blender-modellrendering, inte en Studio-skärmbild.

## Matchande delar och robotar

| Robot | Delar som krävs | Inkomst |
|---|---:|---:|
| Common | 5 Common | $5/sek |
| Uncommon | 7 Uncommon | $10/sek |
| Rare | 10 Rare | $20/sek |
| Epic | 12 Epic | $45/sek |
| Legendary | 15 Legendary | $100/sek |
| Mythic | 18 Mythic | $225/sek |
| Celestial | 20 Celestial | $500/sek |

Common och Rare följer dina önskade recept. Övriga nya värden är tills vidare testbalans. En Common-del kan aldrig ersätta en Rare-del.

Första inlämningen av en rarity startar ett projekt på en ledig robotplattform. Nästa del av samma rarity fortsätter det projektet. Det går att arbeta på flera rarities samtidigt. Varje projekt reserverar sin plattform, så andra robotbyggen inte kan ta platsen innan det är färdigt. Det finns fyra plattformar per spelare. Alla sju områden är öppna från början; välj vilka fyra robotprojekt du vill bygga. Byte/återvinning av färdiga robotar ingår ännu inte.

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

## Nytt i v0.6: områden, kamera och animerat skrot

Väggarna är nu **64 studs höga** runt både banan och basområdet. Kameran begränsas innanför yttergränserna, även när kartdelar strömmas in. Vanlig högerknappsrotation och mobilkamera finns kvar, med högst 32 studs utzoomning. Föremålen svävar mjukt, roterar, vickar och har en pulserande ring på marken. Ringen döljs och animationen stoppas när en del bärs.

- [ ] Håll höger musknapp och vrid kameran vid båda långväggarna, basområdets bakvägg, sista väggen och ingångens hörn. Zooma ut och prova shift lock/förstaperson. Kameran ska hållas på insidan utan att klippa igenom ytterväggen.
- [ ] Prova samma sak i telefonläge, både stående och liggande, samt efter Reset Character.
- [ ] Gå genom alla sju områden. HUD:ens receptlista följer området när du går in; du kan också scrolla i listan.
- [ ] Prova att plocka upp/släppa en del medan den studsar, direkt efter respawn och efter att ha lämnat området och återvänt. Den ska följa spelaren stadigt under bärandet.
- [ ] Testa Epic, Legendary, Mythic och Celestial som nya robotprojekt i separata serverbesök om plattformarna tar slut. Kontrollera exakt delantal och inkomst enligt tabellen.

[Modellbilder och tekniska uppgifter](STAGES_V06.md)

## Visuell genomgång av v0.6

Det nya bygget har höga skrotklädda väggar, lagad plåt, silor, markslitage, olje-/våtfläckar, avrinningsgaller, verkstadsljus och mer detaljerade fynd, baser, robotar och mekaniker. Ljuset ligger i sen eftermiddag. Rök och gnistor är sparsamma och aktiveras i närheten av spelaren.

- [ ] Öppna den **nya platsfilen**. Streaming- och ljusinställningar ingår i den; använd den som utgångspunkt även om du tidigare synkat koden till en äldre plats.
- [ ] Gå genom alla sju områden och bedöm ljus, material, väggarnas skrotklädsel och att text och upphämtningsdelar är tydliga.
- [ ] Kontrollera att mittvägen och alla upphämtningsplatser är fria från nya hinder.
- [ ] Plocka upp, bär, släpp och lämna in alla sju sorters skrot. Modellerna ska följa spelaren utan kollision; släppta modeller ska börja sväva igen över markytan.
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
