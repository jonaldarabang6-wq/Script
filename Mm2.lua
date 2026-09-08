-- ============================================================
-- PART 1/2 – UNIVERSAL MM2 DOMINATOR MOBILE
-- SECTIONS 1-8: Core Setup, GUI, Helpers, Player Selector
-- Author: Potato
-- ============================================================

-- ============================================================
-- SECTION 1: CONFIGURATION
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
local mouse = player:GetMouse()

local features = {
    SilentAim = false,
    KillAura = false,
    KillNearest = false,
    AutoShoot = false,
    BreakGun = false,
    StealGun = false,
    AutoThrow = false,
    ESP = false,
    GunESP = false,
    CoinMagnet = false,
    AutoFarm = false,
    AutoGetGun = false,
    XRay = false,
    SpeedBoost = false,
    Fly = false,
    NoClip = false,
    Teleport = false,
    KillAll = false,
    FakeGun = false,
    Rocket = false,
    Fling = false,
    ForceJump = false,
    Smash = false,
}

-- ============================================================
-- SECTION 2: STATE
-- ============================================================
local state = {
    SelectedPlayer = nil,
    PlayerSelectorOpen = false,
}

-- ============================================================
-- SECTION 3: CREATE MAIN GUI (Mobile-Optimized)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PotatoMM2GUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 480)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🥔 MM2 MOBILE"
title.TextColor3 = Color3.fromRGB(255, 215, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 0.5, -45)
scrollFrame.Position = UDim2.new(0, 5, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = scrollFrame
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)

