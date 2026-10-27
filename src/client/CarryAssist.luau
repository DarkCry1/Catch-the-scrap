--!nonstrict
-- Observe the actual hands, not just whether IK objects were successfully created.
local RunService=game:GetService("RunService")
local Assist={}
function Assist.start(player,remote)
    local elapsed,waiting,attempted=0,0,nil
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<.25 then return end
        local step=elapsed;elapsed=0
        if player:GetAttribute("CarryMode")~="Two-hand IK" or (player:GetAttribute("CarryStyle") or "Auto")~="Auto" then waiting=0;return end
        local world=workspace:FindFirstChild("CatchTheScrapWorld")
        local items=world and world:FindFirstChild("Items")
        local character=player.Character
        if not items or not character then return end
        for _,model in items:GetChildren() do
            if model:GetAttribute("CarrierUserId")~=player.UserId then continue end
            local id=model:GetAttribute("ItemId")
            if attempted==id then return end
            local root=model:FindFirstChild("CarryRoot")
            local bad=false
            for _,side in {"Left","Right"} do
                local target=root and root:FindFirstChild(side.."CargoGrip")
                local hand=character:FindFirstChild(side.."Hand")
                if not target or not hand or (target.WorldPosition-hand.Position).Magnitude>1.5 then bad=true end
            end
            if bad then waiting+=step else waiting=0 end
            if waiting>=2 then attempted=id;waiting=0;remote:FireServer("SetCarryStyle","Handheld") end
            return
        end
    end)
end
return Assist
