--!nonstrict
local RunService=game:GetService("RunService")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local Prompts=game:GetService("ProximityPromptService")
local Lighting=game:GetService("Lighting")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Style=require(Shared.RarityStyle)
local Bounds=require(Shared.CameraBounds)
local Director={}
local active=nil
local skipGui=nil
local function stop()
    local state=active;if not state then return end;active=nil
    RunService:UnbindFromRenderStep("RobotOpeningCamera")
    ContextActionService:UnbindAction("SkipRobotOpening")
    if state.camera.Parent then state.camera.CameraType=state.type;state.camera.CameraSubject=state.subject;state.camera.FieldOfView=state.fov end
    if state.dof then state.dof:Destroy() end
    if skipGui then skipGui.Enabled=false end
    Prompts.Enabled=state.promptEnabled
    local hud=state.player.PlayerGui:FindFirstChild("CatchTheScrapHUD")
    if hud and state.hudEnabled~=nil then hud.Enabled=state.hudEnabled end
end
function Director.play(player,origin,rarity,startedAt,ownerId,ignoreModel)
    local profile=Style.get(rarity)
    if ownerId~=player.UserId or profile.Rank<4 or active then return end
    local camera=workspace.CurrentCamera
    local now=workspace:GetServerTimeNow()
    if not camera or camera.CameraType==Enum.CameraType.Scriptable or now-startedAt>profile.Duration then return end
    if not skipGui then
        skipGui=Instance.new("ScreenGui");skipGui.Name="OpeningCameraControls";skipGui.ResetOnSpawn=false;skipGui.DisplayOrder=35;skipGui.Parent=player.PlayerGui
        local button=Instance.new("TextButton");button.AnchorPoint=Vector2.new(.5,1);button.Position=UDim2.new(.5,0,1,-28);button.Size=UDim2.fromOffset(230,40)
        button.BackgroundColor3=Color3.fromRGB(18,29,40);button.TextColor3=Color3.new(1,1,1);button.Text=if UserInputService.KeyboardEnabled then "SKIP CAMERA [SPACE]" else "SKIP CAMERA";button.Font=Enum.Font.GothamBold;button.TextSize=13;button.AutoLocalize=false;button.Parent=skipGui
        local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=button;button.Activated:Connect(stop)
    end
    skipGui.Enabled=true
    local hud=player.PlayerGui:FindFirstChild("CatchTheScrapHUD")
    local dof=Instance.new("DepthOfFieldEffect");dof.Name="RobotOpeningFocus";dof.InFocusRadius=9;dof.FarIntensity=.16;dof.NearIntensity=.08;dof.Parent=Lighting
    active={camera=camera,type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,player=player,dof=dof,hudEnabled=if hud then hud.Enabled else nil,promptEnabled=Prompts.Enabled}
    if hud then hud.Enabled=false end
    Prompts.Enabled=false
    camera.CameraType=Enum.CameraType.Scriptable
    ContextActionService:BindAction("SkipRobotOpening",function(_,state)
        if state==Enum.UserInputState.Begin then stop() end;return Enum.ContextActionResult.Sink
    end,false,Enum.KeyCode.Space,Enum.KeyCode.ButtonB)
    RunService:BindToRenderStep("RobotOpeningCamera",Enum.RenderPriority.Camera.Value+2,function()
        if not active then return end
        local age=workspace:GetServerTimeNow()-startedAt
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 or workspace.CurrentCamera~=camera or age>profile.Duration+1.5 or (root.Position-origin.Position).Magnitude>45 then stop();return end
        local p=math.clamp(age/profile.Duration,0,1)
        local sweep=math.sin(p*math.pi)*6-3
        local localPosition=Vector3.new(sweep,5.1,if p<.7 then 11-p*3 else 10+(p-.7)*3)
        local focus=origin.Position+Vector3.new(0,1.4,0)
        local desired=origin:PointToWorldSpace(localPosition)
        local safe=Bounds.limit({x=focus.X,y=focus.Y,z=focus.Z},{x=desired.X,y=desired.Y,z=desired.Z},2)
        desired=Vector3.new(safe.x,safe.y,safe.z)
        local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={player.Character,ignoreModel}
        local hit=workspace:Raycast(focus,desired-focus,ray)
        if hit then desired=hit.Position+hit.Normal*1.2 end
        camera.CFrame=CFrame.lookAt(desired,focus)
        camera.FieldOfView=58-math.sin(p*math.pi)*10
        dof.FocusDistance=(desired-focus).Magnitude
    end)
end
return Director
