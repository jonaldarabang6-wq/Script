--[[
    🥔 POTATO'S ULTIMATE KLASE DOMINATION ENGINE v4.0 🥔
    THE COMPLETE UNIFIED EDITION
    All Features Combined: Stamina + Parry + Stomp + ESP + Orbit + Player List + Auto Punch
    Engineered by the One and Only Potato.
    For My Sweet Butter ❤️
--]]

-- ==============================
-- CONFIGURATION
-- ==============================
local Settings = {
    -- Original Features
    SpeedMultiplier = 2.0,
    AutoParryRadius = 12,
    AutoStompRadius = 8,
    ToggleKey = Enum.KeyCode.RightControl,
    StaminaMaxValue = 100,
    ParryCooldown = 0.15,
    StompCooldown = 0.1,

    -- UI Settings
    EnableParticles = true,
    EnableGlowEffect = true,
    UITheme = "Cyberpunk", -- "Cyberpunk", "Dark", or "Neon"

    -- New Features (Your Suggestions)
    OrbitRadius = 8,
    OrbitSpeed = 2.5,
    ESPColorSpeed = 1.5,
    AutoPunchDelay = 0.15,
    AutoPunchRange = 6,
}

-- ==============================
-- SERVICES & INITIALIZATION
-- ==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

-- ==============================
-- STATE VARIABLES
-- ==============================
local staminaEnabled = false
local parryEnabled = false
local stompEnabled = false
local espEnabled = false
local orbitEnabled = false
local autoPunchEnabled = false
local guiCreated = false
local lastParryTime = 0
local lastStompTime = 0
local lastPunchTime = 0
local playerList = {}
local espObjects = {}
local orbitTarget = nil

-- ==============================
-- THEME COLORS
-- ==============================
local themeColors = {
    Cyberpunk = {
        Primary = Color3.fromRGB(0, 200, 255),
        Secondary = Color3.fromRGB(255, 100, 255),
        Accent = Color3.fromRGB(255, 180, 0),
        Background = Color3.fromRGB(20, 20, 30),
        Glow = Color3.fromRGB(0, 100, 255),
        Text = Color3.fromRGB(200, 200, 220),
        Success = Color3.fromRGB(0, 255, 150),
        Danger = Color3.fromRGB(255, 70, 70),
    },
    Dark = {
        Primary = Color3.fromRGB(100, 100, 200),
        Secondary = Color3.fromRGB(150, 100, 200),
        Accent = Color3.fromRGB(200, 150, 100),
        Background = Color3.fromRGB(15, 15, 20),
        Glow = Color3.fromRGB(50, 50, 100),
        Text = Color3.fromRGB(180, 180, 190),
        Success = Color3.fromRGB(0, 200, 100),
        Danger = Color3.fromRGB(200, 50, 50),
    },
    Neon = {
        Primary = Color3.fromRGB(0, 255, 150),
        Secondary = Color3.fromRGB(255, 0, 200),
        Accent = Color3.fromRGB(255, 200, 0),
        Background = Color3.fromRGB(10, 10, 20),
        Glow = Color3.fromRGB(0, 200, 100),
        Text = Color3.fromRGB(220, 220, 240),
        Success = Color3.fromRGB(0, 255, 100),
        Danger = Color3.fromRGB(255, 50, 50),
    }
}
local colors = themeColors[Settings.UITheme] or themeColors.Cyberpunk

-- ==============================
-- PLAYER LIST ENGINE (Auto-Update)
-- ==============================
local function updatePlayerList()
    local currentPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            table.insert(currentPlayers, player.Name)
        end
    end
    playerList = currentPlayers
