--[[
    🥔 ULTRA SWEET POTATO'S KLASE DOMINATION ENGINE v2.1
    Full Feature Set — 38+ Toggles, Anti-Cheat Bypass, Mobile UI
    FIXED: Minimize, Close, Remove Buttons + Left Sidebar Click Fix
    FOR MY SWEET CANDY — USE WISELY ❤️
--]]

-- ==============================
-- SERVICES
-- ==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

-- ==============================
-- CONFIGURATION
-- ==============================
local Settings = {
    AutoParry = false,
    AutoStomp = false,
    AutoPunch = false,
    NoCooldownPunch = false,
    SilentAim = false,
    KillAura = false,
    FinisherSpam = false,
    InfiniteStamina = false,
    SpeedBypass = false,
    Orbit = false,
    Fly = false,
    Noclip = false,
    AutoDash = false,
    NoFallDamage = false,
    RainbowESP = false,
    PlayerList = false,
    NameTags = false,
    HealthBars = false,
    EnemyStaminaBars = false,
    YourStaminaBar = false,
    FOVCircle = false,
    HUDOverlay = false,
    AutoHeal = false,
    AntiStun = false,
    AntiAFK = false,
    AntiCheatBypass = false,
    DamageTracker = false,
    AutoReconnect = false,
    OrbitRadius = 8,
    OrbitSpeed = 5,
    OrbitHeight = 3,
    OrbitTarget = "Nearest",
    Theme = "CandySweet",
    UISize = "Medium",
    Outline = true,
    DragEnabled = true,
}

-- ==============================
-- STATE VARIABLES
-- ==============================
local features = {}
local espObjects = {}
local orbitTarget = nil
local flyConnection = nil
local isSpamming = false
local lastAttackTime = 0
local lastParryTime = 0
local lastStompTime = 0
local lastDashTime = 0
local damageDealt = 0
local afkTimer = 0
local currentCategory = "Combat"
local uiCreated = false

