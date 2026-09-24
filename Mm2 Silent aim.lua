-- ============================================================
-- MM2 DOMINATOR – FULL EXPLOIT (PART 1/4)
-- Author: Potato
-- Description: Config, state, role detection, murderer finder,
--              ping compensation, and prediction logic.
-- ============================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    SilentAim = true,
    MurdererESP = true,
    AutoGetGun = true,
    SpeedBypass = true,
    HitboxExpander = true,
    Range = 120,
    BasePrediction = 0.13,
    PingMultiplier = 0.0008,
    MaxPrediction = 0.25,
    FireDelay = 0.25,
    AimJitter = 0.15,
    SmoothFrames = 3,
    HitboxPriority = {"Head", "Torso", "HumanoidRootPart"},
    ESPColor = Color3.fromRGB(255, 0, 0),
    BoostedSpeed = 45,
    NormalSpeed = 16,
    HitboxMultiplier = 2.0,
    MaxHitboxSize = 50,
    GunPickupRange = 200,
    UI_SCALE = 0.85,
}

-- ============================================================
-- STATE
-- ============================================================
local state = {
    CurrentRole = "Innocent",
    Murderer = nil,
    LastFire = 0,
    VelocityHistory = {},
    Ping = 0,
    LastGunPickup = 0,
    ESPObjects = {},
    OriginalSizes = {},
    Hooked = false,
    Toggles = {
        ["Silent Aim"] = true,
        ["Murderer ESP"] = true,
        ["Auto Get Gun"] = true,
        ["Speed Bypass"] = true,
        ["Hitbox Expander"] = true,
    },
}

-- ============================================================
-- ROLE DETECTION
-- ============================================================
local function detectRole()
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local name = string.lower(tool.Name)
            if string.find(name, "knife") then
                state.CurrentRole = "Murderer"
                return
            elseif string.find(name, "gun") then
                state.CurrentRole = "Sheriff"
                return
            end
        end
    end
    state.CurrentRole = "Innocent"
end

-- ============================================================
-- FIND MURDERER
-- ============================================================
local function findMurderer()
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            for _, tool in ipairs(p.Character:GetChildren()) do
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "knife") then
                    state.Murderer = p
                    return p
                end
            end
        end
    end
    state.Murderer = nil
    return nil
end

-- ============================================================
-- PING + PREDICTION
-- ============================================================
local function getPing()
    local ok, ping = pcall(function()
        return player:GetNetworkPing() * 1000
    end)
    state.Ping = ok and ping or 50
    return state.Ping
end

local function getPredictionTime()
    local prediction = CONFIG.BasePrediction + (getPing() * CONFIG.PingMultiplier)
    return math.min(prediction, CONFIG.MaxPrediction)
end

local function smoothVelocity(targetRoot)
    table.insert(state.VelocityHistory, targetRoot.Velocity)
    if #state.VelocityHistory > CONFIG.SmoothFrames then
        table.remove(state.VelocityHistory, 1)
    end
    local sum = Vector3.new(0, 0, 0)
    for _, v in ipairs(state.VelocityHistory) do
        sum = sum + v
    end
    return sum / #state.VelocityHistory
end

local function getTargetPosition(targetChar)
    for _, hitboxName in ipairs(CONFIG.HitboxPriority) do
        local hitbox = targetChar:FindFirstChild(hitboxName)
        if hitbox then return hitbox.Position end
    end
    return nil
end

local function predictPosition(targetRoot)
    if not targetRoot then return nil end
    local position = getTargetPosition(targetRoot.Parent) or targetRoot.Position
    local velocity = smoothVelocity(targetRoot)
    local hum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
    local pt = getPredictionTime()
    local predicted = position + (velocity * pt)
    if hum then
        if hum.FloorMaterial == Enum.Material.Air then
            predicted = predicted + Vector3.new(0, velocity.Y * pt * 0.5, 0)
        elseif hum.MoveDirection.Magnitude > 0 then
            predicted = predicted + (hum.MoveDirection * 2)
        end
    end
    if CONFIG.AimJitter > 0 then
        predicted = predicted + Vector3.new(
            (math.random() - 0.5) * CONFIG.AimJitter,
            0,
            (math.random() - 0.5) * CONFIG.AimJitter
        )
    end
    return predicted
end

-- ============================================================
-- MM2 DOMINATOR – FULL EXPLOIT (PART 2/4)
-- Author: Potato
-- Description: Silent aim, auto fire, murderer ESP, auto get gun.
-- ============================================================