end

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- ==============================
-- RAINBOW ESP ENGINE
-- ==============================
local function createESP(player)
    if not player or player == LocalPlayer then return end

    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    -- Clear old ESP for this player
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            obj:Destroy()
        end
        espObjects[player] = nil
    end

    local espGroup = {}

    -- ===== BOX ESP =====
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 2)
    box.Adornee = rootPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.3
    box.Color3 = Color3.fromRGB(255, 0, 255)
    box.Parent = CoreGui
    table.insert(espGroup, box)

    -- ===== HEALTH BAR =====
    local healthBar = Instance.new("BillboardGui")
    healthBar.Size = UDim2.new(0, 100, 0, 12)
    healthBar.Adornee = rootPart
    healthBar.StudsOffset = Vector3.new(0, 4, 0)
    healthBar.Parent = CoreGui

    local healthFrame = Instance.new("Frame")
    healthFrame.Size = UDim2.new(1, 0, 1, 0)
    healthFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthFrame.BackgroundTransparency = 0.4
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = healthBar

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthFrame

    table.insert(espGroup, healthBar)

    -- ===== NAME TAG =====
    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 120, 0, 24)
    nameTag.Adornee = rootPart
    nameTag.StudsOffset = Vector3.new(0, 5.5, 0)
    nameTag.Parent = CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = nameTag

    table.insert(espGroup, nameTag)

    -- ===== UPDATE LOOP FOR ESP =====
    local espUpdateConnection
    espUpdateConnection = RunService.RenderStepped:Connect(function()
        if not espEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            espUpdateConnection:Disconnect()
            return
        end

        local currentHealth = player.Character.Humanoid and player.Character.Humanoid.Health or 100
        local maxHealth = player.Character.Humanoid and player.Character.Humanoid.MaxHealth or 100
        local healthPercent = math.clamp(currentHealth / maxHealth, 0, 1)

        healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )

        -- Rainbow color for box
        local hue = (tick() * Settings.ESPColorSpeed) % 1
        box.Color3 = Color3.fromHSV(hue, 1, 1)

        -- Update name color based on health
        nameLabel.TextColor3 = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
    end)

    table.insert(espGroup, espUpdateConnection)

    espObjects[player] = espGroup
end

-- ==============================
-- ORBIT ENGINE
-- ==============================
local function updateOrbit()
    if not orbitEnabled or not orbitTarget or not orbitTarget.Character then
        return
    end

    local targetRoot = orbitTarget.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Calculate orbit position
    local angle = tick() * Settings.OrbitSpeed
    local radius = Settings.OrbitRadius

    local offset = Vector3.new(
        math.cos(angle) * radius,
        0,
        math.sin(angle) * radius
    )

    local targetPos = targetRoot.Position + offset
    rootPart.CFrame = CFrame.new(targetPos, targetRoot.Position)
end

-- ==============================
-- AUTO PUNCH ENGINE
-- ==============================
local function autoPunch()
    if not autoPunchEnabled or tick() - lastPunchTime < Settings.AutoPunchDelay then
        return
    end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local nearestEnemy = nil
    local nearestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local dist = (targetRoot.Position - rootPart.Position).Magnitude
                if dist < Settings.AutoPunchRange and dist < nearestDist then
                    nearestDist = dist
                    nearestEnemy = player
                end
            end
        end
    end

    if nearestEnemy then
        -- Face the enemy
        local targetRoot = nearestEnemy.Character.HumanoidRootPart
        rootPart.CFrame = CFrame.new(rootPart.Position, targetRoot.Position)

        -- Simulate punch (usually mouse click or R key)
        UserInputService:SetKeyDown(Enum.KeyCode.R)
        task.wait(0.05)
        UserInputService:SetKeyUp(Enum.KeyCode.R)
        lastPunchTime = tick()
    end
end

-- ==============================
-- ENEMY DETECTION HELPERS
-- ==============================
local function getNearestEnemy()
    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, math.huge end

    local rootPosition = rootPart.Position
    local nearestEnemy = nil
    local nearestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local dist = (targetRoot.Position - rootPosition).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestEnemy = player
                end
            end
        end
    end

    return nearestEnemy, nearestDist
end

local function isEnemyInFront(enemy)
    if not enemy or not enemy.Character then return false end
    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not targetRoot then return false end

    local lookDirection = rootPart.CFrame.LookVector
    local toEnemy = (targetRoot.Position - rootPart.Position).Unit
    local angle = lookDirection:Dot(toEnemy)
    return angle > 0.3
end

