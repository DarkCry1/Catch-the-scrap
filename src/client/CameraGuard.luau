--!nonstrict
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("CatchTheScrapShared")
local Config=require(Shared.Config)
local Bounds=require(Shared.CameraBounds)
local CameraGuard={}
function CameraGuard.start(player)
    player.CameraMaxZoomDistance=Config.Camera.MaxZoom
    player.CameraMinZoomDistance=.5
    -- Run after the normal camera: mouse, touch, gamepad and first-person still work.
    RunService:BindToRenderStep("ScrapyardCameraGuard",Enum.RenderPriority.Camera.Value+1,function()
        local camera=workspace.CurrentCamera
        if not camera or camera.CameraType==Enum.CameraType.Scriptable then return end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local desired=camera.CFrame.Position
        local focus=camera.Focus.Position
        -- The camera's near-plane corners need space too, especially on wide screens.
        local aspect=camera.ViewportSize.X/math.max(camera.ViewportSize.Y,1)
        local near=math.abs(camera.NearPlaneZ)
        local halfHeight=math.tan(math.rad(camera.FieldOfView/2))*near
        local padding=math.max(Config.Camera.EdgeInset,math.sqrt(halfHeight^2*(1+aspect^2))+Config.Camera.NearPlanePadding)
        local point=Bounds.limit({x=focus.X,y=focus.Y,z=focus.Z},{x=desired.X,y=desired.Y,z=desired.Z},padding)
        local position=Vector3.new(point.x,point.y,point.z)
        if (position-desired).Magnitude>.001 then
            camera.CFrame=CFrame.new(position)*camera.CFrame.Rotation
        end
    end)
end
return CameraGuard