-- ============================================================
-- SILENT AIM
-- ============================================================
local function silentAim()
    if not state.Toggles["Silent Aim"] then return end
    if state.CurrentRole ~= "Sheriff" and state.CurrentRole ~= "Hero" then return end
    local murderer = state.Murderer or findMurderer()
    if not murderer or not murderer.Character then return end
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local predictedPos = predictPosition(targetRoot)
    if not predictedPos then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "gun") then
            for _, child in ipairs(tool:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    local oldFire = child.FireServer
                    child.FireServer = function(self, ...)
                        local args = {...}
                        if #args > 0 then args[1] = predictedPos
                        else table.insert(args, predictedPos) end
                        return oldFire(self, unpack(args))
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AUTO FIRE
-- ============================================================
local function autoFire()
    if not CONFIG.SilentAim then return end
    if state.CurrentRole ~= "Sheriff" and state.CurrentRole ~= "Hero" then return end
    local now = tick()
    if now - state.LastFire < CONFIG.FireDelay then return end
    local murderer = state.Murderer or findMurderer()
    if not murderer or not murderer.Character then return end
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    if (rootPart.Position - targetRoot.Position).Magnitude > CONFIG.Range then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "gun") then
            tool:Activate()
            state.LastFire = now
            break
        end
    end
end

-- ============================================================
-- MURDERER ESP (RED)
-- ============================================================
local function clearESP()
    for _, obj in ipairs(state.ESPObjects) do
        if obj and obj.Remove then obj:Remove() end
    end
    state.ESPObjects = {}
end

local function drawESP()
    if not state.Toggles["Murderer ESP"] then clearESP() return end
    clearESP()
    local murderer = state.Murderer or findMurderer()
    if not murderer or not murderer.Character then return end
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local pos, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
    if not onScreen then return end
    local dist = (rootPart.Position - targetRoot.Position).Magnitude
    local box = Drawing.new("Square")
    box.Position = Vector2.new(pos.X - 30, pos.Y - 60)
    box.Size = Vector2.new(60, 90)
    box.Color = CONFIG.ESPColor
    box.Thickness = 2
    box.Transparency = 0.8
    box.Filled = false
    box.Visible = true
    table.insert(state.ESPObjects, box)
    local label = Drawing.new("Text")
    label.Position = Vector2.new(pos.X - 40, pos.Y - 85)
    label.Text = "🔪 " .. murderer.Name .. " [" .. math.floor(dist) .. "m]"
    label.Color = CONFIG.ESPColor
    label.Size = 16
    label.Center = true
    label.Outline = true
    label.Visible = true
    table.insert(state.ESPObjects, label)
    local tracer = Drawing.new("Line")
    tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    tracer.To = Vector2.new(pos.X, pos.Y)
    tracer.Color = CONFIG.ESPColor
    tracer.Thickness = 1
    tracer.Transparency = 0.5
    tracer.Visible = true
    table.insert(state.ESPObjects, tracer)
end

-- ============================================================
-- AUTO GET GUN
-- ============================================================
local function findDroppedGun()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and string.find(string.lower(obj.Name), "gun") then
            if obj.Parent == workspace or obj.Parent:IsA("Model") then
                return obj
            end
        end
    end
    return nil
end