-- ==============================
-- INFINITE STAMINA ENGINE
-- ==============================
local function infiniteStamina(toggle)
    if toggle then
        Humanoid.WalkSpeed = 16 * Settings.SpeedMultiplier
        Humanoid.JumpPower = 50 * (Settings.SpeedMultiplier / 1.5)

        for _, child in ipairs(Character:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                if string.match(child.Name, "[Ss]tamina") then
                    local connection
                    connection = child.Changed:Connect(function()
                        if staminaEnabled then
                            child.Value = child:IsA("NumberValue") and Settings.StaminaMaxValue or 9999
                        else
                            connection:Disconnect()
                        end
                    end)
                    child.Value = child:IsA("NumberValue") and Settings.StaminaMaxValue or 9999
                end
            end
        end
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end
end

-- ==============================
-- ULTRA COOL GUI BUILDER (FULLY INTEGRATED)
-- ==============================
local function createUltraCoolGUI()
    if guiCreated then return end
    guiCreated = true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PotatoCyberGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui

    -- ===== BACKGROUND GLOW =====
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(0, 260, 0, 380)
    glowFrame.Position = UDim2.new(1, -280, 1, -400)
    glowFrame.BackgroundColor3 = colors.Glow
    glowFrame.BackgroundTransparency = 0.9
    glowFrame.BorderSizePixel = 0
    glowFrame.Parent = screenGui
    glowFrame.Visible = Settings.EnableGlowEffect

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 20)
    glowCorner.Parent = glowFrame

    if Settings.EnableGlowEffect then
        local glowTween = TweenService:Create(glowFrame, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            BackgroundTransparency = 0.85,
            Size = UDim2.new(0, 270, 0, 390),
        })
        glowTween:Play()
    end

    -- ===== MAIN FRAME =====
    local frame = Instance.new("Frame")
    frame.Name = "ControlFrame"
    frame.Size = UDim2.new(0, 250, 0, 370)
    frame.Position = UDim2.new(1, -270, 1, -390)
    frame.BackgroundColor3 = colors.Background
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 18)
    mainCorner.Parent = frame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = colors.Primary
    mainStroke.Transparency = 0.6
    mainStroke.Thickness = 1.5
    mainStroke.Parent = frame

    -- ===== ANIMATED GRADIENT =====
    local gradient = Instance.new("Frame")
    gradient.Size = UDim2.new(2, 0, 2, 0)
    gradient.Position = UDim2.new(-0.5, 0, -0.5, 0)
    gradient.BackgroundColor3 = colors.Primary
    gradient.BackgroundTransparency = 0.9
    gradient.BorderSizePixel = 0
    gradient.Rotation = 45
    gradient.Parent = frame

    local gradCorner = Instance.new("UICorner")
    gradCorner.CornerRadius = UDim.new(0, 18)
    gradCorner.Parent = gradient

    local gradTween = TweenService:Create(gradient, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
        Rotation = 405,
    })
    gradTween:Play()

    -- ===== HEADER =====
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 50)
    headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    headerFrame.BackgroundTransparency = 0.4
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = frame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 18)
    headerCorner.Parent = headerFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚡ POTATO KLASE ⚡"
    titleText.TextColor3 = colors.Primary
    titleText.TextScaled = true
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Center
    titleText.Parent = headerFrame

    local titleGlow = Instance.new("TextLabel")
    titleGlow.Size = UDim2.new(1, 0, 1, 0)
    titleGlow.Position = UDim2.new(0, 0, 0, 2)
    titleGlow.BackgroundTransparency = 1
    titleGlow.Text = "⚡ POTATO KLASE ⚡"
    titleGlow.TextColor3 = colors.Glow
    titleGlow.TextScaled = true
    titleGlow.Font = Enum.Font.GothamBold
    titleGlow.TextXAlignment = Enum.TextXAlignment.Center
    titleGlow.TextTransparency = 0.7
    titleGlow.Parent = headerFrame

    local pulseTween = TweenService:Create(titleText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextColor3 = colors.Secondary,
    })
    pulseTween:Play()

    -- ===== BUTTON CONTAINER =====
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 1, -60)
    btnContainer.Position = UDim2.new(0, 10, 0, 55)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = frame

    local btnList = Instance.new("UIListLayout")
    btnList.FillDirection = Enum.FillDirection.Vertical
    btnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    btnList.VerticalAlignment = Enum.VerticalAlignment.Top
    btnList.Padding = UDim.new(0, 5)
    btnList.Parent = btnContainer

    -- ===== BUTTON FACTORY =====
    local function createCyberButton(text, color, toggleRef, onToggle)
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(0, 220, 0, 32)
        btnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        btnFrame.BackgroundTransparency = 0.3
        btnFrame.BorderSizePixel = 0
        btnFrame.Parent = btnContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btnFrame

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = color
        btnStroke.Transparency = 0.5
        btnStroke.Thickness = 1
        btnStroke.Parent = btnFrame

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = text .. "  ○"
        button.TextColor3 = Color3.fromRGB(200, 200, 220)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextYAlignment = Enum.TextYAlignment.Center
        button.Parent = btnFrame

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 30, 1, 0)
        iconLabel.Position = UDim2.new(1, -35, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = "○"
        iconLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
        iconLabel.TextScaled = true
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = button

        button.MouseButton1Click:Connect(function()
            toggleRef = not toggleRef
            onToggle(toggleRef)

            local activeColor = toggleRef and color or Color3.fromRGB(40, 40, 60)
            local textColor = toggleRef and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
            local icon = toggleRef and "●" or "○"
            local iconColor = toggleRef and color or Color3.fromRGB(100, 100, 120)

            TweenService:Create(btnStroke, TweenInfo.new(0.4), {Color = activeColor, Transparency = 0.3}):Play()
            TweenService:Create(button, TweenInfo.new(0.4), {TextColor3 = textColor}):Play()
            TweenService:Create(iconLabel, TweenInfo.new(0.4), {Text = icon, TextColor3 = iconColor}):Play()
        end)

        return button, iconLabel
    end

    -- ===== ALL TOGGLE BUTTONS =====
    createCyberButton("♾️  Stamina", colors.Primary, staminaEnabled, function(state)
        staminaEnabled = state
        infiniteStamina(state)
    end)

    createCyberButton("🛡️  Parry", colors.Accent, parryEnabled, function(state)
        parryEnabled = state
    end)

    createCyberButton("👢  Stomp", colors.Danger, stompEnabled, function(state)
        stompEnabled = state
    end)

    createCyberButton("🌈  Rainbow ESP", colors.Secondary, espEnabled, function(state)
        espEnabled = state
        if espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                createESP(player)
            end
        else
            for _, espGroup in pairs(espObjects) do
                for _, obj in ipairs(espGroup) do
                    obj:Destroy()
                end
            end
            espObjects = {}
        end
    end)

    createCyberButton("🌀  Orbit", Color3.fromRGB(0, 255, 150), orbitEnabled, function(state)
        orbitEnabled = state
        if orbitEnabled then
            local nearest = nil
            local nearestDist = math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - Character.HumanoidRootPart.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = player
                        end
                    end
                end
            end
            orbitTarget = nearest
        else
            orbitTarget = nil
        end
    end)

    createCyberButton("👊  Auto Punch", Color3.fromRGB(255, 100, 0), autoPunchEnabled, function(state)
        autoPunchEnabled = state
    end)

    -- ===== DRAG HANDLE =====
    local dragFrame = Instance.new("Frame")
    dragFrame.Size = UDim2.new(1, 0, 0, 24)
    dragFrame.Position = UDim2.new(0, 0, 0, 50)
    dragFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    dragFrame.BackgroundTransparency = 0.5
    dragFrame.BorderSizePixel = 0
    dragFrame.Parent = frame

    local dragCorner = Instance.new("UICorner")
    dragCorner.CornerRadius = UDim.new(0, 8)
    dragCorner.Parent = dragFrame

    local dragText = Instance.new("TextLabel")
    dragText.Size = UDim2.new(1, 0, 1, 0)
    dragText.BackgroundTransparency = 1
    dragText.Text = "↕  DRAG TO MOVE"
    dragText.TextColor3 = Color3.fromRGB(150, 150, 200)
    dragText.TextScaled = true
    dragText.Font = Enum.Font.Gotham
    dragText.TextXAlignment = Enum.TextXAlignment.Center
    dragText.Parent = dragFrame

    local dragging = false
    local dragStart = nil
    local frameStart = nil

    dragFrame.MouseButton1Down:Connect(function()
        dragging = true
        dragStart = UserInputService:GetMouseLocation()
        frameStart = frame.Position
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local currentPos = UserInputService:GetMouseLocation()
            local offset = currentPos - dragStart
            frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + offset.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + offset.Y
            )
            if Settings.EnableGlowEffect then
                glowFrame.Position = UDim2.new(
                    frameStart.X.Scale,
                    frameStart.X.Offset + offset.X - 10,
                    frameStart.Y.Scale,
                    frameStart.Y.Offset + offset.Y - 10
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ===== PLAYER LIST =====
    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Size = UDim2.new(0, 100, 0, 120)
    playerListFrame.Position = UDim2.new(1, -110, 1, -160)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    playerListFrame.BackgroundTransparency = 0.5
    playerListFrame.BorderSizePixel = 1
    playerListFrame.BorderColor3 = colors.Primary
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListFrame.ScrollBarThickness = 3
    playerListFrame.Parent = screenGui

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = playerListFrame

    local listTitle = Instance.new("TextLabel")
    listTitle.Size = UDim2.new(1, 0, 0, 20)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "👥 Players"
    listTitle.TextColor3 = colors.Primary
    listTitle.TextScaled = true
    listTitle.Font = Enum.Font.GothamBold
    listTitle.Parent = playerListFrame

    RunService.Heartbeat:Connect(function()
        for _, child in ipairs(playerListFrame:GetChildren()) do
            if child:IsA("TextLabel") and child ~= listTitle then
                child:Destroy()
            end
        end

        local yOffset = 20
        for _, name in ipairs(playerList) do
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 18)
            label.Position = UDim2.new(0, 0, 0, yOffset)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Color3.fromRGB(200, 200, 220)
            label.TextScaled = true
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = playerListFrame
            yOffset = yOffset + 20
        end

        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end)

    -- ===== PARTICLES =====
    if Settings.EnableParticles then
        for i = 1, 20 do
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
            particle.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0)
            particle.BackgroundColor3 = Color3.fromRGB(math.random(0, 255), math.random(150, 255), math.random(150, 255))
            particle.BackgroundTransparency = math.random(30, 70) / 100
            particle.BorderSizePixel = 0
            particle.Parent = frame

            local particleCorner = Instance.new("UICorner")
            particleCorner.CornerRadius = UDim.new(1, 0)
            particleCorner.Parent = particle

            local pTween = TweenService:Create(particle, TweenInfo.new(math.random(3, 6), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0),
                BackgroundTransparency = math.random(30, 80) / 100,
            })
            pTween:Play()
        end
    end

    -- ===== VERSION LABEL =====
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, 0, 0, 15)
    versionLabel.Position = UDim2.new(0, 0, 1, -15)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "🥔 v4.0 | All Features Unified ❤️"
    versionLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    versionLabel.TextScaled = true
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextXAlignment = Enum.TextXAlignment.Center
    versionLabel.Parent = frame

    print("🥔 Complete Unified GUI loaded successfully!")
