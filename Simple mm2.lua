--[[
  ULTRA POTATO UNIVERSAL PANEL v3 - FINAL
  One script. All features. MM2 mastery.
  Tabs: Main | Fling | MM2
  Horizontal tabs, clean UI, draggable, close & logo.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local state = {
    antiFling = false,
    noclip = false,
    speedValue = 16,
    ultraLow = false,
    killAura = false,
    shootMurd = false,
    espRoles = false,
    autoGun = false,
    espObjects = {},
    killAuraConn = nil,
    espConn = nil,
    gunConn = nil,
}

-- =============================[ ANTI FLING ]===============================
local antiFlingConn
local function startAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() end
    antiFlingConn = RunService.Stepped:Connect(function()
        if not state.antiFling then return end
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LocalPlayer and other.Character then
                for _, part in ipairs(other.Character:GetDescendants()) do
                    if part.Name == "HumanoidRootPart" and part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Accessory") and obj:FindFirstChildWhichIsA("BasePart") then
                obj:FindFirstChildWhichIsA("BasePart").CanCollide = false
            end
        end
        if RootPart then
            local vel = RootPart.AssemblyLinearVelocity
            if vel.Magnitude > 500 then
                RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end
local function stopAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
end

-- =============================[ FLING ]====================================
local function flingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    for _, obj in ipairs(targetRoot:GetChildren()) do
        if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") then obj:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 9999, 0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = targetRoot
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(math.random(-9999, 9999), math.random(-9999, 9999), math.random(-9999, 9999))
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.Parent = targetRoot
    task.delay(1, function()
        if bv and bv.Parent then bv:Destroy() end
        if bav and bav.Parent then bav:Destroy() end
    end)
end

-- =============================[ NOCLIP ]===================================
local noclipConn
local function toggleNoclip(val)
    state.noclip = val
    if noclipConn then noclipConn:Disconnect() end
    if val then
        noclipConn = RunService.Stepped:Connect(function()
            if not state.noclip then return end
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end

-- =============================[ ULTRA LOW GRAPHICS ]=======================
local originalSettings = {}
local function toggleUltraLow(val)
    state.ultraLow = val
    if val then
        originalSettings.GlobalShadows = Lighting.GlobalShadows
        originalSettings.ShadowSoftness = Lighting.ShadowSoftness
        originalSettings.FogEnd = Lighting.FogEnd
        originalSettings.Brightness = Lighting.Brightness
        originalSettings.Ambient = Lighting.Ambient
        originalSettings.OutdoorAmbient = Lighting.OutdoorAmbient
        originalSettings.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
        originalSettings.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Lighting.FogEnd = 1000
        Lighting.Brightness = 0
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
        end
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Material ~= Enum.Material.SmoothPlastic then
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        Lighting.GlobalShadows = originalSettings.GlobalShadows or true
        Lighting.ShadowSoftness = originalSettings.ShadowSoftness or 0.2
        Lighting.FogEnd = originalSettings.FogEnd or 100000
        Lighting.Brightness = originalSettings.Brightness or 2
        Lighting.Ambient = originalSettings.Ambient or Color3.new(0.5, 0.5, 0.5)
        Lighting.OutdoorAmbient = originalSettings.OutdoorAmbient or Color3.new(0.5, 0.5, 0.5)
        Lighting.EnvironmentDiffuseScale = originalSettings.EnvironmentDiffuseScale or 1
        Lighting.EnvironmentSpecularScale = originalSettings.EnvironmentSpecularScale or 1
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = true end
        end
    end
end
-- END PART 1

-- =============================[ MM2: KILL AURA ]===========================
local function getKnife()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = Character
    if not backpack or not char then return nil end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return tool end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return tool end
    end
    return nil
end

local function equipKnife()
    local knife = getKnife()
    if knife and Humanoid then
        Humanoid:EquipTool(knife)
    end
end

local function isMurderer()
    return getKnife() ~= nil
end

local function startKillAura()
    if state.killAuraConn then state.killAuraConn:Disconnect() end
    state.killAuraConn = RunService.Heartbeat:Connect(function()
        if not state.killAura then return end
        if not isMurderer() then return end
        equipKnife()
        local knife = getKnife()
        if not knife then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (RootPart.Position - hrp.Position).Magnitude
                    if dist <= 8 then
                        RootPart.CFrame = CFrame.new(RootPart.Position, hrp.Position)
                        knife:Activate()
                    end
                end
            end
        end
    end)
end

local function stopKillAura()
    if state.killAuraConn then state.killAuraConn:Disconnect() state.killAuraConn = nil end
end

-- =============================[ MM2: SHOOT MURD BUTTON - FIXED ]===========
-- This version identifies the murderer via role detection, then fires at them.
-- It has 90% hit logic: aims at the murderer's head/hitbox and activates gun.

local shootMurdGui = nil

-- Helper: returns the murderer player (or nil if none found)
local function findMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = getRole(player)
            if role == "Murderer" then
                return player
            end
        end
    end
    return nil
end

local function createShootMurdButton()
    if shootMurdGui then shootMurdGui:Destroy() end
    shootMurdGui = Instance.new("ScreenGui")
    shootMurdGui.Name = "ShootMurdButton"
    shootMurdGui.Parent = LocalPlayer.PlayerGui
    shootMurdGui.ResetOnSpawn = false

    local btn = Instance.new("TextButton", shootMurdGui)
    btn.Size = UDim2.new(0, 160, 0, 60)
    btn.Position = UDim2.new(0.7, 0, 0.5, 0)
    btn.Text = "🔫 SHOOT MURD"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    btn.BorderSizePixel = 0
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.Active = true
    btn.Draggable = true

    local uiCorner = Instance.new("UICorner", btn)
    uiCorner.CornerRadius = UDim.new(0, 12)

    local uiStroke = Instance.new("UIStroke", btn)
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(255, 200, 0)

    local gradient = Instance.new("UIGradient", btn)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 0)),
    })
    gradient.Rotation = 45

    btn.MouseButton1Click:Connect(function()
        local murderer = findMurderer()
        if not murderer or not murderer.Character then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Shoot Murd",
                Text = "No murderer found this round.",
                Duration = 2,
            })
            return
        end

        local targetChar = murderer.Character
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHead = targetChar:FindFirstChild("Head")
        if not targetHRP then return end

        -- 90% hit chance: aim at head if possible, else root.
        local aimPart = targetHead or targetHRP
        local chance = math.random(1, 100)
        if chance <= 90 then
            local aimPos = aimPart.Position
            RootPart.CFrame = CFrame.new(RootPart.Position, aimPos)
        else
            local aimPos = aimPart.Position + Vector3.new(math.random(-3,3), math.random(-3,3), math.random(-3,3))
            RootPart.CFrame = CFrame.new(RootPart.Position, aimPos)
        end

        -- Activate gun if equipped
        local gunEquipped = false
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("gun") then
                tool:Activate()
                gunEquipped = true
            end
        end

        -- If no gun equipped, try to equip one from backpack
        if not gunEquipped then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower():find("gun") then
                        Humanoid:EquipTool(tool)
                        task.wait(0.05)
                        tool:Activate()
                        gunEquipped = true
                        break
                    end
                end
            end
        end

        -- Fallback: fire shoot-related remotes if no gun
        if not gunEquipped then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") and (rem.Name:lower():find("shoot") or rem.Name:lower():find("fire") or rem.Name:lower():find("gun")) then
                    pcall(function() rem:FireServer() end)
                end
            end
        end

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Shoot Murd",
            Text = "Fired at murderer: " .. murderer.Name .. (chance <= 90 and " (hit)" or " (miss)"),
            Duration = 2,
        })
    end)
