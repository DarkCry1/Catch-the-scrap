# Verkstäder och robotar – designunderlag

## Granskade kodreferenser

Två öppna Roblox-tycoon-projekt har granskats via GitHub. De används som underlag för vanliga spelmönster. Ingen av deras kod, modeller eller texturer ingår i det här bygget.

- [Tycoon Creator](https://github.com/ivadsiulsgames/tycooncreator/tree/4dc8ca7a9bd073da5c774097643060cac57b58ae): `CashGuiServiceClient.lua`, `Dropper.lua` och `SellPart.lua`. Visar separat penga-HUD, produktion med ägare och intervall, samt insamling som kopplas till rätt spelare. Vårt bygge visar både saldo och inkomsttakt och låter färdiga robotar producera direkt utan en mängd fysiska pengadelar.
- [Roblox Studio Tycoon-serien](https://github.com/B-Ricey763/Roblox-Studio-Tycoon/tree/b09783d092420a81665193a4b6649c7e4d5f60e0): `Video 13/Tycoon.lua` och `Video 6/Components/Bank.lua`/`Collector.lua`. Visar spelarägda tycoon-instansers spawn, upptagna platser, insamlingsstation och ägarkontroll. Vårt bygge använder namngivna verkstäder, en tydlig inlämningsmaskin och serverkontrollerad ekonomi.

Detta är kodgranskning, inte speltest eller visuell granskning av deras färdiga baser.

## Referenser som inte kunde granskas

Officiella sidor för **Steal a Brainrot** och **Grow a Garden** försöktes hämtas, men miljöns proxy nekade anslutningen till `www.roblox.com` med HTTP 403. Inga skärmbilder eller modeller från dessa spel har hämtats eller använts. Roblox-webbåtkomst har sparats som ett konfigurationsutkast; sparandet aktiverar inte åtkomsten i sig.

## Egen visuell riktning

- En återvinningsverkstad med öppen front, rejäla portstolpar, metallgolv och ett bakre tak som lämnar större delen av kameravyn öppen.
- Mörk stålpalett med varm orange maskinkant och olika accentfärger mellan baserna.
- En central gata, numrerade portar och ägarnamn som gör hemvägen begriplig.
- Fyra tydliga robotplattformar, en inlämningsmaskin och progressmätare.
- Robotarna byggs synligt i fem monteringsgrupper: ben/fötter, kropp, båda armarna, huvud och reaktor/slutdetaljer.
- Framtida delar visas som en genomskinlig ritning. Färdiga robotar har en pulserande reaktor och en skylt med sin inkomst.

All geometri skapas från egna primitiva Roblox-delar i `BaseBlueprint.luau` och `RobotBlueprint.luau`. Det finns inga externa asset-ID:n eller Toolbox-modeller.

![Modellförhandsvisning av skrotgården](../downloads/scrapyard-preview.png)

Bilden är en Blender-rendering av skrotgårdens grundgeometri från samma blueprint som spelet använder. Den är **inte en skärmbild från Roblox Studio**. Ljus, material, text och kamera kan se annorlunda ut i spelet.

## Uppdatering v0.3

Spelets egna texter är på engelska. Common kräver 5 Common-delar, Uncommon 7 och Rare 10. Robotarnas fem monteringsgrupper är ben/fötter, kropp, armar, huvud och reaktor/slutdetaljer. Skrotgården är 160 × 1 440 studs och har containrar, vrak, däck- och rörhögar, skrotrobotar och traverskranar. Skylttexterna har inga synliga bakgrundspaneler. Inga ytterligare externa spelbilder har granskats som del av denna ändring.

## Uppdatering v0.4

Milo är en egen mekanikerrobot med skyddsglasögon och skiftnyckel bakom en liten uppgraderingsdisk. Standens geometri är egen och delar robotens befintliga grundmodell i mindre skala. Inga externa modeller eller nya spelreferenser användes. Spelets köpmeny, priser, erbjudanden och meddelanden är på engelska.

## Uppdatering v0.5

Skrotgården har fått en egen sammanhängande industrimiljö med skrotklädda ytterväggar och infart, plåtlager och förstärkningar, silor, lagade verkstäder och detaljerade kugghjul, motorer och kärnor. All geometri är fortsatt egen. Spelet använder Roblox inbyggda material och paketerade partikeltexturer. [Den visuella genomgången](VISUAL_PASS_V05.md) visar modellrenderingar och beskriver vilka verkliga Studio-tester som återstår. Inga nya externa spelbilder eller modeller importerades.


## Uppdatering v0.6

Epic, Legendary, Mythic och Celestial följer etablerat rarity-språk från loot-/simulatorspel. De nya områdesnamnen Turbine Foundry, Golden Furnace, Void Salvage och Starforge Ruins är egna och anpassade till skrotgårdens tema. Geometri, modeller och animationer är byggda i projektet. Inga nya externa spel har speltestats eller visuellt granskats i molnet för denna uppdatering.


## Uppdatering v0.7

Bärposen är procedurbyggd för R6/R15. Kvarn, sågblad och kartonger är egen geometri; tejp, fraktetikett och robotstämpel består av vanliga delar. Unboxing sker efter hemleverans på en ledig robotplattform. Inga Toolbox-modeller eller uppladdade animationer används. Gnistor använder Roblox medföljande partikeltextur. Modellbilderna är från Blender, inte från Roblox Studio.


## Uppdatering v0.8

De sex robotvarianterna är byggda av projektets egen geometri: Iron Bastion, Volt Runner, Drillmaster, Magnetron, Orbital Warden och Sunforge Sentinel. Ingen ny extern modell eller animation har kopierats. Rare-boxar är nu tidsstyrda serverevent med garanterad annonserad rarity. Bärposen har bytt till C0-styrning efter användarens Studio-bild som visade att v0.7:s Transform-metod inte lyfte armarna.
