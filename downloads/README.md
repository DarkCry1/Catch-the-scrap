# Hämta första prototypen

1. Öppna [Catch-the-scrap.rbxl](Catch-the-scrap.rbxl) på GitHub.
2. Klicka på **Download raw file** (nedåtpilen) uppe till höger vid filen.
3. Spara filen på din Windows-dator. Om webbläsaren lägger till en extra ändelse, behåll filnamnet `Catch-the-scrap.rbxl`.
4. Öppna Roblox Studio och välj **File → Open from File…** eller **Ctrl+O**.
5. Öppna filen och tryck **Play / F5**. Kartan skapas när Play startar.

**WASD**: gå. **Håll E** nära ett fynd: plocka upp. **Q**: släpp. **Håll E** vid din egen orange basplatta: lämna in.

Se [hela Windows-guiden](../docs/STUDIO_START_SV.md) för testlista och felsökning.

Platsfilen är ett exporterat prototypbygge från källkoden på denna gren. Automatiska logiktester och bygget passerar; spelet ska fortfarande testas i Roblox Studio. Vid senare kodändringar skapar `python3 scripts/check.py` nya filer i `build/`; filen i denna mapp uppdateras separat när ett nytt nedladdningsbart bygge ska delas.
