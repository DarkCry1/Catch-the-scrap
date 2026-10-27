--!nonstrict
local CollectionService=game:GetService("CollectionService")
local Config=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.Config)
local Blueprint=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.CrateBlueprint)
local Decor=require(script.Parent.RarityDecor)
local Builder={}
function Builder.display(parent,origin,startedAt,rarity)
    local model=Instance.new("Model");model.Name="UnboxingRobotBox"
    model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("Rarity",rarity);model:SetAttribute("StartedAt",startedAt);model:SetAttribute("Origin",origin)
    for _,d in Blueprint.build() do
        local part=Instance.new("Part");part.Name=d.name;part.Size=Vector3.new(unpack(d.size))
        part.CFrame=origin*CFrame.new(unpack(d.position));part.Color=Color3.fromRGB(unpack(if d.name=="TopTape" or d.name=="PackingTape" then Config.Robot.Recipes[rarity].Color else d.color));part.Material=Enum.Material[d.material]
        part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Parent=model
    end
    Decor.frame(model,origin,rarity,nil)
    model:SetAttribute("OwnerUserId",parent.Parent:GetAttribute("OwnerUserId"))
    model.WorldPivot=origin;model.Parent=parent
    CollectionService:AddTag(model,"OpeningRobotBox")
    return model
end
return Builder
