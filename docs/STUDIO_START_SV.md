# Första testet i Roblox Studio – Windows

Det här bygget har **verkstadsbaser, robotbygge och pengar per sekund** utöver plocka upp, bära och släppa. Banan och dina verkstäder skapas automatiskt när du trycker Play. Du ska inte bygga kartan eller klistra in en massa skript själv.

## 1. Öppna den färdiga platsfilen

1. Installera **Roblox Studio** från Roblox officiella webbplats om du inte redan har det. Starta Studio och logga in på ditt Roblox-konto på din egen dator.
2. Hämta den nya filen **Catch-the-scrap-v0.2.rbxl** från mappen `downloads` på GitHub-grenen `codex/workshop-robots`. Spara den exempelvis i `Hämtade filer`. Om du bygger från källkoden finns filen i mappen `build`.
3. I Studio väljer du **File → Open from File…** (eller **Ctrl+O**). Välj `Catch-the-scrap-v0.2.rbxl` (eller filnamnet som du själv sparade). Om din Studio-version visar **Open…**, välj det alternativet för att öppna en lokal fil.
4. Öppna panelerna **Explorer** och **Output** via **View** eller **Window**, beroende på Studio-version. Output visar utskrifter och felmeddelanden.
5. Tryck **Play** under testkontrollerna eller **F5**. Använd Play med en spelarkaraktär, inte enbart **Run**.
6. En karta, åtta verkstäder och tolv fynd ska nu visas. Du ska hamna i din egen verkstad med en ruta märkt **CATCH THE SCRAP** uppe till vänster.

Det är normalt att världen är tom **före Play**: kartan byggs av servern vid spelstart. Du behöver inget Rojo-plugin för att öppna och testa platsfilen.

## 2. Spela igenom första loopen

1. Titta i rutan efter **VERKSTAD**, exempelvis **1**. Basens skylt visar också ditt namn och nummer.
2. Gå med **WASD**, hoppa med **mellanslag**, och vänd kameran med musen (håll höger musknapp vid behov).
3. Följ banan ut från basområdet till **ZON 1 · Common**.
4. Gå nära ett **Kugghjul**. Håll **E** en kort stund när **Plocka upp** visas.
5. Föremålet ska synas framför dig. Rutan ska visa namn, rarity, vikt och lägre fart.
6. Tryck **Q** eller knappen **Släpp** längst ned för att lägga ned föremålet. Du ska få tillbaka din vanliga fart. Plocka upp det igen med E.
7. Gå tillbaka till **din egen bas**. Gå in genom porten och fram till inlämningsmaskinen med orange kant och håll **E** när **Lämna scrap** visas.
8. Föremålet ska försvinna ur händerna, din fart återställas och **INLÄMNAT** öka med exakt ett. Robotbyggets progress ska öka med ett scrap. Spelarlistan visar även antal inlämnade fynd.
9. Efter cirka **8 sekunder** dyker ett nytt föremål upp på fyndets ursprungliga plats på banan.
10. Prova också **Skrotmotor** i zon 2 och **Robotkärna** i zon 3. De är tyngre och gör hemresan långsammare.

Testvärden: grundfart **24**, Strength **30**, vikter **10 / 60 / 150**, lägsta fart **7**. Det här är justerbara prototypvärden, inte slutlig balans.

## Bygg din första robot

1. Lämna in totalt **10 fynd** i din egen maskin. Varje fynd ger **1 scrap** i det här testbygget.
2. Titta på första robotplattformen efter varje inlämning. En ny del blir synlig och framtida delar syns som en genomskinlig ritning.
3. Vid **10/10** blir roboten färdig automatiskt. Nästa robot börjar på **0/10** i nästa lediga plats.
4. HUD:en ska visa **1/4 robotar** och **+$5/sek**. Pengarna börjar öka först nu; en halvfärdig robot tjänar inget.
5. Vänta ungefär tio sekunder. Saldoökningen ska motsvara cirka **$50**, med någon sekunds marginal för när du börjar och slutar mäta.
6. Ytterligare tio scrap bygger nästa robot: två robotar ger **$10/sek**. Fyra ger **$20/sek**.
7. När fyra robotplatser är fyllda nekas nya inlämningar. Föremålet stannar i händerna och du kan släppa det med Q.

Robotar, byggprogress och pengar finns kvar om karaktären dör under samma serverbesök. De **sparas inte mellan serverbesök**. Inget spenderings- eller uppgraderingssystem finns ännu.

## 3. Manuell testlista

Bocka av efter ett riktigt Studio-test. Dessa punkter är **inte automatiskt verifierade av molnbygget**.

- [ ] Play skapar bana, baser och HUD utan röda fel i Output.
- [ ] Du börjar i en bas vars skylt och HUD visar samma nummer.
- [ ] Ett fynd kan plockas upp, visas framför spelaren och sänker farten.
- [ ] Ett andra fynd nekas medan du redan bär ett.
- [ ] Q och knappen Släpp återställer farten; det släppta fyndet kan plockas upp igen.
- [ ] Din egen bas tar emot fyndet och räknaren ökar exakt en gång.
- [ ] Den tionde inlämningen färdigställer exakt en robot och ger $5/sek.
- [ ] Byggdelar och progress visar 1–9/10 före färdig robot utan inkomst.
- [ ] Två robotar ger $10/sek och fyra ger $20/sek.
- [ ] En full verkstad låter spelaren behålla fyndet vid nekad inlämning.
- [ ] En annan spelares bas nekar inlämning och låter dig behålla fyndet.
- [ ] Inlämning utan fynd ger inget extra antal.
- [ ] Nya fynd återkommer efter ungefär åtta sekunder utan att dubbleras.
- [ ] **Reset Character** medan du bär något återställer fyndet till dess ursprungsplats. Tidigare inlämnat antal, robotar och pengar finns kvar under samma spelsession.
- [ ] När du slutar med **Stop** och startar en ny server är räknaren noll: ingen DataStore används ännu.

