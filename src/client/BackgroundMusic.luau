--!nonstrict
-- Plays the original uploaded loop. Roblox requires an audio asset granted to
-- the experience; a local WAV/MP3 cannot be embedded as a playable SoundId.
local SoundService=game:GetService("SoundService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Rules=require(Shared.MusicRules)
local Audio=require(script.Parent.Audio)
local Music={}
function Music.start(player)
    if Music.controller then return Music.controller end
    if not Config.Music.Enabled then return end
    Audio.start()
    local template=SoundService:FindFirstChild("ScrapyardMusic")
    if not template or not template:IsA("Sound") then
        template=Instance.new("Sound");template.Name="ScrapyardMusic";template.Parent=SoundService
    end
    local state={connections={},generation=0,dead=false,paused=false,started=false,ready=false,elapsed=0}
    Music.controller=state
    local function cancelTween()
        if state.tween then state.tween:Cancel();state.tween=nil end
    end
    local function removeSound()
        cancelTween()
        if state.loadedConnection then state.loadedConnection:Disconnect();state.loadedConnection=nil end
        if state.sound then state.sound:Stop();state.sound:Destroy();state.sound=nil end
        state.ready=false;state.started=false;state.paused=false;state.target=nil
    end
    local function targetVolume()
        local camera=workspace.CurrentCamera
        return Rules.volume(Config.Music,player:GetAttribute("GuardChase")==true or player:GetAttribute("DroneChase")==true,camera and camera.CameraType==Enum.CameraType.Scriptable or false,Audio.muted)
    end
    local function refresh(seconds)
        local sound=state.sound
        if state.dead or not sound or not state.ready then return end
        if Audio.muted then
            cancelTween();sound.Volume=0;state.target=0
            if state.started and not state.paused then sound:Pause();state.paused=true end
            return
        end
        if state.paused then sound:Resume();state.paused=false
        elseif not state.started then sound:Play();state.started=true end
        local volume=targetVolume()
        if state.target==volume then return end
        state.target=volume;cancelTween()
        state.tween=TweenService:Create(sound,TweenInfo.new(seconds or Config.Music.FadeSeconds,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Volume=volume})
        state.tween:Play()
    end
    local function load()
        state.generation+=1;local generation=state.generation
        removeSound()
        local id=Rules.assetId(if Config.Music.SoundId~="" then Config.Music.SoundId else template.SoundId)
        if not id then
            warn("[Catch the Scrap] Background music awaits its uploaded audio ID. Set SoundService.ScrapyardMusic.SoundId; see docs/BACKGROUND_MUSIC_SV.md.")
            return
        end
        local sound=Instance.new("Sound");sound.Name="LocalScrapyardMusic";sound.SoundId=id;sound.Looped=true;sound.Volume=0;sound.PlaybackSpeed=1;sound.SoundGroup=Audio.musicGroup;sound.Parent=Audio.master
        state.sound=sound
        local function loaded()
            if state.dead or state.generation~=generation or state.ready then return end
            state.ready=true;refresh(Config.Music.FadeInSeconds)
        end
        state.loadedConnection=sound.Loaded:Connect(loaded)
        if sound.IsLoaded then loaded() end
        task.spawn(function()
            local failed=false
            local ok=pcall(function()
                ContentProvider:PreloadAsync({sound},function(_,status) if status~=Enum.AssetFetchStatus.Success then failed=true end end)
            end)
            if state.dead or state.generation~=generation then return end
            if sound.IsLoaded then loaded()
            elseif not ok or failed then
                warn("[Catch the Scrap] Background music could not load. Check that the audio is approved and granted to this experience: "..id)
            end
        end)
    end
    table.insert(state.connections,template:GetPropertyChangedSignal("SoundId"):Connect(load))
    table.insert(state.connections,Audio.master:GetPropertyChangedSignal("Volume"):Connect(function() refresh() end))
    table.insert(state.connections,player:GetAttributeChangedSignal("GuardChase"):Connect(function() refresh() end))
    table.insert(state.connections,player:GetAttributeChangedSignal("DroneChase"):Connect(function() refresh() end))
    table.insert(state.connections,RunService.Heartbeat:Connect(function(dt)
        state.elapsed+=dt;if state.elapsed<.2 then return end;state.elapsed=0;refresh()
    end))
    function state:destroy()
        if self.dead then return end;self.dead=true;self.generation+=1
        for _,connection in self.connections do connection:Disconnect() end
        removeSound();Music.controller=nil
    end
    load()
    return state
end
return Music