local function autoGetGun()
    if not state.Toggles["Auto Get Gun"] then return end
    if state.CurrentRole == "Murderer" then return end
    local now = tick()
    if now - state.LastGunPickup < 0.5 then return end
    local gun = findDroppedGun()
    if not gun then return end
    local gunPos = gun:IsA("BasePart") and gun.Position or (gun:FindFirstChild("Handle") and gun.Handle.Position)
    if not gunPos then return end
    if (rootPart.Position - gunPos).Magnitude > CONFIG.GunPickupRange then return end
    state.LastGunPickup = now
    rootPart.CFrame = CFrame.new(gunPos)
    wait(0.1)
    for _, child in ipairs(gun:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            child.HoldDuration = 0
            child:InputHoldBegin()
            wait(0.05)
            child:InputHoldEnd()
            break
        elseif child:IsA("ClickDetector") then
            child:Click()
            break
        end
    end
    pcall(function() gun.Parent = player.Backpack end)
    print("🔫 Auto-grabbed gun!")
end

-- ============================================================
-- MM2 DOMINATOR – FULL EXPLOIT (PART 3/4)
-- Author: Potato
-- Description: Speed bypass, hitbox expander, and UI.
-- ============================================================

-- ============================================================
-- LOOP SPEED BYPASS
-- ============================================================
local function speedLoop()
    if not state.Toggles["Speed Bypass"] then return end
    if humanoid then
        humanoid.WalkSpeed = CONFIG.BoostedSpeed
    end
end

-- ============================================================
-- HITBOX EXPANDER (INVISIBLE)
-- ============================================================
local function expandHitbox(part)
    if not part or not part:IsA("BasePart") then return end
    if not state.OriginalSizes[part] then
        state.OriginalSizes[part] = part.Size
    end
    local original = state.OriginalSizes[part]
    part.Size = Vector3.new(
        math.min(original.X * CONFIG.HitboxMultiplier, CONFIG.MaxHitboxSize),
        math.min(original.Y * CONFIG.HitboxMultiplier, CONFIG.MaxHitboxSize),
        math.min(original.Z * CONFIG.HitboxMultiplier, CONFIG.MaxHitboxSize)
    )
    part.Transparency = 1
    part.CanCollide = false
    part.CastShadow = false
    part.Massless = true
end

local function hitboxLoop()
    if not state.Toggles["Hitbox Expander"] then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "hitbox") or string.find(name, "hit") or string.find(name, "damage") then
                expandHitbox(obj)
            end
        end
    end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, obj in ipairs(tool:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = string.lower(obj.Name)
                    if string.find(name, "hitbox") or string.find(name, "hit") or string.find(name, "damage") then
                        expandHitbox(obj)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- UI (AURA FARMING + COOL FONT) – LANDSCAPE FIX + SPEED INPUT
-- ============================================================
local UI_SCALE = CONFIG.UI_SCALE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2DominatorUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- ============================================================
-- AURA FRAME (Positioned top-left for landscape)
-- ============================================================
local auraFrame = Instance.new("Frame")
auraFrame.Size = UDim2.new(0, 340 * UI_SCALE, 0, 460 * UI_SCALE)
auraFrame.Position = UDim2.new(0, 10, 0, 10)
auraFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
auraFrame.BorderSizePixel = 0
auraFrame.ClipsDescendants = true
auraFrame.Parent = screenGui

local auraCorner = Instance.new("UICorner")
auraCorner.CornerRadius = UDim.new(0, 22 * UI_SCALE)
auraCorner.Parent = auraFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 20)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 0, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 20, 20)),
})
gradient.Parent = auraFrame

local gradientRotation = 0
runService.Heartbeat:Connect(function(dt)
    gradientRotation = gradientRotation + dt * 40
    gradient.Rotation = gradientRotation % 360
end)

local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(255, 50, 50)
glow.Thickness = 2
glow.Transparency = 0.2
glow.Parent = auraFrame

local glowPulse = 0
runService.Heartbeat:Connect(function(dt)
    glowPulse = glowPulse + dt * 4
    glow.Transparency = 0.2 + math.sin(glowPulse) * 0.15
    glow.Color = Color3.fromRGB(
        200 + math.sin(glowPulse) * 55,
        30,
        30 + math.sin(glowPulse * 1.5) * 30
    )
end)

-- ============================================================
-- HEADER
-- ============================================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40 * UI_SCALE)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
header.Parent = auraFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 22 * UI_SCALE)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -95 * UI_SCALE, 1, 0)
title.Position = UDim2.new(0, 12 * UI_SCALE, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ MM2 DOMINATOR ⚡"
title.TextColor3 = Color3.fromRGB(255, 215, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local titleGlow = Instance.new("UIStroke")
titleGlow.Color = Color3.fromRGB(255, 100, 100)
titleGlow.Thickness = 1
titleGlow.Transparency = 0.5
titleGlow.Parent = title

local titlePulse = 0
runService.Heartbeat:Connect(function(dt)
    titlePulse = titlePulse + dt * 2
    title.TextColor3 = Color3.fromRGB(
        255,
        215 + math.sin(titlePulse) * 40,
        100 + math.sin(titlePulse) * 50
    )
end)

local function createButton(text, color, xOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28 * UI_SCALE, 0, 28 * UI_SCALE)
    btn.Position = UDim2.new(1, xOffset * UI_SCALE, 0, 6 * UI_SCALE)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBlack
    btn.Parent = header
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    local btnGlow = Instance.new("UIStroke")
    btnGlow.Color = Color3.fromRGB(255, 255, 255)
    btnGlow.Thickness = 1
    btnGlow.Transparency = 0.7
    btnGlow.Parent = btn
    return btn
end

local minimizeBtn = createButton("−", Color3.fromRGB(255, 180, 50), -100)
local closeBtn = createButton("✕", Color3.fromRGB(200, 50, 50), -68)
local deleteBtn = createButton("⌫", Color3.fromRGB(100, 100, 100), -36)

-- ============================================================
-- FEATURE LIST
-- ============================================================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -14 * UI_SCALE, 1, -55 * UI_SCALE)
scrollFrame.Position = UDim2.new(0, 7 * UI_SCALE, 0, 45 * UI_SCALE)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4 * UI_SCALE
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)
scrollFrame.Parent = auraFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6 * UI_SCALE)