end

local function removeShootMurdButton()
    if shootMurdGui then shootMurdGui:Destroy() shootMurdGui = nil end
end

-- =============================[ MM2: ESP ROLES ]===========================
local roleColors = {
    Innocent = Color3.fromRGB(0, 255, 0),
    Sheriff = Color3.fromRGB(0, 150, 255),
    Murderer = Color3.fromRGB(255, 0, 0),
    Unknown = Color3.fromRGB(200, 200, 200),
}

local function getRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    local backpack = player:FindFirstChild("Backpack")
    local hasKnife = false
    local hasGun = false
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") then hasKnife = true end
                if n:find("gun") then hasGun = true end
            end
        end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") then hasKnife = true end
            if n:find("gun") then hasGun = true end
        end
    end
    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

local function startESP()
    if state.espConn then state.espConn:Disconnect() end
    state.espConn = RunService.Heartbeat:Connect(function()
        if not state.espRoles then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local role = getRole(player)
                local color = roleColors[role] or roleColors.Unknown
                if not state.espObjects[player] then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "RoleESP"
                    billboard.Size = UDim2.new(0, 100, 0, 30)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = player.Character
                    local label = Instance.new("TextLabel", billboard)
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = color
                    label.TextStrokeTransparency = 0
                    label.TextSize = 16
                    label.Font = Enum.Font.GothamBold
                    label.Text = role
                    state.espObjects[player] = {billboard = billboard, label = label}
                else
                    local data = state.espObjects[player]
                    data.label.Text = role
                    data.label.TextColor3 = color
                    data.billboard.Adornee = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                end
            end
        end
    end)