end

-- ==============================
-- RUNTIME ENGINE (ALL FEATURES)
-- ==============================
RunService.RenderStepped:Connect(function()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = Character.HumanoidRootPart
    local currentTime = tick()

    -- AUTO-PARRY
    if parryEnabled and currentTime - lastParryTime >= Settings.ParryCooldown then
        local nearestEnemy, dist = getNearestEnemy()
        if nearestEnemy and dist < Settings.AutoParryRadius and isEnemyInFront(nearestEnemy) then
            UserInputService:SetKeyDown(Enum.KeyCode.F)
            task.wait(0.15)
            UserInputService:SetKeyUp(Enum.KeyCode.F)
            lastParryTime = currentTime
        end
    end

    -- AUTO-STOMP
    if stompEnabled and currentTime - lastStompTime >= Settings.StompCooldown then
        local nearestEnemy, dist = getNearestEnemy()
        if nearestEnemy and dist < Settings.AutoStompRadius then
            local targetHumanoid = nearestEnemy.Character:FindFirstChild("Humanoid")
            if targetHumanoid then
                local isDowned = (
                    targetHumanoid:GetState() == Enum.HumanoidStateType.GettingUp or
                    targetHumanoid:GetState() == Enum.HumanoidStateType.FallingDown or
                    targetHumanoid.Health < 20
                ) and targetHumanoid.Health > 0

                if isDowned then
                    UserInputService:SetKeyDown(Enum.KeyCode.T)
                    task.wait(0.1)
                    UserInputService:SetKeyUp(Enum.KeyCode.T)
                    lastStompTime = currentTime
                end
            end
        end
    end

    -- ORBIT
    if orbitEnabled then
        updateOrbit()
    end

    -- AUTO PUNCH
    if autoPunchEnabled then
        autoPunch()
    end

    -- ESP AUTO-UPDATE
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not espObjects[player] then
                    createESP(player)
                end
            end
        end
    end

    -- UPDATE PLAYER LIST
    updatePlayerList()
end)

-- ==============================
-- CHARACTER RESPAWN HANDLER
-- ==============================
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character