local featureList = {
    "🎯 Silent Aim",
    "🔴 Murderer ESP",
    "🔫 Auto Get Gun",
    "⚡ Speed Bypass",
    "📏 Hitbox Expander",
}

for _, featureName in ipairs(featureList) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36 * UI_SCALE)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Parent = scrollFrame
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 10 * UI_SCALE)
    rowCorner.Parent = row
    local rowGlow = Instance.new("UIStroke")
    rowGlow.Color = Color3.fromRGB(100, 100, 255)
    rowGlow.Thickness = 1
    rowGlow.Transparency = 0.8
    rowGlow.Parent = row
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12 * UI_SCALE, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = featureName
    label.TextColor3 = Color3.fromRGB(230, 230, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 42 * UI_SCALE, 0, 24 * UI_SCALE)
    toggle.Position = UDim2.new(1, -52 * UI_SCALE, 0, 6 * UI_SCALE)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = row
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    local circle = Instance.new("TextLabel")
    circle.Size = UDim2.new(0, 20 * UI_SCALE, 0, 20 * UI_SCALE)
    circle.Position = UDim2.new(0, 2 * UI_SCALE, 0, 2 * UI_SCALE)
    circle.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
    circle.BorderSizePixel = 0
    circle.Text = ""
    circle.Parent = toggle
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    local cleanName = featureName:gsub("[^%w%s]", ""):match("^%s*(.-)%s*$")
    local isOn = state.Toggles[cleanName] or false
    local function updateToggle()
        if isOn then
            toggle.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
            circle.Position = UDim2.new(0, 20 * UI_SCALE, 0, 2 * UI_SCALE)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            circle.Position = UDim2.new(0, 2 * UI_SCALE, 0, 2 * UI_SCALE)
        end
        state.Toggles[cleanName] = isOn
    end
    updateToggle()
    toggle.MouseButton1Click:Connect(function() isOn = not isOn updateToggle() end)
    toggle.TouchTap:Connect(function() isOn = not isOn updateToggle() end)
end

-- ============================================================
-- SPEED INPUT ROW
-- ============================================================
local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(1, 0, 0, 40 * UI_SCALE)
speedRow.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
speedRow.BackgroundTransparency = 0.2
speedRow.BorderSizePixel = 0
speedRow.Parent = scrollFrame

local speedRowCorner = Instance.new("UICorner")
speedRowCorner.CornerRadius = UDim.new(0, 10 * UI_SCALE)
speedRowCorner.Parent = speedRow

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 1, 0)
speedLabel.Position = UDim2.new(0, 12 * UI_SCALE, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ Speed:"
speedLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedRow

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 85 * UI_SCALE, 0, 28 * UI_SCALE)
speedInput.Position = UDim2.new(1, -100 * UI_SCALE, 0, 6 * UI_SCALE)
speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
speedInput.BackgroundTransparency = 0.2
speedInput.BorderSizePixel = 0
speedInput.Text = tostring(CONFIG.BoostedSpeed)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextScaled = true
speedInput.Font = Enum.Font.GothamBold
speedInput.PlaceholderText = "Speed"
speedInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
speedInput.ClearTextOnFocus = false
speedInput.Parent = speedRow

local speedInputCorner = Instance.new("UICorner")
speedInputCorner.CornerRadius = UDim.new(0, 8 * UI_SCALE)
speedInputCorner.Parent = speedInput

local speedGlow = Instance.new("UIStroke")
speedGlow.Color = Color3.fromRGB(255, 100, 100)
speedGlow.Thickness = 1
speedGlow.Transparency = 0.5
speedGlow.Parent = speedInput