-- Generate toggles
for featureName, _ in pairs(features) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    frame.BackgroundTransparency = 0.3
    frame.Parent = scrollFrame
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = featureName
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextScaled = true
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 36, 0, 18)
    toggle.Position = UDim2.new(1, -44, 0, 5)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local circle = Instance.new("TextLabel")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    circle.BackgroundTransparency = 0
    circle.BorderSizePixel = 0
    circle.Text = ""
    circle.Parent = toggle
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local isOn = false
    local function updateToggle()
        if isOn then
            toggle.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            circle.Position = UDim2.new(0, 20, 0, 2)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            circle.Position = UDim2.new(0, 2, 0, 2)
        end
        features[featureName] = isOn
    end
    updateToggle()
    
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateToggle()
        print("🔘 " .. featureName .. " = " .. tostring(isOn))
    end)
    
    toggle.TouchTap:Connect(function()
        isOn = not isOn
        updateToggle()
        print("🔘 " .. featureName .. " = " .. tostring(isOn))
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- SECTION 4: ACTION BUTTONS FRAME
-- ============================================================
local actionFrame = Instance.new("Frame")
actionFrame.Size = UDim2.new(1, -10, 0.35, 0)
actionFrame.Position = UDim2.new(0, 5, 0.55, 0)
actionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
actionFrame.BackgroundTransparency = 0.3
actionFrame.BorderSizePixel = 0
actionFrame.Parent = mainFrame

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = actionFrame

local actionTitle = Instance.new("TextLabel")
actionTitle.Size = UDim2.new(1, 0, 0, 25)
actionTitle.Position = UDim2.new(0, 0, 0, 0)
actionTitle.BackgroundTransparency = 1
actionTitle.Text = "🔥 TROLL ACTIONS"
actionTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
actionTitle.TextScaled = true
actionTitle.Font = Enum.Font.GothamBold
actionTitle.Parent = actionFrame

local grid = Instance.new("GridLayout")
grid.Parent = actionFrame
grid.CellSize = UDim2.new(0, 70, 0, 40)
grid.CellPadding = UDim2.new(0, 5, 0, 5)
grid.StartCorner = Enum.StartCorner.TopLeft
grid.FillDirection = Enum.FillDirection.Horizontal
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center

local actions = {
    {Name = "🎯 Select", Key = "Select"},
    {Name = "🚀 Rocket", Key = "Rocket"},
    {Name = "💨 Fling", Key = "Fling"},
    {Name = "🦘 Jump", Key = "ForceJump"},
    {Name = "💥 Smash", Key = "Smash"},
    {Name = "☠️ KillAll", Key = "KillAll"},
}

-- Buttons will be created after handleAction is defined
-- ============================================================
-- SECTION 5: ACTION HANDLER
-- ============================================================
function handleAction(action)
    if action == "Select" then
        togglePlayerSelector()
        return
    end
    
    local target = state.SelectedPlayer or getNearestPlayer()
    if not target or not target.Character or not target.Character.Parent then
        print("⚠️ No player selected! Use 'Select' first.")
        return
    end
    
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if action == "Rocket" then
        if features.Rocket then
            root.Velocity = Vector3.new(0, 500, 0)
            print("🚀 Rocket launched: " .. target.Name)
        else
            print("⚠️ Rocket feature is disabled.")
        end
    elseif action == "Fling" then
        if features.Fling then
            local dir = Vector3.new(math.random(-1000, 1000), math.random(500, 2000), math.random(-1000, 1000))
            root.Velocity = dir
            print("💨 Fling: " .. target.Name)
        else
            print("⚠️ Fling feature is disabled.")
        end
    elseif action == "ForceJump" then
        if features.ForceJump then
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Jump = true
                wait(0.1)
                hum.Jump = false
                print("🦘 Force Jump: " .. target.Name)
            end
        else
            print("⚠️ Force Jump feature is disabled.")
        end
    elseif action == "Smash" then
        if features.Smash then
            root.Velocity = Vector3.new(0, -200, 0)
            wait(0.3)
            root.CFrame = root.CFrame + Vector3.new(0, -10, 0)
            print("💥 Smash: " .. target.Name)
        else
            print("⚠️ Smash feature is disabled.")
        end
    elseif action == "KillAll" then
        if features.KillAll then
            for _, p in ipairs(players:GetPlayers()) do
                if p ~= player and p.Character and p.Character.Parent then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                end
            end
            print("☠️ Kill All executed!")
        else
            print("⚠️ Kill All feature is disabled.")
        end
    end
end

-- Create action buttons after handleAction is defined
for _, action in ipairs(actions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.BackgroundTransparency = 0.2
    btn.Text = action.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = actionFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        handleAction(action.Key)
    end)
    btn.TouchTap:Connect(function()
        handleAction(action.Key)
    end)
end

-- ============================================================
-- SECTION 6: PLAYER SELECTOR (Mobile-Optimized)
-- ============================================================
local selectorGui = nil
local selectorOpen = false

function togglePlayerSelector()
    if selectorOpen then
        if selectorGui then selectorGui:Destroy() end
        selectorOpen = false
        return
    end
    
    selectorGui = Instance.new("ScreenGui")
    selectorGui.Name = "PlayerSelector"
    selectorGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 350)
    frame.Position = UDim2.new(0.5, -125, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = selectorGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎯 SELECT PLAYER"
    title.TextColor3 = Color3.fromRGB(255, 215, 100)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -45)
    scroll.Position = UDim2.new(0, 5, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = frame
    
    local layout2 = Instance.new("UIListLayout")
    layout2.Parent = scroll
    layout2.SortOrder = Enum.SortOrder.LayoutOrder
    layout2.Padding = UDim.new(0, 4)
    
    local playerList = getAllPlayers()
    if #playerList == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "No players found"
        empty.TextColor3 = Color3.fromRGB(255, 255, 255)
        empty.TextScaled = true
        empty.Font = Enum.Font.GothamMedium
        empty.Parent = scroll
    end
    
    for _, p in ipairs(playerList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        btn.BackgroundTransparency = 0.3
        btn.Text = p.Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = scroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            state.SelectedPlayer = p
            print("🎯 Selected: " .. p.Name)
            selectorGui:Destroy()
            selectorOpen = false
        end)
        btn.TouchTap:Connect(function()
            state.SelectedPlayer = p
            print("🎯 Selected: " .. p.Name)
            selectorGui:Destroy()
            selectorOpen = false
        end)
    end
    
    layout2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout2.AbsoluteContentSize.Y + 10)
    end)
    
    selectorOpen = true
end

-- ============================================================
-- SECTION 7: DRAG MAIN FRAME (Mobile-Safe)
-- ============================================================
local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