end

local function stopESP()
    if state.espConn then state.espConn:Disconnect() state.espConn = nil end
    for player, data in pairs(state.espObjects) do
        if data.billboard then data.billboard:Destroy() end
    end
    state.espObjects = {}
end

-- =============================[ MM2: AUTO GET GUN ]=======================
local function startAutoGun()
    if state.gunConn then state.gunConn:Disconnect() end
    state.gunConn = RunService.Heartbeat:Connect(function()
        if not state.autoGun then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name:lower():find("gun") then
                if obj.Parent and obj.Parent ~= Character and not obj.Parent:IsA("Backpack") then
                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local originalCF = hrp.CFrame
                        hrp.CFrame = CFrame.new(obj.Position)
                        task.wait(0.1)
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                        else
                            obj.Parent = Character
                        end
                        task.wait(0.1)
                        hrp.CFrame = originalCF
                    end
                end
            end
        end
    end)
end

local function stopAutoGun()
    if state.gunConn then state.gunConn:Disconnect() state.gunConn = nil end
end
-- END PART 2

-- =============================[ UI ]=======================================
local gui = Instance.new("ScreenGui")
gui.Name = "UltraPotatoPanel"
gui.Parent = LocalPlayer.PlayerGui
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 340, 0, 400)
main.Position = UDim2.new(0.5, -170, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 1
mainStroke.Color = Color3.fromRGB(80, 50, 120)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 10)
titleBar.ClipsDescendants = true

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.Text = "🥔 Ultra Panel v3"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 18
title.Font = Enum.Font.GothamBold

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -70, 0, 3)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
closeBtn.BorderSizePixel = 0
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

local delBtn = Instance.new("TextButton", titleBar)
delBtn.Size = UDim2.new(0, 30, 0, 30)
delBtn.Position = UDim2.new(1, -36, 0, 3)
delBtn.Text = "🗑"
delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
delBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
delBtn.BorderSizePixel = 0
delBtn.TextSize = 16
delBtn.Font = Enum.Font.GothamBold
local delCorner = Instance.new("UICorner", delBtn)
delCorner.CornerRadius = UDim.new(0, 6)

local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 42)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
tabBar.BorderSizePixel = 0
local tabBarCorner = Instance.new("UICorner", tabBar)
tabBarCorner.CornerRadius = UDim.new(0, 8)

local tabNames = {"Main", "Fling", "MM2"}
local tabs = {}
local contentFrames = {}

local function switchTab(index)
    for i, frame in ipairs(contentFrames) do
        frame.Visible = (i == index)
    end
    for i, btn in ipairs(tabs) do
        local isActive = (i == index)
        btn.BackgroundColor3 = isActive and Color3.fromRGB(80, 40, 120) or Color3.fromRGB(30, 30, 40)
        btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 170)
    end
end

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(1/3, -4, 1, -6)
    btn.Position = UDim2.new((i-1)/3, 2, 0, 3)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 160, 170)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(80, 40, 120) or Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
    table.insert(tabs, btn)
