local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local enabled = false
local skeletons = {} -- [Player] = {gui, lines, hpBG, hpBar, box, nameLabel}

-- bones for skeleton correctly work (HumanoidRig)
local bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"UpperTorso", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"RightLowerArm", "RightHand"},
}

-- create a line or (UI Frame)
local function makeLine(parent)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
    line.Size = UDim2.new(0, 0, 0, 2)
    line.Visible = false
    line.Parent = parent
    return line
end

-- create HP bar
local function makeHPBar(parent)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 60, 0, 6)
    bg.AnchorPoint = Vector2.new(0.5, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BorderSizePixel = 0
    bg.Visible = false
    bg.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.Parent = bg

    return bg, bar
end

-- create Box
local function makeBox(parent)
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = Color3.fromRGB(255, 255, 0)
    box.Size = UDim2.new(0, 0, 0, 0)
    box.Visible = false
    box.Parent = parent
    return box
end

-- create Name label
local function makeName(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 14
    lbl.Text = text
    lbl.Visible = false
    lbl.Parent = parent
    return lbl
end

-- create ESP for anyone player
local function createSkeleton(plr)
    if plr == LocalPlayer or skeletons[plr] then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local sg = Instance.new("ScreenGui")
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,1,0)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    local lines = {}
    for _,_ in ipairs(bones) do
        table.insert(lines, makeLine(holder))
    end

    local hpBG, hpBar = makeHPBar(holder)
    local box = makeBox(holder)
    local nameLabel = makeName(holder, plr.Name)

    skeletons[plr] = {gui = sg, lines = lines, hpBG = hpBG, hpBar = hpBar, box = box, nameLabel = nameLabel}
end

-- delete ESP
local function removeSkeleton(plr)
    if skeletons[plr] then
        skeletons[plr].gui:Destroy()
        skeletons[plr] = nil
    end
end

-- update animations
RunService.RenderStepped:Connect(function()
    if not enabled then return end
    for plr, data in pairs(skeletons) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum and hum.Health > 0) then
            data.gui.Enabled = false
        else
            data.gui.Enabled = true

            -- skeleton
            for i, pair in ipairs(bones) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local line = data.lines[i]
                if p1 and p2 then
                    local v1, ons1 = Camera:WorldToViewportPoint(p1.Position)
                    local v2, ons2 = Camera:WorldToViewportPoint(p2.Position)
                    if ons1 and ons2 then
                        line.Visible = true
                        local mid = (Vector2.new(v1.X, v1.Y) + Vector2.new(v2.X, v2.Y)) / 2
                        local dist = (Vector2.new(v1.X, v1.Y) - Vector2.new(v2.X, v2.Y)).Magnitude
                        line.Size = UDim2.new(0, dist, 0, 2)
                        line.Position = UDim2.new(0, mid.X, 0, mid.Y)
                        line.Rotation = math.deg(math.atan2(v2.Y - v1.Y, v2.X - v1.X))
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end

            -- HP bar
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local v, ons = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4, 0))
                if ons then
                    data.hpBG.Visible = true
                    data.hpBG.Position = UDim2.new(0, v.X, 0, v.Y)
                    data.hpBar.Size = UDim2.new(math.clamp(hum.Health/hum.MaxHealth,0,1), 0, 1, 0)
                    data.hpBar.BackgroundColor3 = Color3.fromRGB(255 - hum.Health*2, hum.Health*2, 0)
                else
                    data.hpBG.Visible = false
                end
            end

            -- BOX
            local head = char:FindFirstChild("Head")
            local leg = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot")
            if head and leg then
                local top, on1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                local bottom, on2 = Camera:WorldToViewportPoint(leg.Position - Vector3.new(0,0.5,0))
                if on1 and on2 then
                    data.box.Visible = true
                    local height = (bottom.Y - top.Y)
                    local width = height / 2
                    data.box.Size = UDim2.new(0, width, 0, height)
                    data.box.Position = UDim2.new(0, top.X, 0, top.Y + height/2)

                    -- никнейм под боксом
                    data.nameLabel.Visible = true
                    data.nameLabel.Text = plr.Name
                    data.nameLabel.Position = UDim2.new(0, top.X, 0, bottom.Y + 15)
                    data.nameLabel.Size = UDim2.new(0, 200, 0, 20)
                else
                    data.box.Visible = false
                    data.nameLabel.Visible = false
                end
            else
                data.box.Visible = false
                data.nameLabel.Visible = false
            end
        end
    end
end)

-- update players
local function refresh()
    for _, plr in ipairs(Players:GetPlayers()) do
        if enabled then
            createSkeleton(plr)
        else
            removeSkeleton(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if enabled then createSkeleton(plr) end
    end)
end)
Players.PlayerRemoving:Connect(removeSkeleton)

-- Toggle key (G)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.G then
        enabled = not enabled
        refresh()
    end
end)
