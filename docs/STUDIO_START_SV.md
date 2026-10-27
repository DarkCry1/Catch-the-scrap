# Testa v1.5 på Windows

Det här bygget fortsätter från din **v1.4-fil** och lägger till en gående
vaktrobot i varje rarity-område. Robotdex, sparning, mutationer, rebirth,
uppdrag, tvåhandsbärande och effekterna från v1.4 finns kvar.

## Öppna rätt fil

1. [Ladda ned Catch-the-scrap-v1.5.rbxl](https://github.com/DarkCry1/Catch-the-scrap/raw/refs/heads/codex/stage-guardians-v15/downloads/Catch-the-scrap-v1.5.rbxl).
   Om GitHub visar filsidan: klicka **Download raw file** / nedåtpilen.
2. Stoppa gamla Play i Studio. Öppna **nya filen med Ctrl+O**.
3. Tryck **Play/F5**. Banan skapas vid spelstart; tom editor före Play är normalt.
4. Öppna **Output** via View/Window för felmeddelanden.

## Börja med Common-vakten

1. Gå ut i Common-området utan att bära något. Den grå **Rustyard Watcher** ska
   patrullera utan att jaga dig. Exakt en vakt finns i området.
2. Plocka upp Common-skrot nära vakten och inom fri sikt. Den ska stanna,
   lysa rött och varna innan den börjar gå efter dig.
3. Spring hem med fyndet. Common-vakten jagar med 15 studs/sekund; högre
   rarities är snabbare och större. Den lämnar inte sitt område.
4. Prova **Q/Drop** under jakten. Vakten ska sluta jaga och svalna en stund.
5. Prova att stå kvar med loot tills den hinner fram. Bara fyndet ska återgå
   till gården. Pengar, färdiga robotar och Robotdex ska vara kvar.
6. Prova samma sak bakom ett solitt hinder. Vakten ska behöva gå runt det
   och inte kunna ta fyndet genom hindret.

Vakten skyddar loot som kommer från **dess eget område**, inklusive boxevent
som spawnat där. Den ska ignorera tomhänta spelare och loot från andra områden.

## Jämför alla sju

| Rarity | Modellhöjd, cirka | Jakthastighet |
|---|---:|---:|
| Common | 8,4 studs | 15 studs/sek |
| Uncommon | 9,7 studs | 17 studs/sek |
| Rare | 11,0 studs | 19 studs/sek |
| Epic | 12,3 studs | 22 studs/sek |
| Legendary | 14,3 studs | 25 studs/sek |
| Mythic | 16,1 studs | 28 studs/sek |
| Celestial | 17,9 studs | 31 studs/sek |

Värdena är vår första testbalans. De är inte uppmätta värden från Steal An Egg.
Sena områden kräver uppgraderingar, skydd bakom skrot, bra tajming eller att du
släpper fyndet. Varningen är 1,4–0,8 sekunder och jakten högst 7–10 sekunder.
Efteråt svalnar vakten i åtta sekunder.

**F4 / ADMIN** finns för ditt UserId **11824623188** och lokala Studio-testare.
Sätt exempelvis Speed till 80 för att snabbt nå alla områden. Välj **Reset
stats** innan du bedömer vanlig svårighetsgrad. Du kan även trigga boxevent i
valt område och återvända till basen.

## Kontrollera detta i Studio

- [ ] Exakt en gående robot i vart och ett av sju områden; inga gamla flygande
  säkerhetsdrönare finns kvar.
- [ ] Ben och armar rör sig under gång. Robotarna ser framåt när de går och
  ändrar inte höjd eller klipper genom skrothögar vid svängar.
- [ ] Större kropp och högre jakthastighet för varje rarity. Epic är lila,
  Legendary guld och Celestial har rörliga regnbågsdetaljer.
- [ ] Tomhänt spelare ignoreras; rätt loot och fri sikt utlöser en tydlig varning.
- [ ] Q, död, Reset Character, områdesgräns och överlevd jakttid avslutar jakten.
  Dropp eller död ska inte räknas som en lyckad Escape-uppgift.
- [ ] Vakten går aldrig in i nästa område eller hem till verkstäderna.
- [ ] Fångst återställer bara det burna fyndet och ger inga dubbla effekter.
- [ ] Två spelare kan vara i samma område; vakten har en måltavla åt gången,
  rätt person ser varningen och ingen annan förlorar sitt fynd.
- [ ] Gå långt bort och tillbaka genom streaming. Robotar och animationer ska
  återkomma utan dubbla modeller eller kvarlämnade varningar.
- [ ] Prova låg/hög grafik och mobilvy. Kontrollera FPS på riktig enhet.
- [ ] Bygg en robot, öppna Robotdex med I, prova uppdrag, mutation och rebirth
  samt att återansluta med fungerande sparning. v1.4-systemen ska fungera vidare.

Tvåspelartest: stoppa Play och använd **Server & Clients / Local Server** med
två spelare. Åtta baser finns. Sex plattformar är tillgängliga från början,
sju efter första rebirth och åtta efter andra.

## Sparning och källkod

Spelet använder v1.4:s DataStore-system och samma datalagringsnamn. I Studio
krävs en publicerad upplevelse och **Game Settings → Security → Enable Studio
Access to API Services** för att testa verklig sparning. Om DataStore inte går
att nå visar spelet ett meddelande och framstegen blir tillfälliga för besöket.

[Regler, referens och tekniska detaljer](STAGE_GUARDIANS_V15.md) ·
[Redigerbar källkod](../downloads/Catch-the-scrap-v1.5-source.zip)

Bilden på robotarna är en Blender-rendering, inte en Studio-skärmbild. Molnets
automatiska kontroller ersätter inte riktig testning av Roblox-gång, ljus,
streaming, sparning eller mobilprestanda.

Vid fel: skicka **första röda feltexten i Output** och vad du gjorde före felet.
Normal start skriver `[Catch the Scrap] Scrapyard ready. Stage Guardians v1.5`.

För kodsynk: Rojo 7.7.1 och motsvarande Studio-plugin lokalt på Windows.
Packa upp källkods-ZIP:en och kör i projektmappen:

```powershell
& 'C:\Tools\Rojo\rojo.exe' serve default.project.json
```

Stoppa Play och anslut pluginet till localhost:34872 i en kopia av platsen.
Molnets localhost är en annan dator än Windows-datorn. Automatiska kontroller:
`python scripts/check.py` med Python 3, Rojo 7.7.1 och Luau 0.744 i PATH.