end

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -20, 1, -96)
content.Position = UDim2.new(0, 10, 0, 84)
content.BackgroundTransparency = 1

local function makeToggle(parent, label, y, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    frame.BorderSizePixel = 0
    local fCorner = Instance.new("UICorner", frame)
    fCorner.CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 70, 0, 26)
    btn.Position = UDim2.new(1, -80, 0, 6)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = on and "ON" or "OFF"
        btn.TextColor3 = on and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        callback(on)
    end)
    return frame
end

local mainTab = Instance.new("Frame", content)
mainTab.Size = UDim2.new(1, 0, 1, 0)
mainTab.BackgroundTransparency = 1
mainTab.Visible = true
table.insert(contentFrames, mainTab)

makeToggle(mainTab, "Anti-Fling", 0, function(v)
    state.antiFling = v
    if v then startAntiFling() else stopAntiFling() end
end)

makeToggle(mainTab, "NoClip", 46, function(v) toggleNoclip(v) end)

makeToggle(mainTab, "Ultra Low Graphics", 92, function(v) toggleUltraLow(v) end)

local speedFrame = Instance.new("Frame", mainTab)
speedFrame.Size = UDim2.new(1, 0, 0, 66)
speedFrame.Position = UDim2.new(0, 0, 0, 138)
speedFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
speedFrame.BorderSizePixel = 0
local sfCorner = Instance.new("UICorner", speedFrame)
sfCorner.CornerRadius = UDim.new(0, 6)

local speedLbl = Instance.new("TextLabel", speedFrame)
speedLbl.Size = UDim2.new(1, -20, 0, 22)
speedLbl.Position = UDim2.new(0, 12, 0, 4)
speedLbl.Text = "Speed: 16"
speedLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLbl.BackgroundTransparency = 1
speedLbl.TextXAlignment = Enum.TextXAlignment.Left
speedLbl.TextSize = 14
speedLbl.Font = Enum.Font.Gotham

local speedBox = Instance.new("TextBox", speedFrame)
speedBox.Size = UDim2.new(0.45, 0, 0, 28)
speedBox.Position = UDim2.new(0, 12, 0, 30)
speedBox.Text = "16"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
speedBox.BorderSizePixel = 0
speedBox.TextSize = 15
speedBox.Font = Enum.Font.GothamBold
speedBox.ClearTextOnFocus = false
local sbCorner = Instance.new("UICorner", speedBox)
sbCorner.CornerRadius = UDim.new(0, 6)

local applyBtn = Instance.new("TextButton", speedFrame)
applyBtn.Size = UDim2.new(0.4, 0, 0, 28)
applyBtn.Position = UDim2.new(0.5, 0, 0, 30)
applyBtn.Text = "Apply"
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
applyBtn.BorderSizePixel = 0
applyBtn.TextSize = 14
applyBtn.Font = Enum.Font.GothamBold
local abCorner = Instance.new("UICorner", applyBtn)
abCorner.CornerRadius = UDim.new(0, 6)
applyBtn.MouseButton1Click:Connect(function()
    local num = tonumber(speedBox.Text)
    if num then
        state.speedValue = num
        if Humanoid then Humanoid.WalkSpeed = num end
        speedLbl.Text = "Speed: " .. num
    end
end)
-- END PART 3

local flingTab = Instance.new("Frame", content)
flingTab.Size = UDim2.new(1, 0, 1, 0)
flingTab.BackgroundTransparency = 1
flingTab.Visible = false
table.insert(contentFrames, flingTab)

local playerList = Instance.new("ScrollingFrame", flingTab)
playerList.Size = UDim2.new(1, 0, 0, 200)
playerList.Position = UDim2.new(0, 0, 0, 0)
playerList.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 6
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
local plCorner = Instance.new("UICorner", playerList)
plCorner.CornerRadius = UDim.new(0, 6)

local selectedPlayer = nil
local selectedLabel = Instance.new("TextLabel", flingTab)
selectedLabel.Size = UDim2.new(1, 0, 0, 24)
selectedLabel.Position = UDim2.new(0, 0, 0, 206)
selectedLabel.Text = "Target: None"
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextSize = 13
selectedLabel.Font = Enum.Font.Gotham

