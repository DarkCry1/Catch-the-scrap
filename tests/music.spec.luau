--!strict
local Rules=require("../src/shared/MusicRules")
local Config=require("../src/shared/Config")
local n=0
local function check(ok:boolean,message:string)n+=1;assert(ok,message)end
for _,v in {"", "rbxassetid://0", "123oops", "https://example.com/music.mp3", "rbxasset://sounds/swoosh.wav", "data:audio/wav;base64,AAAA", "-123", "0", " 123 "} do
    check(Rules.assetId(v)==nil,"invalid or unsupported content IDs do not start a sound")
end
check(Rules.assetId("12345")=="rbxassetid://12345","numeric asset ID normalized")
check(Rules.assetId("rbxassetid://12345")=="rbxassetid://12345","uploaded asset ID accepted")
check(Rules.assetId(12345)==nil and Rules.assetId(false)==nil,"unexpected types rejected")
check(Config.Music.SoundId=="","no unverified third-party music ID shipped")
local s=Config.Music
check(Rules.volume(s,false,false,false)==s.Volume,"idle background level")
check(Rules.volume(s,true,false,false)<s.Volume,"chase warnings have space")
check(Rules.volume(s,false,true,false)<s.Volume,"cinematics have space")
check(Rules.volume(s,true,true,false)==s.Volume*math.min(s.DuckChase,s.DuckCinematic),"ducking flags use the stronger reduction")
for _,chased in {true,false} do for _,cinematic in {true,false} do check(Rules.volume(s,chased,cinematic,true)==0,"mute always wins")end end
print("Background music ID validation/mix rules passed "..n.." assertions")