### Två spelare

1. Stoppa först det vanliga Play-testet.
2. Öppna Studios testläge för en **lokal server med två klienter**. Beroende på Studio-version ligger det under **Test → Server & Clients** eller **Local Server**, välj **2 players/clients** och sedan **Start/Play**.
3. Kontrollera att spelarna får olika verkstäder och separata saldon/progress.
4. Försök plocka upp samma fynd samtidigt. Bara en spelare ska få det.
5. Försök lämna in i den andra spelarens bas: inlämningen ska nekas.
6. Stäng en klient medan den bär ett fynd. Den andra klienten ska kunna hitta det på dess ursprungsplats.
7. Stoppa hela server-/klienttestet via Studios testkontroller.

Prototypen har **åtta basplatser**. Testa med högst åtta samtidiga spelare. En nionde spelare får ingen bas och kan inte hämta fynd. Automatisk kö och omfördelning ingår inte ännu.

### Mobil

1. Öppna Studios **Device Emulator** och välj en telefon. Den ligger i testverktygen; menyplaceringen kan skilja mellan Studio-versioner.
2. Starta Play och kontrollera att HUD:en går att läsa och att rörelse- och hoppkontrollerna fortfarande går att använda.
3. Gå nära ett fynd och håll inne upphämtningsknappen på skärmen.
4. Prova **Släpp föremål** och håll inne inlämningsknappen vid maskinen inne i din verkstad.
5. Bekräfta senare på en riktig mobil före publicering; emulatorn ersätter inte ett enhetstest.

## 4. Om något inte fungerar

1. Stoppa testet.
2. Öppna **Output**, starta Play igen och leta efter **det första röda felmeddelandet**.
3. En normal serverstart skriver `[Catch the Scrap] Verkstäder startade: 10 scrap = 1 robot, $5/sek, 4 platser per bas. Ingen datasparning.`
4. Skicka den exakta röda feltexten och gärna en skärmbild av Output. Berätta även vad du gjorde precis före felet.

Om kartan förblir tom: kontrollera att du öppnat den nya platsfilen och använt **Play**. I Explorer ska `ServerScriptService → CatchTheScrap → Main` finnas och vara ett vanligt server-Script. Klientskriptet finns i `StarterPlayer → StarterPlayerScripts → CatchTheScrap → Main`. Modulerna finns i `ReplicatedStorage → CatchTheScrapShared`. Du behöver inte flytta dem.

Om du ser kartan men inga upphämtningsknappar: klicka i spelfönstret, gå närmare fyndet och kontrollera att du inte redan bär något.

## 5. Hur vi fortsätter ändra koden

Första testet kräver bara platsfilen. Den redigerbara källkoden följer också med i `Catch-the-scrap-source.zip`. Packa upp ZIP-filen till en vanlig mapp före användning.

Vi använder **Rojo 7.7.1** när du senare vill synka kod från datorn till Studio:

1. Hämta Windows x86_64-versionen från [Rojos officiella release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), packa upp den och lägg `rojo.exe` där du hittar den.
2. Öppna PowerShell i källkodsmappen, där `default.project.json` ligger.
3. Kör Rojo med sin fullständiga sökväg, exempelvis `& 'C:\Tools\Rojo\rojo.exe' serve default.project.json`. Håll PowerShell-fönstret öppet. Det här kommandot körs **på din Windows-dator**.
4. Installera det officiella Rojo Studio-pluginet via länken i [Rojo-projektets dokumentation](https://github.com/rojo-rbx/rojo). Använd plugin-versionen för samma release som CLI:n.
5. Stoppa Play, öppna Rojo-pluginet i Studio och anslut till **localhost**, port **34872**. Granska synkförslaget och anslut i en kopia av platsen så att du inte råkar skriva över egna Studio-ändringar.
6. Kör Play igen efter synkningen.

Molnserverns `localhost` är en annan dator än din Windows-dator. Du kan öppna de exporterade platsfilerna från molnet, eller köra lokal Rojo-synk enligt stegen ovan.

För att skapa en ny platsfil på Windows räcker Rojo utan plugin:

```powershell
& 'C:\Tools\Rojo\rojo.exe' build default.project.json --output Catch-the-scrap.rbxl
```

Alla automatiska projektkontroller körs med `python scripts/check.py` om Python 3, Rojo 7.7.1 och Luau 0.744 finns i PATH. Luau-verktygen finns som Windows-arkiv på [den officiella releasen](https://github.com/luau-lang/luau/releases/tag/0.744).

## Nästa steg efter detta test

Fiender, mer avancerad crafting, uppgraderingar, sparning och prestige kommer senare. Nuvarande robotrecept och inkomst är testvärden. Servern kontrollerar upphämtning, avstånd, bärande, basägare, robotkapacitet och pengaproduktion. Ett komplett system mot rörelse-/teleportfusk ingår inte ännu.
