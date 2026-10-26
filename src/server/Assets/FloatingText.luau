--!nonstrict
local FloatingText = {}

function FloatingText.create(parent, name, cframe, value, color, width, height, distance)
    local anchor = Instance.new("Part")
    anchor.Name = name
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.CFrame = cframe
    anchor.Anchored = true
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Parent = parent
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromScale(width, height)
    gui.MaxDistance = distance or 110
    gui.AlwaysOnTop = false
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.fromRGB(12, 18, 24)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.AutoLocalize = false
    label.Parent = gui
    return label
end

return FloatingText