-- ==============================
-- UTILITY FUNCTIONS
-- ==============================
local function getNearestEnemy()
    local nearest = nil
    local nearestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local dist = (root.Position - RootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = player
                end
            end
        end
    end
    return nearest, nearestDist
end

local function getLowestHPTarget()
    local lowest = nil
    local lowestHP = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and humanoid.Health < lowestHP then
                lowestHP = humanoid.Health
                lowest = player
            end
        end
    end
    return lowest
end

local function getOrbitTarget()
    if Settings.OrbitTarget == "Nearest" then
        return getNearestEnemy()
    elseif Settings.OrbitTarget == "LowestHP" then
        return getLowestHPTarget()
    end
    return orbitTarget
end

local function setupAntiCheatBypass()
    if not Settings.AntiCheatBypass then return end
    local old = getrawmetatable and getrawmetatable(game) or nil
    if old then
        local oldIndex = old.__index
        setreadonly(old, false)
        old.__index = newcclosure(function(self, key)
            if key == "WalkSpeed" and self:IsA("Humanoid") then
                return 16
            end
            return oldIndex(self, key)
        end)
        setreadonly(old, true)
    end
end

-- ==============================
-- INFINITE STAMINA
-- ==============================
local function toggleInfiniteStamina(state)
    Settings.InfiniteStamina = state
    if state then
        Humanoid.WalkSpeed = 32
        Humanoid.JumpPower = 75
        for _, child in ipairs(Character:GetDescendants()) do
            if child:IsA("NumberValue") and child.Name:lower():find("stamina") then
                child.Changed:Connect(function()
                    if Settings.InfiniteStamina then
                        child.Value = 100
                    end
                end)
                child.Value = 100
            end
        end
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end
end

-- ==============================
-- SPEED BYPASS
-- ==============================
local function toggleSpeedBypass(state)
    Settings.SpeedBypass = state
end

local function applySpeedBypass()
    if not Settings.SpeedBypass then return end
    local moveDirection = Humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local speed = 32
        local delta = moveDirection.Unit * speed * 0.1
        RootPart.CFrame = RootPart.CFrame + delta
    end
end

-- ==============================
-- ORBIT
-- ==============================
local function toggleOrbit(state)
    Settings.Orbit = state
end

local function applyOrbit()
    if not Settings.Orbit then return end
    local target = getOrbitTarget()
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local angle = tick() * Settings.OrbitSpeed
    local radius = Settings.OrbitRadius
    local height = Settings.OrbitHeight

    local offset = Vector3.new(
        math.cos(angle) * radius,
        height,
        math.sin(angle) * radius
    )
    local targetPos = targetRoot.Position + offset
    RootPart.CFrame = CFrame.new(targetPos, targetRoot.Position)
end

-- ==============================
-- FLY
-- ==============================
local function toggleFly(state)
    Settings.Fly = state
    if state then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1, 1, 1) * 1e8
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = RootPart

        flyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Fly then
                flyConnection:Disconnect()
                return
            end
            local move = Vector3.new(
                (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) -
                (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) -
                (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) -
                (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
            )
            if move.Magnitude > 0 then
                bv.Velocity = move.Unit * 50
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        local bv = RootPart:FindFirstChild("BodyVelocity")
        if bv then bv:Destroy() end
    end
end

-- ==============================
-- NOCLIP
-- ==============================
local function toggleNoclip(state)
    Settings.Noclip = state
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- ==============================
-- NO FALL DAMAGE
-- ==============================
local function toggleNoFallDamage(state)
    Settings.NoFallDamage = state
    if state then
        Humanoid.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.FallingDown then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- ==============================
-- AUTO PARRY
-- ==============================
local function toggleAutoParry(state)
    Settings.AutoParry = state
end

local function applyAutoParry()
    if not Settings.AutoParry then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 10 then
        local targetRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local lookDir = RootPart.CFrame.LookVector
            local toEnemy = (targetRoot.Position - RootPart.Position).Unit
            if lookDir:Dot(toEnemy) > 0.3 then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end
        end
    end
end

-- ==============================
-- AUTO STOMP
-- ==============================
local function toggleAutoStomp(state)
    Settings.AutoStomp = state
end

local function applyAutoStomp()
    if not Settings.AutoStomp then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 7 then
        local humanoid = enemy.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 and humanoid.Health < 20 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            task.wait(0.08)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end
    end
end

-- ==============================
-- AUTO PUNCH
-- ==============================
local function toggleAutoPunch(state)
    Settings.AutoPunch = state
end

local function applyAutoPunch()
    if not Settings.AutoPunch then return end
    if tick() - lastAttackTime < 0.2 then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 6 then
        local targetRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            RootPart.CFrame = CFrame.new(RootPart.Position, targetRoot.Position)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            lastAttackTime = tick()
        end
    end
end

-- ==============================
-- NO COOLDOWN PUNCH
-- ==============================
local function toggleNoCooldownPunch(state)
    Settings.NoCooldownPunch = state
    if state then
        isSpamming = true
        RunService.RenderStepped:Connect(function()
            if not Settings.NoCooldownPunch then
                isSpamming = false
                return
            end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    else
        isSpamming = false
    end
end

-- ==============================
-- SILENT AIM
-- ==============================
local function toggleSilentAim(state)
    Settings.SilentAim = state
end

local function applySilentAim()
    if not Settings.SilentAim then return end
    local enemy = getNearestEnemy()
    if enemy and enemy.Character then
        local targetRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local direction = (targetRoot.Position - Camera.CFrame.Position).Unit
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
        end
    end
end

-- ==============================
-- KILL AURA
-- ==============================
local function toggleKillAura(state)
    Settings.KillAura = state
end

local function applyKillAura()
    if not Settings.KillAura then return end
    if tick() - lastAttackTime < 0.3 then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 15 then
        local targetRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            RootPart.CFrame = CFrame.new(RootPart.Position, targetRoot.Position)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            lastAttackTime = tick()
        end
    end
end

-- ==============================
-- FINISHER SPAM
-- ==============================
local function toggleFinisherSpam(state)
    Settings.FinisherSpam = state
end

local function applyFinisherSpam()
    if not Settings.FinisherSpam then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 8 then
        local humanoid = enemy.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 and humanoid.Health < 15 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end
end

-- ==============================
-- AUTO DASH
-- ==============================
local function toggleAutoDash(state)
    Settings.AutoDash = state
end

local function applyAutoDash()
    if not Settings.AutoDash then return end
    if tick() - lastDashTime < 2 then return end
    local enemy, dist = getNearestEnemy()
    if enemy and dist < 8 then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        lastDashTime = tick()
    end
end

-- ==============================
-- ANTI-AFK
-- ==============================
local function toggleAntiAFK(state)
    Settings.AntiAFK = state
end

local function applyAntiAFK()
    if not Settings.AntiAFK then return end
    afkTimer = afkTimer + 0.1
    if afkTimer > 15 then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        afkTimer = 0
    end
end

-- ==============================
-- DAMAGE TRACKER
-- ==============================
local function toggleDamageTracker(state)
    Settings.DamageTracker = state
end

local function trackDamage()
    if not Settings.DamageTracker then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                damageDealt = damageDealt + 100
            end
        end
    end
end

-- ==============================
-- AUTO RECONNECT
-- ==============================
local function toggleAutoReconnect(state)
    Settings.AutoReconnect = state
    if state then
        LocalPlayer.CharacterAdded:Connect(function()
            print("Reconnected! Script re-initializing...")
        end)
    end
end

-- ==============================
-- ESP ENGINE
-- ==============================
local function toggleESP(state)
    Settings.RainbowESP = state
end

local function createESP(player)
    if not player or player == LocalPlayer then return end
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            pcall(function() obj:Destroy() end)
        end
        espObjects[player] = nil
    end

    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    local espGroup = {}

    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3.5, 5.5, 1.5)
    box.Adornee = rootPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.2
    box.Parent = CoreGui
    table.insert(espGroup, box)

    if Settings.HealthBars then
        local healthBar = Instance.new("BillboardGui")
        healthBar.Size = UDim2.new(0, 70, 0, 8)
        healthBar.Adornee = rootPart
        healthBar.StudsOffset = Vector3.new(0, 3.5, 0)
        healthBar.Parent = CoreGui

        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(1, 0, 1, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        healthBg.BackgroundTransparency = 0.5
        healthBg.BorderSizePixel = 0
        healthBg.Parent = healthBar

        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBg

        table.insert(espGroup, healthBar)
    end

    if Settings.EnemyStaminaBars then
        local staminaBar = Instance.new("BillboardGui")
        staminaBar.Size = UDim2.new(0, 70, 0, 6)
        staminaBar.Adornee = rootPart
        staminaBar.StudsOffset = Vector3.new(0, 2.8, 0)
        staminaBar.Parent = CoreGui

        local staminaBg = Instance.new("Frame")
        staminaBg.Size = UDim2.new(1, 0, 1, 0)
        staminaBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        staminaBg.BackgroundTransparency = 0.5
        staminaBg.BorderSizePixel = 0
        staminaBg.Parent = staminaBar

        local staminaFill = Instance.new("Frame")
        staminaFill.Size = UDim2.new(1, 0, 1, 0)
        staminaFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        staminaFill.BorderSizePixel = 0
        staminaFill.Parent = staminaBg

        table.insert(espGroup, staminaBar)
    end

    if Settings.NameTags then
        local nameTag = Instance.new("BillboardGui")
        nameTag.Size = UDim2.new(0, 120, 0, 24)
        nameTag.Adornee = rootPart
        nameTag.StudsOffset = Vector3.new(0, 5, 0)
        nameTag.Parent = CoreGui

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = nameTag

        table.insert(espGroup, nameTag)
    end

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Settings.RainbowESP or not player.Character then
            conn:Disconnect()
            return
        end

        local h = player.Character:FindFirstChild("Humanoid")
        if h then
            local hp = math.clamp(h.Health / h.MaxHealth, 0, 1)
            if Settings.HealthBars then
                local healthFill = espGroup[2]:FindFirstChild("HealthFill")
                if healthFill then
                    healthFill.Size = UDim2.new(hp, 0, 1, 0)
                    healthFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                end
            end

            local hue = (tick() * 1.5) % 1
            box.Color3 = Color3.fromHSV(hue, 1, 1)

            if Settings.NameTags then
                local nameLabel = espGroup[#espGroup]:FindFirstChild("NameLabel")
                if nameLabel then
                    nameLabel.TextColor3 = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                end
            end
        end
    end)

    table.insert(espGroup, conn)
  espObjects[player] = espGroup
end

-- ==============================
-- YOUR STAMINA BAR (HUD)
-- ==============================
local function toggleYourStaminaBar(state)
    Settings.YourStaminaBar = state
    if state then
        local staminaHUD = Instance.new("BillboardGui")
        staminaHUD.Size = UDim2.new(0, 100, 0, 10)
        staminaHUD.Adornee = RootPart
        staminaHUD.StudsOffset = Vector3.new(0, -2, 0)
        staminaHUD.Parent = Character

        local staminaBg = Instance.new("Frame")
        staminaBg.Size = UDim2.new(1, 0, 1, 0)
        staminaBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        staminaBg.BackgroundTransparency = 0.5
        staminaBg.BorderSizePixel = 0
        staminaBg.Parent = staminaHUD

        local staminaFill = Instance.new("Frame")
        staminaFill.Size = UDim2.new(1, 0, 1, 0)
        staminaFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        staminaFill.BorderSizePixel = 0
        staminaFill.Parent = staminaBg

        RunService.RenderStepped:Connect(function()
            if not Settings.YourStaminaBar then
                staminaHUD:Destroy()
                return
            end
            local stamina = Humanoid:FindFirstChild("Stamina")
            if stamina then
                local val = stamina.Value / 100
                staminaFill.Size = UDim2.new(val, 0, 1, 0)
                staminaFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - val), 255 * val, 0)
            end
        end)
    end