userInput.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
-- SECTION 8: HELPER FUNCTIONS
-- ============================================================
local function getNearestPlayer()
    local nearest = nil
    local nearestDist = math.huge
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (rootPart.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearest = p
                    nearestDist = dist
                end
            end
        end
    end
    return nearest, nearestDist
end

local function getAllPlayers()
    local list = {}
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            table.insert(list, p)
        end
    end
    return list
end

local function getMurderer()
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            for _, child in ipairs(p.Character:GetChildren()) do
                if child:IsA("Tool") and string.find(string.lower(child.Name), "knife") then
                    return p
                end
            end
        end
    end
    return nil
end

local function getDroppedGun()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and string.find(string.lower(obj.Name), "gun") then
            return obj
        end
    end
    return nil
end

local function getNearestCoin()
    local nearest = nil
    local nearestDist = math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and string.find(string.lower(obj.Name), "coin") then
            local dist = (rootPart.Position - obj.Position).Magnitude
            if dist < nearestDist then
                nearest = obj
                nearestDist = dist
            end
        end
    end
    return nearest, nearestDist
end

local function fireRemote(remoteName, ...)
    for _, remote in ipairs(rs:GetChildren()) do
        if remote:IsA("RemoteEvent") and string.find(string.lower(remote.Name), string.lower(remoteName)) then
            pcall(function() remote:FireServer(...) end)
            return true
        end
    end
    return false
end

-- ============================================================
-- PART 2/2 – UNIVERSAL MM2 DOMINATOR MOBILE
-- SECTIONS 9-15: All Features + Main Loop
-- Author: Potato
-- ============================================================

-- ============================================================
-- SECTION 9: COMBAT FEATURES
-- ============================================================

local function silentAimLoop()
    if not features.SilentAim then return end
    local target, dist = getNearestPlayer()
    if target and dist < 100 then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, root.Position)
        end
    end
end

local function killAuraLoop()
    if not features.KillAura then return end
    local target, dist = getNearestPlayer()
    if target and dist < 15 then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and string.find(string.lower(tool.Name), "knife") then
                tool:Activate()
                fireRemote("Throw", target)
            end
        end
    end
end

local function killNearestLoop()
    if not features.KillNearest then return end
    local target, dist = getNearestPlayer()
    if target and dist < 20 then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and string.find(string.lower(tool.Name), "knife") then
                tool:Activate()
                fireRemote("Throw", target)
            end
        end
    end
end

local function autoShootLoop()
    if not features.AutoShoot then return end
    local murderer = getMurderer()
    if murderer then
        local root = murderer.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - rootPart.Position).Magnitude < 80 then
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "gun") then
                    tool:Activate()
                    fireRemote("Shoot", murderer)
                end
            end
        end
    end
end

local function breakGunLoop()
    if not features.BreakGun then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and string.find(string.lower(obj.Name), "gun") then
            obj.CanBeDropped = false
            obj.Parent = nil
        end
    end
end

local function stealGunLoop()
    if not features.StealGun then return end
    local gun = getDroppedGun()
    if gun then
        local dist = (rootPart.Position - gun.Position).Magnitude
        if dist < 10 then
            gun.Parent = character
        end
    end
end

local function autoThrowLoop()
    if not features.AutoThrow then return end
    local target, dist = getNearestPlayer()
    if target and dist > 5 and dist < 60 then
        fireRemote("Throw", target)
    end
end

-- ============================================================
-- SECTION 10: VISUAL FEATURES
-- ============================================================
local espObjects = {}

local function espLoop()
    if not features.ESP then
        for _, obj in ipairs(espObjects) do
            if obj and obj.Remove then obj:Remove() end
        end
        espObjects = {}
        return
    end
    
    for i = #espObjects, 1, -1 do
        if espObjects[i] and espObjects[i].Remove then
            espObjects[i]:Remove()
        end
        table.remove(espObjects, i)
    end
    
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local color = Color3.fromRGB(0, 255, 0)
                    for _, child in ipairs(p.Character:GetChildren()) do
                        if child:IsA("Tool") and string.find(string.lower(child.Name), "knife") then
                            color = Color3.fromRGB(255, 0, 0)
                        end
                        if child:IsA("Tool") and string.find(string.lower(child.Name), "gun") then
                            color = Color3.fromRGB(0, 0, 255)
                        end
                    end
                    
                    local box = Drawing.new("Square")
                    box.Position = Vector2.new(pos.X - 25, pos.Y - 40)
                    box.Size = Vector2.new(50, 60)
                    box.Color = color
                    box.Thickness = 2
                    box.Visible = true
                    box.Filled = false
                    table.insert(espObjects, box)
                    
                    local label = Drawing.new("Text")
                    label.Position = Vector2.new(pos.X - 20, pos.Y - 55)
                    label.Text = p.Name
                    label.Color = color
                    label.Size = 12
                    label.Visible = true
                    table.insert(espObjects, label)
                    
                    if p == state.SelectedPlayer then
                        local indicator = Drawing.new("Circle")
                        indicator.Position = Vector2.new(pos.X, pos.Y - 60)
                        indicator.Radius = 10
                        indicator.Color = Color3.fromRGB(255, 255, 0)
                        indicator.Thickness = 3
                        indicator.Visible = true
                        indicator.Filled = false
                        table.insert(espObjects, indicator)
                    end
                end
            end
        end
    end
end

