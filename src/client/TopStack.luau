--!nonstrict
-- One shared stack for top-of-screen notifications (event banners, Robotdex
-- discoveries, drone warnings). Visible cards are laid out top-down in the
-- order they appeared and glide into place, so they never overlap.
local TweenService=game:GetService("TweenService")
local Stack={entries={},serial=0}
Stack.Top=34
Stack.Gap=10
Stack.Tween=TweenInfo.new(.38,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)

local function reflow()
    local active={}
    for _,entry in Stack.entries do if entry.active and entry.frame.Parent then table.insert(active,entry) end end
    table.sort(active,function(a,b) return a.seq<b.seq end)
    local y=Stack.Top
    for _,entry in active do
        local target=UDim2.new(.5,0,0,y)
        if entry.target~=target then
            entry.target=target
            if entry.fresh then
                -- New cards drop in from just above their slot.
                entry.frame.Position=UDim2.new(.5,0,0,y-entry.height-20);entry.fresh=false
            end
            TweenService:Create(entry.frame,Stack.Tween,{Position=target}):Play()
        end
        y+=entry.height+Stack.Gap
    end
    for _,entry in Stack.entries do
        if not entry.active and entry.target~=entry.hidden then
            entry.target=entry.hidden
            TweenService:Create(entry.frame,Stack.Tween,{Position=entry.hidden}):Play()
        end
    end
end

-- frame must use AnchorPoint (.5, 0). height is its pixel height.
function Stack.add(frame,height)
    local entry={frame=frame,height=height,active=false,seq=0,hidden=UDim2.new(.5,0,0,-height-40)}
    frame.AnchorPoint=Vector2.new(.5,0);frame.Position=entry.hidden;entry.target=entry.hidden
    table.insert(Stack.entries,entry)
    return entry
end
function Stack.show(entry)
    -- A card that is already showing keeps its slot when its text updates.
    if not entry.active then Stack.serial+=1;entry.fresh=true;entry.seq=Stack.serial end
    entry.active=true
    reflow()
end
function Stack.hide(entry)
    if not entry.active then return end
    entry.active=false
    reflow()
end
Stack.reflow=reflow
return Stack