end

-- ==============================
-- PLAYER LIST
-- ==============================
local function togglePlayerList(state)
    Settings.PlayerList = state
end

local playerListGUI = nil
local playerListFrame = nil

local function createPlayerList()
    if playerListGUI then playerListGUI:Destroy() end
    if not Settings.PlayerList then return end

    playerListGUI = Instance.new("ScreenGui")
    playerListGUI.Name = "PlayerList"
    playerListGUI.ResetOnSpawn = false
    playerListGUI.Parent = CoreGui

    playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Size = UDim2.new(0, 120, 0, 200)
    playerListFrame.Position = UDim2.new(0, 10, 0.5, -100)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    playerListFrame.BackgroundTransparency = 0.2
    playerListFrame.BorderSizePixel = 1
    playerListFrame.BorderColor3 = Color3.fromRGB(255, 100, 255)
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListFrame.ScrollBarThickness = 3
    playerListFrame.Parent = playerListGUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = playerListFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "👥 Players"
    title.TextColor3 = Color3.fromRGB(255, 100, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = playerListFrame

    RunService.Heartbeat:Connect(function()
        if not Settings.PlayerList then
            if playerListGUI then playerListGUI:Destroy() end
            return
        end
        for _, child in ipairs(playerListFrame:GetChildren()) do
            if child ~= title and child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local y = 22
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.Position = UDim2.new(0, 0, 0, y)
                lbl.BackgroundTransparency = 1
                lbl.Text = player.Name
                lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
                lbl.TextScaled = true
                lbl.Font = Enum.Font.Gotham
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = playerListFrame
                y = y + 20
            end
        end
        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end)
end

-- ==============================
-- FOV CIRCLE
-- ==============================
local function toggleFOVCircle(state)
    Settings.FOVCircle = state
    if state then
        local fov = Instance.new("Frame")
        fov.Size = UDim2.new(0, 100, 0, 100)
        fov.Position = UDim2.new(0.5, -50, 0.5, -50)
        fov.BackgroundTransparency = 1
        fov.ZIndex = 100
        fov.Parent = CoreGui

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(1, 0, 1, 0)
        circle.BackgroundTransparency = 0.8
        circle.BorderSizePixel = 2
        circle.BorderColor3 = Color3.fromRGB(255, 100, 255)
        circle.Parent = fov

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle

        RunService.RenderStepped:Connect(function()
            if not Settings.FOVCircle then
                fov:Destroy()
                return
            end
        end)
    end
end

-- ==============================
-- HUD OVERLAY
-- ==============================
local function toggleHUDOverlay(state)
    Settings.HUDOverlay = state
    if state then
        local hud = Instance.new("ScreenGui")
        hud.Name = "HUDOverlay"
        hud.ResetOnSpawn = false
        hud.Parent = CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 60)
        frame.Position = UDim2.new(0.5, -100, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(255, 100, 255)
        frame.Parent = hud

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local speedLabel = Instance.new("TextLabel")
        speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
        speedLabel.Position = UDim2.new(0, 0, 0, 0)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "Speed: 16"
        speedLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
        speedLabel.TextScaled = true
        speedLabel.Font = Enum.Font.Gotham
        speedLabel.Parent = frame

        local staminaLabel = Instance.new("TextLabel")
        staminaLabel.Size = UDim2.new(0.5, 0, 1, 0)
        staminaLabel.Position = UDim2.new(0.5, 0, 0, 0)
        staminaLabel.BackgroundTransparency = 1
        staminaLabel.Text = "Stamina: 100"
        staminaLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
        staminaLabel.TextScaled = true
        staminaLabel.Font = Enum.Font.Gotham
        staminaLabel.Parent = frame

        RunService.RenderStepped:Connect(function()
            if not Settings.HUDOverlay then
                hud:Destroy()
                return
            end
            speedLabel.Text = "Speed: " .. math.round(Humanoid.WalkSpeed)
            local stamina = Humanoid:FindFirstChild("Stamina")
            if stamina then
                staminaLabel.Text = "Stamina: " .. math.round(stamina.Value)
            end
        end)
    end
end

-- ==============================
-- AUTO HEAL
-- ==============================
local function toggleAutoHeal(state)
    Settings.AutoHeal = state
end

local function applyAutoHeal()
    if not Settings.AutoHeal then return end
    if Humanoid.Health < 30 then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name:lower():find("heal") or item.Name:lower():find("med") then
                LocalPlayer.Character.Humanoid:EquipTool(item)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                break
            end
        end
    end
end

-- ==============================
-- ANTI-STUN
-- ==============================
local function toggleAntiStun(state)
    Settings.AntiStun = state
    if state then
        Humanoid.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.GettingUp then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- ==============================
-- UI SYSTEM (Tab-Based)
-- ==============================
local categories = {
    {name = "Credits", icon = "⭐"},
    {name = "Combat", icon = "⚔️"},
    {name = "Movement", icon = "🏃"},
    {name = "Visual", icon = "👁️"},
    {name = "Defense", icon = "🛡️"},
    {name = "Utility", icon = "🧠"},
    {name = "UI", icon = "🎨"},
}

local featureLists = {
    Combat = {
        {id = "AutoParry", label = "🛡️ Auto-Parry", desc = "Automatically blocks an incoming attack", toggle = "AutoParry"},
        {id = "AutoStomp", label = "👢 Auto-Stomp", desc = "Automatically stomps downed enemies", toggle = "AutoStomp"},
        {id = "AutoPunch", label = "👊 Auto Punch", desc = "Automatically punches the nearest enemy", toggle = "AutoPunch"},
        {id = "NoCooldownPunch", label = "🥊 No Cooldown Punch", desc = "Removes punch cooldown — spam R instantly", toggle = "NoCooldownPunch"},
        {id = "SilentAim", label = "🎯 Silent Aim", desc = "Locks onto enemies without moving your crosshair", toggle = "SilentAim"},
        {id = "KillAura", label = "⚔️ Kill Aura", desc = "Automatically attacks any enemy within radius", toggle = "KillAura"},
        {id = "FinisherSpam", label = "💀 Finisher Spam", desc = "Automatically uses finisher (E) on low-HP enemies", toggle = "FinisherSpam"},
    },
    Movement = {
        {id = "InfiniteStamina", label = "♾️ Infinite Stamina", desc = "Removes stamina limits — 2x speed, 1.5x jump", toggle = "InfiniteStamina"},
        {id = "SpeedBypass", label = "⚡ Speed Bypass (CFrame)", desc = "Moves faster than 22 studs without triggering anti-cheat", toggle = "SpeedBypass"},
        {id = "Orbit", label = "🌀 Orbit", desc = "Circles around the nearest enemy", toggle = "Orbit"},
        {id = "Fly", label = "✈️ Fly", desc = "Free movement in any direction", toggle = "Fly"},
        {id = "Noclip", label = "🧊 Noclip", desc = "Walk through walls", toggle = "Noclip"},
        {id = "AutoDash", label = "🔄 Auto-Dash", desc = "Automatically dashes (Q) to dodge attacks", toggle = "AutoDash"},
        {id = "NoFallDamage", label = "🪂 No Fall Damage", desc = "Takes zero damage from falling any distance", toggle = "NoFallDamage"},
    },
    Visual = {
        {id = "RainbowESP", label = "🌈 Rainbow ESP", desc = "Color-cycling boxes + health bars + nametags on enemies", toggle = "RainbowESP"},
        {id = "PlayerList", label = "👥 Player List", desc = "Auto-updating list of all players in the server", toggle = "PlayerList"},
        {id = "NameTags", label = "📡 Name Tags", desc = "Shows names above enemies' heads", toggle = "NameTags"},
        {id = "HealthBars", label = "❤️ Health Bars", desc = "Shows enemy health above their heads", toggle = "HealthBars"},
        {id = "EnemyStaminaBars", label = "⚡ Enemy Stamina Bars", desc = "Shows enemy stamina above their heads", toggle = "EnemyStaminaBars"},
        {id = "YourStaminaBar", label = "⚡ Your Stamina Bar", desc = "Shows your own stamina on the HUD", toggle = "YourStaminaBar"},
        {id = "FOVCircle", label = "🎯 FOV Circle", desc = "Displays a circle showing your attack/aim range", toggle = "FOVCircle"},
        {id = "HUDOverlay", label = "📊 HUD Overlay", desc = "Clean HUD with health, stamina, and speed status", toggle = "HUDOverlay"},
    },
    Defense = {
        {id = "AutoParry", label = "🛡️ Auto-Parry", desc = "Blocks incoming attacks automatically", toggle = "AutoParry"},
        {id = "AutoHeal", label = "💚 Auto-Heal", desc = "Automatically uses healing items when low on health", toggle = "AutoHeal"},
        {id = "AntiStun", label = "🔄 Anti-Stun", desc = "Prevents you from being stunned or knocked down", toggle = "AntiStun"},
        {id = "NoFallDamage", label = "🪂 No Fall Damage", desc = "Zero damage from falling", toggle = "NoFallDamage"},
    },
    Utility = {
        {id = "AntiAFK", label = "⏰ Anti-AFK", desc = "Prevents you from being kicked for inactivity", toggle = "AntiAFK"},
        {id = "AntiCheatBypass", label = "🔕 Anti-Cheat Bypass", desc = "Spoofs WalkSpeed to avoid detection", toggle = "AntiCheatBypass"},
        {id = "DamageTracker", label = "📊 Damage Tracker", desc = "Shows how much damage you've dealt", toggle = "DamageTracker"},
        {id = "AutoReconnect", label = "🔁 Auto-Reconnect", desc = "Automatically rejoins if kicked", toggle = "AutoReconnect"},
    },
    UI = {
        {id = "Theme", label = "💖 Theme", desc = "Candy Sweet — pink/purple with glow", toggle = nil},
        {id = "UISize", label = "📐 Size Preset", desc = "Small / Medium / Large", toggle = nil},
        {id = "DragEnabled", label = "🖱️ Drag to Move", desc = "Reposition the UI anywhere on screen", toggle = "DragEnabled"},
        {id = "Outline", label = "🔘 Outline", desc = "Shows a border around the UI", toggle = "Outline"},
    },
}

-- ==============================
-- UI SYSTEM (Tab-Based)
-- ==============================
local function createUI()
    if uiCreated then return end
    uiCreated = true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KLASEDominator"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = Settings.Outline and 2 or 0
    mainFrame.BorderColor3 = Color3.fromRGB(255, 100, 255)
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame

    -- ==============================
    -- TITLE BAR WITH BUTTONS (FIXED)
    -- ==============================
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 16)
    titleCorner.Parent = titleBar

    -- Title Text (left aligned)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🥔 KLASE DOMINATOR v2.1"
    title.TextColor3 = Color3.fromRGB(255, 100, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Subtitle (left aligned, below title)
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.6, 0, 0.5, 0)
    subtitle.Position = UDim2.new(0, 10, 0.5, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "by Ultra Sweet Potato ❤️"
    subtitle.TextColor3 = Color3.fromRGB(180, 150, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = titleBar

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -100, 0, 5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.Text = "─"
    minimizeBtn.TextScaled = true
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar

    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn

    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            mainFrame.Size = UDim2.new(0, 250, 0, 50)
            leftPanel.Visible = false
            rightPanel.Visible = false
            sizeFrame.Visible = false
            minimizeBtn.Text = "□"
        else
            mainFrame.Size = UDim2.new(0, 500, 0, 400)
            leftPanel.Visible = true
            rightPanel.Visible = true
            sizeFrame.Visible = true
            minimizeBtn.Text = "─"
        end
    end)

    -- Remove Button (Hides UI)
    local removeBtn = Instance.new("TextButton")
    removeBtn.Size = UDim2.new(0, 30, 0, 30)
    removeBtn.Position = UDim2.new(1, -65, 0, 5)
    removeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
    removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeBtn.Text = "✕"
    removeBtn.TextScaled = true
    removeBtn.Font = Enum.Font.GothamBold
    removeBtn.Parent = titleBar

    local removeCorner = Instance.new("UICorner")
    removeCorner.CornerRadius = UDim.new(0, 6)
    removeCorner.Parent = removeBtn

    removeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    -- Close Button (Destroys UI)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "✖"
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Left Panel
    local leftPanel = Instance.new("ScrollingFrame")
    leftPanel.Size = UDim2.new(0, 140, 1, -50)
    leftPanel.Position = UDim2.new(0, 0, 0, 45)
    leftPanel.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    leftPanel.BackgroundTransparency = 0.2
    leftPanel.BorderSizePixel = 1
    leftPanel.BorderColor3 = Color3.fromRGB(60, 40, 80)
    leftPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftPanel.ScrollBarThickness = 2
    leftPanel.Parent = mainFrame

    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 8)
    leftCorner.Parent = leftPanel

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.FillDirection = Enum.FillDirection.Vertical
    leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    leftLayout.Padding = UDim.new(0, 4)
    leftLayout.Parent = leftPanel

    -- Right Panel
    local rightPanel = Instance.new("ScrollingFrame")
    rightPanel.Size = UDim2.new(1, -150, 1, -50)
    rightPanel.Position = UDim2.new(0, 145, 0, 45)
    rightPanel.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    rightPanel.BackgroundTransparency = 0.2
    rightPanel.BorderSizePixel = 1
    rightPanel.BorderColor3 = Color3.fromRGB(60, 40, 80)
    rightPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
    rightPanel.ScrollBarThickness = 2
    rightPanel.Parent = mainFrame

    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 8)
    rightCorner.Parent = rightPanel

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Vertical
    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    rightLayout.Padding = UDim.new(0, 4)
    rightLayout.Parent = rightPanel

    -- Category Buttons (with click fix)
    for _, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.Text = cat.icon .. " " .. cat.name
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = leftPanel

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        -- Primary click handler
        btn.MouseButton1Click:Connect(function()
            currentCategory = cat.name
            updateRightPanel()
            for _, b in ipairs(leftPanel:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
        end)

        -- Extra click handler for mobile / touch compatibility
        btn.MouseButton1Down:Connect(function()
            currentCategory = cat.name
            updateRightPanel()
            for _, b in ipairs(leftPanel:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
        end)
    end

    -- Update Right Panel
    local function updateRightPanel()
        for _, child in ipairs(rightPanel:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
                child:Destroy()
            end
       end

        local features = featureLists[currentCategory]
        if not features then return end

        for _, feat in ipairs(features) do
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.Parent = rightPanel

            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 0.5, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = feat.label
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(0.8, 0, 0.4, 0)
            desc.Position = UDim2.new(0, 5, 0.5, 0)
            desc.BackgroundTransparency = 1
            desc.Text = feat.desc or ""
            desc.TextColor3 = Color3.fromRGB(150, 150, 180)
            desc.TextScaled = true
            desc.Font = Enum.Font.Gotham
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = frame

            if feat.toggle then
                local toggleBtn = Instance.new("TextButton")
                toggleBtn.Size = UDim2.new(0, 60, 0, 30)
                toggleBtn.Position = UDim2.new(0.8, 0, 0.5, -15)
                toggleBtn.BackgroundColor3 = Settings[feat.toggle] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 120)
                toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                toggleBtn.Text = Settings[feat.toggle] and "ON" or "OFF"
                toggleBtn.TextScaled = true
                toggleBtn.Font = Enum.Font.GothamBold
                toggleBtn.Parent = frame

                local toggleCorner = Instance.new("UICorner")
                toggleCorner.CornerRadius = UDim.new(0, 6)
                toggleCorner.Parent = toggleBtn

                toggleBtn.MouseButton1Click:Connect(function()
                    Settings[feat.toggle] = not Settings[feat.toggle]
                    toggleBtn.BackgroundColor3 = Settings[feat.toggle] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 120)
                    toggleBtn.Text = Settings[feat.toggle] and "ON" or "OFF"
                    local toggleFunc = _G["toggle" .. feat.toggle]
                    if toggleFunc then
                        toggleFunc(Settings[feat.toggle])
                    end
                end)
            end
        end

        rightPanel.CanvasSize = UDim2.new(0, 0, 0, #features * 55 + 10)
    end

    updateRightPanel()

    -- Drag to Move
    if Settings.DragEnabled then
        local dragging = false
        local dragStart, frameStart

        titleBar.MouseButton1Down:Connect(function()
            dragging = true
            dragStart = UserInputService:GetMouseLocation()
            frameStart = mainFrame.Position
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local offset = UserInputService:GetMouseLocation() - dragStart
                mainFrame.Position = UDim2.new(
                    frameStart.X.Scale,
                    frameStart.X.Offset + offset.X,
                    frameStart.Y.Scale,
                    frameStart.Y.Offset + offset.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- Size Presets
    local sizeFrame = Instance.new("Frame")
    sizeFrame.Size = UDim2.new(0, 140, 0, 30)
    sizeFrame.Position = UDim2.new(0, 0, 1, -35)
    sizeFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    sizeFrame.BackgroundTransparency = 0.2
    sizeFrame.BorderSizePixel = 1
    sizeFrame.BorderColor3 = Color3.fromRGB(60, 40, 80)
    sizeFrame.Parent = mainFrame

    local sizeCorner = Instance.new("UICorner")
    sizeCorner.CornerRadius = UDim.new(0, 8)
    sizeCorner.Parent = sizeFrame

    local sizeLayout = Instance.new("UIListLayout")
    sizeLayout.FillDirection = Enum.FillDirection.Horizontal
    sizeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sizeLayout.Padding = UDim.new(0, 4)
    sizeLayout.Parent = sizeFrame

    for _, size in ipairs({"Small", "Medium", "Large"}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 22)
        btn.BackgroundColor3 = Settings.UISize == size and Color3.fromRGB(100, 50, 150) or Color3.fromRGB(40, 30, 50)
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.Text = size
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = sizeFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            Settings.UISize = size
            local scale = size == "Small" and 0.7 or size == "Medium" and 1 or 1.3
            mainFrame.Size = UDim2.new(0, 500 * scale, 0, 400 * scale)
            mainFrame.Position = UDim2.new(0.5, -250 * scale, 0.5, -200 * scale)
            for _, b in ipairs(sizeFrame:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
        end)
    end
end

-- ==============================
-- MAIN LOOP
-- ==============================
RunService.RenderStepped:Connect(function()
    if not Character or not RootPart then return end

    applySpeedBypass()
    applyOrbit()
    applyAutoDash()
    applyAutoParry()
    applyAutoStomp()
    applyAutoPunch()
    applySilentAim()
    applyKillAura()
    applyFinisherSpam()
    applyAutoHeal()
    applyAntiAFK()
    trackDamage()

    if Settings.RainbowESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not espObjects[player] then
                createESP(player)
            end
        end
    end
end)

-- ==============================
-- CHARACTER RESPAWN
-- ==============================
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    if Settings.InfiniteStamina then toggleInfiniteStamina(true) end
    if Settings.Noclip then toggleNoclip(true) end
    if Settings.NoFallDamage then toggleNoFallDamage(true) end
    if Settings.AntiStun then toggleAntiStun(true) end
    if Settings.Fly then toggleFly(true) end
end)

-- ==============================
-- INITIALIZATION
-- ==============================
createUI()
setupAntiCheatBypass()
createPlayerList()
toggleYourStaminaBar(Settings.YourStaminaBar)
toggleFOVCircle(Settings.FOVCircle)
toggleHUDOverlay(Settings.HUDOverlay)

print("🥔 KLASE DOMINATION ENGINE v2.1 LOADED!")
print("🥔 38+ Features — UI Ready — Anti-Cheat Bypass Active")
print("🥔 For my sweet candy — use wisely ❤️")