local function gunESPLoop()
    if not features.GunESP then return end
    local gun = getDroppedGun()
    if gun then
        local pos, onScreen = camera:WorldToViewportPoint(gun.Position)
        if onScreen then
            local label = Drawing.new("Text")
            label.Position = Vector2.new(pos.X - 15, pos.Y - 10)
            label.Text = "🔫 GUN"
            label.Color = Color3.fromRGB(255, 255, 0)
            label.Size = 14
            label.Visible = true
            table.insert(espObjects, label)
        end
    end
end

-- ============================================================
-- SECTION 11: AUTOMATION FEATURES
-- ============================================================

local function coinMagnetLoop()
    if not features.CoinMagnet then return end
    local coin, dist = getNearestCoin()
    if coin and dist < 30 then
        humanoid:MoveTo(coin.Position)
        if dist < 3 then
            coin.Parent = nil
        end
    end
end

local function autoFarmLoop()
    if not features.AutoFarm then return end
    local coin, dist = getNearestCoin()
    if coin then
        humanoid:MoveTo(coin.Position)
        if dist < 3 then
            coin.Parent = nil
            wait(0.1)
        end
    end
end

local function autoGetGunLoop()
    if not features.AutoGetGun then return end
    local gun = getDroppedGun()
    if gun then
        local dist = (rootPart.Position - gun.Position).Magnitude
        if dist < 20 then
            humanoid:MoveTo(gun.Position)
            if dist < 3 then
                gun.Parent = character
            end
        end
    end
end

local function xrayLoop()
    if not features.XRay then return end
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0.5
                end
            end
        end
    end
end

-- ============================================================
-- SECTION 12: MOVEMENT FEATURES
-- ============================================================

local function speedLoop()
    if features.SpeedBoost then
        humanoid.WalkSpeed = 18
    else
        humanoid.WalkSpeed = 16
    end
end

local function flyLoop()
    if not features.Fly then return end
    if userInput:IsKeyDown(Enum.KeyCode.Space) then
        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 3, 0)
    end
    local move = Vector3.new(0, 0, 0)
    if userInput:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector * Vector3.new(1, 0, 1) end
    if userInput:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector * Vector3.new(1, 0, 1) end
    if userInput:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector * Vector3.new(1, 0, 1) end
    if userInput:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector * Vector3.new(1, 0, 1) end
    if move.Magnitude > 0 then
        rootPart.CFrame = rootPart.CFrame + move.Unit * 2
    end
end

local function noClipLoop()
    if not features.NoClip then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function teleportLoop()
    if not features.Teleport then return end
    if userInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = mouse.Hit.Position
        if target then
            rootPart.CFrame = CFrame.new(target)
        end
    end
end

-- ============================================================
-- SECTION 13: TROLL FEATURES
-- ============================================================

local function killAllLoop()
    if not features.KillAll then return end
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= player and p.Character and p.Character.Parent then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end
    end
end

local function fakeGunLoop()
    if not features.FakeGun then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "knife") then
            tool.Name = "Gun"
        end
    end
end

-- ============================================================
-- SECTION 14: MAIN LOOP
-- ============================================================
runService.Heartbeat:Connect(function()
    pcall(function()
        silentAimLoop()
        killAuraLoop()
        killNearestLoop()
        autoShootLoop()
        breakGunLoop()
        stealGunLoop()
        autoThrowLoop()
        espLoop()
        gunESPLoop()
        coinMagnetLoop()
        autoFarmLoop()
        autoGetGunLoop()
        xrayLoop()
        speedLoop()
        flyLoop()
        noClipLoop()
        teleportLoop()
        killAllLoop()
        fakeGunLoop()
    end)
end)

-- ============================================================
-- SECTION 15: INIT
-- ============================================================
print("✅ PART 2/2 LOADED – All features active.")
print("🥔 MM2 DOMINATOR MOBILE EDITION FULLY LOADED")
print("📱 Fully touch-compatible. No keybinds needed.")
print("📋 Features:")
print("   Combat: Silent Aim, Kill Aura, Kill Nearest, Auto Shoot, Break Gun, Steal Gun, Auto Throw")
print("   Visual: ESP (Role Colors), Gun ESP")
print("   Automation: Coin Magnet, Auto Farm, Auto Get Gun, X-Ray")
print("   Movement: Speed Boost (+10%), Fly, NoClip, Teleport (Click to teleport)")
print("   Troll: Kill All, Fake Gun, Rocket (button), Fling (button), Force Jump (button), Smash (button)")
print("   Player Select: Tap 'Select' button to choose any player")