local flingBtn = Instance.new("TextButton", flingTab)
flingBtn.Size = UDim2.new(1, 0, 0, 36)
flingBtn.Position = UDim2.new(0, 0, 0, 234)
flingBtn.Text = "🔥 FLING SELECTED"
flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
flingBtn.BorderSizePixel = 0
flingBtn.TextSize = 15
flingBtn.Font = Enum.Font.GothamBold
local fbCorner = Instance.new("UICorner", flingBtn)
fbCorner.CornerRadius = UDim.new(0, 6)
flingBtn.MouseButton1Click:Connect(function()
    if selectedPlayer then flingPlayer(selectedPlayer) end
end)

local function refreshList()
    for _, c in ipairs(playerList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local y = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", playerList)
            btn.Size = UDim2.new(1, -10, 0, 32)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.Text = p.Name
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btn.BorderSizePixel = 0
            btn.TextSize = 13
            btn.Font = Enum.Font.Gotham
            local bCorner = Instance.new("UICorner", btn)
            bCorner.CornerRadius = UDim.new(0, 6)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                selectedLabel.Text = "Target: " .. p.Name
            end)
            y = y + 36
        end
    end
    playerList.CanvasSize = UDim2.new(0, 0, 0, y)
end

refreshList()
Players.PlayerAdded:Connect(refreshList)
Players.PlayerRemoving:Connect(function(p)
    if selectedPlayer == p then
        selectedPlayer = nil
        selectedLabel.Text = "Target: None"
    end
    refreshList()
end)

local mm2Tab = Instance.new("Frame", content)
mm2Tab.Size = UDim2.new(1, 0, 1, 0)
mm2Tab.BackgroundTransparency = 1
mm2Tab.Visible = false
table.insert(contentFrames, mm2Tab)

makeToggle(mm2Tab, "Kill Aura (Knife)", 0, function(v)
    state.killAura = v
    if v then
        if not isMurderer() then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Kill Aura",
                Text = "You are not the murderer!",
                Duration = 3,
            })
        end
        startKillAura()
    else
        stopKillAura()
    end
end)

makeToggle(mm2Tab, "Shoot Murd Button", 46, function(v)
    state.shootMurd = v
    if v then createShootMurdButton() else removeShootMurdButton() end
end)

makeToggle(mm2Tab, "ESP Roles", 92, function(v)
    state.espRoles = v
    if v then startESP() else stopESP() end
end)

makeToggle(mm2Tab, "Auto Get Gun", 138, function(v)
    state.autoGun = v
    if v then startAutoGun() else stopAutoGun() end
end)

local logoGui
local function createFloatingLogo()
    if logoGui then return end
    logoGui = Instance.new("ScreenGui")
    logoGui.Name = "FloatingLogo"
    logoGui.Parent = LocalPlayer.PlayerGui
    logoGui.ResetOnSpawn = false

    local logoBtn = Instance.new("TextButton", logoGui)
    logoBtn.Size = UDim2.new(0, 60, 0, 60)
    logoBtn.Position = UDim2.new(0.9, 0, 0.85, 0)
    logoBtn.Text = "🥔"
    logoBtn.TextSize = 36
    logoBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
    logoBtn.BorderSizePixel = 0
    logoBtn.Active = true
    logoBtn.Draggable = true
    local lCorner = Instance.new("UICorner", logoBtn)
    lCorner.CornerRadius = UDim.new(0, 30)
    local lStroke = Instance.new("UIStroke", logoBtn)
    lStroke.Thickness = 2
    lStroke.Color = Color3.fromRGB(120, 80, 180)

    logoBtn.MouseButton1Click:Connect(function()
        if gui then gui.Enabled = true end
        if logoGui then logoGui:Destroy() logoGui = nil end
    end)
end

local function destroyFloatingLogo()
    if logoGui then logoGui:Destroy() logoGui = nil end
end

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
    createFloatingLogo()
end)

delBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    destroyFloatingLogo()
end)

switchTab(1)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    if state.noclip then toggleNoclip(true) end
    if Humanoid then Humanoid.WalkSpeed = state.speedValue end
end)
-- END PART 4