speedInput.FocusLost:Connect(function()
    local value = tonumber(speedInput.Text)
    if value and value > 0 and value <= 500 then
        CONFIG.BoostedSpeed = value
        print("⚡ Speed set to: " .. value)
    else
        speedInput.Text = tostring(CONFIG.BoostedSpeed)
    end
end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- FLOATING "F" BUTTON
-- ============================================================
local floatingBtn = Instance.new("TextButton")
floatingBtn.Size = UDim2.new(0, 60 * UI_SCALE, 0, 60 * UI_SCALE)
floatingBtn.Position = UDim2.new(0, 20 * UI_SCALE, 1, -90 * UI_SCALE)
floatingBtn.BackgroundColor3 = Color3.fromRGB(255, 20, 20)
floatingBtn.BackgroundTransparency = 0.05
floatingBtn.BorderSizePixel = 0
floatingBtn.Text = "F"
floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.TextScaled = true
floatingBtn.Font = Enum.Font.GothamBlack
floatingBtn.Visible = false
floatingBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatingBtn

local floatGlow = Instance.new("UIStroke")
floatGlow.Color = Color3.fromRGB(255, 255, 255)
floatGlow.Thickness = 2
floatGlow.Transparency = 0.4
floatGlow.Parent = floatingBtn

local floatPulse = 0
runService.Heartbeat:Connect(function(dt)
    if floatingBtn.Visible then
        floatPulse = floatPulse + dt * 4
        floatGlow.Transparency = 0.2 + math.sin(floatPulse) * 0.3
        floatingBtn.BackgroundColor3 = Color3.fromRGB(
            255,
            20 + math.sin(floatPulse) * 30,
            20 + math.sin(floatPulse * 0.8) * 40
        )
    end
end)

-- ============================================================
-- MM2 DOMINATOR – FULL EXPLOIT (PART 4/4)
-- Author: Potato
-- Description: Drag logic, button actions, tap to fire,
--              main loop, and initialization.
-- ============================================================

-- ============================================================
-- DRAG LOGIC
-- ============================================================
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = auraFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
userInput.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        auraFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local floatDragging, floatDragStart, floatStartPos
floatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = floatingBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then floatDragging = false end
        end)
    end
end)
userInput.InputChanged:Connect(function(input)
    if floatDragging then
        local delta = input.Position - floatDragStart
        floatingBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
    end
end)

-- ============================================================
-- BUTTON ACTIONS
-- ============================================================
minimizeBtn.MouseButton1Click:Connect(function()
    local shrink = tweenService:Create(auraFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    shrink:Play()
    shrink.Completed:Connect(function()
        auraFrame.Visible = false
        auraFrame.Size = UDim2.new(0, 340 * UI_SCALE, 0, 460 * UI_SCALE)
        auraFrame.Position = UDim2.new(0, 10, 0, 10)
        floatingBtn.Visible = true
    end)
end)

closeBtn.MouseButton1Click:Connect(function()
    auraFrame.Visible = false
    floatingBtn.Visible = true
end)

deleteBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

floatingBtn.MouseButton1Click:Connect(function()
    if not floatDragging then
        floatingBtn.Visible = false
        auraFrame.Visible = true
        auraFrame.Size = UDim2.new(0, 0, 0, 0)
        auraFrame.Position = UDim2.new(0, 10, 0, 10)
        local grow = tweenService:Create(auraFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 340 * UI_SCALE, 0, 460 * UI_SCALE),
            Position = UDim2.new(0, 10, 0, 10)
        })
        grow:Play()
    end
end)

-- ============================================================
-- TAP ANYWHERE TO FIRE
-- ============================================================
userInput.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if state.CurrentRole == "Sheriff" or state.CurrentRole == "Hero" then
            autoFire()
        end
    end
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
runService.Heartbeat:Connect(function()
    pcall(function()
        detectRole()
        findMurderer()
        getPing()
        silentAim()
        drawESP()
        autoGetGun()
        speedLoop()
        hitboxLoop()
    end)
end)

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    state.VelocityHistory = {}
    clearESP()
    detectRole()
end)

-- ============================================================
-- INITIALIZE-- ============================================================
detectRole()
findMurderer()
getPing()

print("🥔 MM2 DOMINATOR FULL EXPLOIT LOADED")
print("🎯 Role: " .. state.CurrentRole)
print("📡 Ping: " .. math.floor(state.Ping) .. "ms")
print("🔴 Murderer ESP: RED")
print("🔫 Auto Get Gun: ON")
print("⚡ Speed Bypass: " .. CONFIG.BoostedSpeed)
print("📏 Hitbox Expander: " .. CONFIG.HitboxMultiplier .. "x")
print("📱 Tap anywhere to fire. Use UI to toggle features.")

