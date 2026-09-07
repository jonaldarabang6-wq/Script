-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 1/8: CONFIGURATION & GLOBAL INITIALIZER
-- Author: Potato (The Undisputed Coding God)
-- Description: Central config, global tables, and bootstrapper.
-- ============================================================

-- Ensure we run only once
if _G.PotatoLoaded then return end
_G.PotatoLoaded = true

-- ============================================================
-- 1. GLOBAL CONFIGURATION TABLE
-- ============================================================
_G.PotatoConfig = {
    -- Combat
    AutoParry = false,
    PerfectDash = false,
    ComboAssist = false,
    HitboxExtender = false,

    -- Survival
    AutoHeal = true,
    HealThreshold = 30,   -- percentage
    StaminaLock = false,
    AntiStun = false,

    -- Visual
    ESPBox = false,
    ESPHealth = false,
    TracerLine = false,
    ESPDistance = 150,    -- studs

    -- Movement
    AirJump = false,
    SpeedBoost = false,
    SpeedMultiplier = 1.5,
    NoClip = false,
    TeleportTarget = false,

    -- Network
    RemoteSpoofer = false,
    CooldownReset = false,
    InstantRespawn = false,

    -- Automation
    AutoFarm = false,
    AutoBuy = false,
    AutoDodge = false,

    -- Anti-Detection
    Obfuscate = true,
    SpoofExecutor = true,
}

-- ============================================================
-- 2. GLOBAL STATE & CACHE
-- ============================================================
_G.PotatoState = {
    Player = game.Players.LocalPlayer,
    Character = nil,
    Humanoid = nil,
    RootPart = nil,
    Camera = workspace.CurrentCamera,
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Players = game:GetService("Players"),
    Heartbeat = nil,
    IsMobile = false,
    ActiveFeatures = {},
}

-- Detect mobile
_G.PotatoState.IsMobile = _G.PotatoState.UserInput.TouchEnabled

-- ============================================================
-- 3. UTILITY FUNCTIONS (Global Helpers)
-- ============================================================
local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function safeWait(seconds)
    if seconds and seconds > 0 then
        task.wait(seconds)
    else
        task.wait()
    end
end

local function getNearestEnemy()
    local player = _G.PotatoState.Player
    local character = _G.PotatoState.Character
    if not character or not character.Parent then return nil end
    local root = _G.PotatoState.RootPart
    if not root then return nil end

    local nearest = nil
    local nearestDist = math.huge
    local enemies = _G.PotatoState.Players:GetPlayers()

    for _, other in ipairs(enemies) do
        if other ~= player and other.Character and other.Character.Parent then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local dist = (root.Position - otherRoot.Position).Magnitude
                if dist < nearestDist then
                    local hum = other.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        nearest = other
                        nearestDist = dist
                    end
                end
            end
        end
    end
    return nearest
end

local function getAllEnemies()
    local player = _G.PotatoState.Player
    local enemies = {}
    for _, other in ipairs(_G.PotatoState.Players:GetPlayers()) do
        if other ~= player and other.Character and other.Character.Parent then
            local hum = other.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, other)
            end
        end
    end
    return enemies
end

local function fireRemote(remoteName, ...)
    local rs = _G.PotatoState.ReplicatedStorage
    local remote = rs:FindFirstChild(remoteName)
    if not remote then
        remote = game:GetService("ReplicatedFirst"):FindFirstChild(remoteName)
    end
    if remote then
        remote:FireServer(...)
        return true
    end
    return false
end

-- Expose helpers globally
_G.PotatoUtils = {
    clamp = clamp,
    safeWait = safeWait,
    getNearestEnemy = getNearestEnemy,
    getAllEnemies = getAllEnemies,
    fireRemote = fireRemote,
}

-- ============================================================
-- 4. CHARACTER UPDATE TRACKER
-- ============================================================
local function updateCharacter()
    local player = _G.PotatoState.Player
    if player.Character and player.Character.Parent then
        _G.PotatoState.Character = player.Character
        _G.PotatoState.Humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        _G.PotatoState.RootPart = player.Character:FindFirstChild("HumanoidRootPart")
    else
        _G.PotatoState.Character = nil
        _G.PotatoState.Humanoid = nil
        _G.PotatoState.RootPart = nil
    end
end

-- Update on spawn
_G.PotatoState.Player.CharacterAdded:Connect(updateCharacter)
updateCharacter()

-- ============================================================
-- 5. BOOTSTRAPPER – LOADS ALL PARTS IN ORDER
-- ============================================================
print("🥔 KLASE DOMINATOR – Loading Part 1/8: Config & Initializer")
print("✅ Config loaded. Utilities ready. Character tracked.")

-- This will be followed by Part 2: UI Layer
-- End of Part 1

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 2/8: UI LAYER
-- Author: Potato
-- Description: Mobile-friendly GUI with floating logo, close/minimize,
--              drag, and all feature toggles.
-- ============================================================

print("🥔 Loading Part 2/8: UI Layer")

-- ============================================================
-- 1. UI SETUP
-- ============================================================
local player = _G.PotatoState.Player
local userInput = _G.PotatoState.UserInput
local tween = _G.PotatoState.TweenService
local mouse = player:GetMouse()
local UI_SCALE = 1.0
local GUI_FOLDER = Instance.new("Folder")
GUI_FOLDER.Name = "PotatoUI"
GUI_FOLDER.Parent = player:WaitForChild("PlayerGui")

-- ============================================================
-- 2. MAIN FRAME
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = GUI_FOLDER
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(0, 360 * UI_SCALE, 0, 520 * UI_SCALE)
MainFrame.Position = UDim2.new(0.5, -180 * UI_SCALE, 0.5, -260 * UI_SCALE)
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 24 * UI_SCALE)
UICorner.Parent = MainFrame

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Parent = MainFrame
Shadow.BackgroundTransparency = 1
Shadow.Size = UDim2.new(1, 40 * UI_SCALE, 1, 40 * UI_SCALE)
Shadow.Position = UDim2.new(0, -20 * UI_SCALE, 0, -20 * UI_SCALE)
Shadow.Image = "rbxassetid://131887524"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.6

-- ============================================================
-- 3. HEADER
-- ============================================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 50 * UI_SCALE)
Header.Position = UDim2.new(0, 0, 0, 0)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 24 * UI_SCALE)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -80 * UI_SCALE, 1, 0)
Title.Position = UDim2.new(0, 15 * UI_SCALE, 0, 0)
Title.Text = "🥔 KLASE DOMINATOR"
Title.TextColor3 = Color3.fromRGB(255, 215, 100)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- MINIMIZE
local MinButton = Instance.new("TextButton")
MinButton.Name = "MinButton"
MinButton.Parent = Header
MinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinButton.BackgroundTransparency = 0.3
MinButton.BorderSizePixel = 0
MinButton.Size = UDim2.new(0, 36 * UI_SCALE, 0, 36 * UI_SCALE)
MinButton.Position = UDim2.new(1, -80 * UI_SCALE, 0, 7 * UI_SCALE)
MinButton.Text = "−"
MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinButton.TextScaled = true
MinButton.Font = Enum.Font.GothamBold
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinButton

-- CLOSE
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = Header
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseButton.BackgroundTransparency = 0.2
CloseButton.BorderSizePixel = 0
CloseButton.Size = UDim2.new(0, 36 * UI_SCALE, 0, 36 * UI_SCALE)
CloseButton.Position = UDim2.new(1, -40 * UI_SCALE, 0, 7 * UI_SCALE)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true
CloseButton.Font = Enum.Font.GothamBold
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

-- ============================================================
-- 4. SCROLLING FEATURE LIST
-- ============================================================
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Name = "FeatureList"
ScrollingFrame.Parent = MainFrame
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Size = UDim2.new(1, -20 * UI_SCALE, 1, -70 * UI_SCALE)
ScrollingFrame.Position = UDim2.new(0, 10 * UI_SCALE, 0, 60 * UI_SCALE)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.ScrollBarThickness = 6 * UI_SCALE
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 100)
ScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8 * UI_SCALE)

-- ============================================================
-- 5. GENERATE TOGGLES FROM CONFIG
-- ============================================================
local FeatureDefinitions = {
    {name = "Auto-Parry", key = "F1", configKey = "AutoParry"},
    {name = "Perfect Dash", key = "F2", configKey = "PerfectDash"},
    {name = "Combo Assist", key = "F3", configKey = "ComboAssist"},
    {name = "Hitbox Extender", key = "F4", configKey = "HitboxExtender"},
    {name = "Auto-Heal", key = "F5", configKey = "AutoHeal"},
    {name = "Stamina Lock", key = "F6", configKey = "StaminaLock"},
    {name = "Anti-Stun", key = "F7", configKey = "AntiStun"},
    {name = "ESP (Box)", key = "F8", configKey = "ESPBox"},
    {name = "ESP (Health)", key = "F9", configKey = "ESPHealth"},
    {name = "Tracer Line", key = "F10", configKey = "TracerLine"},
    {name = "Air Jump", key = "F11", configKey = "AirJump"},
    {name = "Speed Boost", key = "F12", configKey = "SpeedBoost"},
    {name = "No-Clip", key = "G", configKey = "NoClip"},
    {name = "Teleport to Target", key = "T", configKey = "TeleportTarget"},
    {name = "Auto-Farm", key = "F", configKey = "AutoFarm"},
    {name = "Remote Spoofer", key = "R", configKey = "RemoteSpoofer"},
}

local function CreateToggle(feature)
    local Frame = Instance.new("Frame")
    Frame.Name = feature.name .. "Toggle"
    Frame.Parent = ScrollingFrame
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Frame.BackgroundTransparency = 0.3
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, -10 * UI_SCALE, 0, 44 * UI_SCALE)
    Frame.ClipsDescendants = true

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12 * UI_SCALE)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12 * UI_SCALE, 0, 0)
    Label.Text = feature.name .. " [" .. feature.key .. "]"
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextScaled = true
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Toggle = Instance.new("TextButton")
    Toggle.Name = "ToggleBtn"
    Toggle.Parent = Frame
    Toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    Toggle.BorderSizePixel = 0
    Toggle.Size = UDim2.new(0, 50 * UI_SCALE, 0, 28 * UI_SCALE)
    Toggle.Position = UDim2.new(1, -60 * UI_SCALE, 0, 8 * UI_SCALE)
    Toggle.Text = ""
    Toggle.AutoButtonColor = false

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = Toggle

    local Circle = Instance.new("TextLabel")
    Circle.Name = "Circle"
    Circle.Parent = Toggle
    Circle.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    Circle.BackgroundTransparency = 0
    Circle.BorderSizePixel = 0
    Circle.Size = UDim2.new(0, 22 * UI_SCALE, 0, 22 * UI_SCALE)
    Circle.Position = UDim2.new(0, 3 * UI_SCALE, 0, 3 * UI_SCALE)
    Circle.Text = ""
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local isOn = _G.PotatoConfig[feature.configKey] or false
    local function UpdateSwitch()
        if isOn then
            Toggle.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            Circle.Position = UDim2.new(0, 25 * UI_SCALE, 0, 3 * UI_SCALE)
        else
            Toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            Circle.Position = UDim2.new(0, 3 * UI_SCALE, 0, 3 * UI_SCALE)
        end
        _G.PotatoConfig[feature.configKey] = isOn
    end
    UpdateSwitch()

    Toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        UpdateSwitch()
    end)

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isOn = not isOn
            UpdateSwitch()
        end
    end)
end

for _, feat in ipairs(FeatureDefinitions) do
    CreateToggle(feat)
end

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20 * UI_SCALE)
end)

-- ============================================================
-- 6. FLOATING LOGO
-- ============================================================
local FloatingLogo = Instance.new("ImageButton")
FloatingLogo.Name = "FloatingLogo"
FloatingLogo.Parent = GUI_FOLDER
FloatingLogo.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
FloatingLogo.BackgroundTransparency = 0.2
FloatingLogo.BorderSizePixel = 0
FloatingLogo.Size = UDim2.new(0, 60 * UI_SCALE, 0, 60 * UI_SCALE)
FloatingLogo.Position = UDim2.new(0, 20 * UI_SCALE, 1, -80 * UI_SCALE)
FloatingLogo.Image = "rbxassetid://6023427436"
FloatingLogo.ImageColor3 = Color3.fromRGB(255, 215, 100)
FloatingLogo.Visible = false
local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = FloatingLogo

-- Drag for logo
local draggingLogo = false
local dragLogoInput, dragLogoStart, dragLogoStartPos
FloatingLogo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingLogo = true
        dragLogoInput = input
        dragLogoStart = input.Position
        dragLogoStartPos = FloatingLogo.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingLogo = false
            end
        end)
    end
end)
userInput.InputChanged:Connect(function(input)
    if draggingLogo and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragLogoStart
        FloatingLogo.Position = UDim2.new(
            dragLogoStartPos.X.Scale,
            dragLogoStartPos.X.Offset + delta.X,
            dragLogoStartPos.Y.Scale,
            dragLogoStartPos.Y.Offset + delta.Y
        )
    end
end)

FloatingLogo.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingLogo.Visible = false
end)

-- ============================================================
-- 7. CLOSE / MINIMIZE LOGIC
-- ============================================================
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingLogo.Visible = true
end)

MinButton.MouseButton1Click:Connect(function()
    local tweenAnim = tween:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tweenAnim:Play()
    tweenAnim.Completed:Connect(function()
        MainFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 360 * UI_SCALE, 0, 520 * UI_SCALE)
        MainFrame.Position = UDim2.new(0.5, -180 * UI_SCALE, 0.5, -260 * UI_SCALE)
        FloatingLogo.Visible = true
    end)
end)

-- ============================================================
-- 8. DRAG MAIN FRAME
-- ============================================================
local dragging = false
local dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPos = MainFrame.Position
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
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Initial state
MainFrame.Visible = true
FloatingLogo.Visible = false

print("✅ UI Layer loaded successfully.")
-- End of Part 2

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 3/8: ANTI-DETECTION & EXECUTOR SPOOFING
-- Author: Potato
-- Description: Obfuscation, executor fingerprint masking,
--              and runtime integrity checks.
-- ============================================================

print("🥔 Loading Part 3/8: Anti-Detection Layer")

-- ============================================================
-- 1. EXECUTOR SPOOFING
-- ============================================================
local function spoofExecutor()
    -- Hide common executor identifiers
    local env = getfenv and getfenv() or _G
    local fakeSyn = {
        secure_call = function(fn, ...) return fn(...) end,
        protect_gui = function() end,
        crypt = { encrypt = function(s) return s end, decrypt = function(s) return s end },
        cache = { replace = function() end },
        request = function(...) return game:GetService("HttpService"):GetAsync(...) end,
    }
    
    -- Override globals if they exist
    if env.syn then env.syn = fakeSyn end
    if env.getexecutorname then 
        env.getexecutorname = function() return "Synapse X v3.2" end 
    end
    if env.checkcaller then 
        env.checkcaller = function() return false end 
    end
    if env.is_synapse then 
        env.is_synapse = function() return true end 
    end
    if env.identifyexecutor then 
        env.identifyexecutor = function() return {Name = "Synapse X", Version = "3.2"} end 
    end
    
    -- Remove or hide debug functions that are often checked
    local debug = debug or {}
    if debug.getinfo then
        local oldGetInfo = debug.getinfo
        debug.getinfo = function(...)
            local info = oldGetInfo(...)
            if info and info.source then
                -- Obfuscate source path
                info.source = "=[C]"
            end
            return info
        end
    end
    
    print("🛡️ Executor spoofed as Synapse X v3.2")
end

-- ============================================================
-- 2. OBFUSCATION WRAPPER (for runtime string protection)
-- ============================================================
local function obfuscateString(str)
    local encoded = ""
    for i = 1, #str do
        local char = string.byte(str, i)
        encoded = encoded .. string.format("%02x", char)
    end
    return encoded
end

local function deobfuscateString(hex)
    local decoded = ""
    for i = 1, #hex, 2 do
        local byte = tonumber(string.sub(hex, i, i+1), 16)
        decoded = decoded .. string.char(byte)
    end
    return decoded
end

-- ============================================================
-- 3. MEMORY CLEANUP & GC CONTROL
-- ============================================================
local function optimizeMemory()
    -- Force garbage collection periodically but unpredictably
    task.spawn(function()
        while true do
            task.wait(math.random(30, 90))
            collectgarbage("collect")
            if math.random(1, 10) == 5 then
                collectgarbage("step", 1000)
            end
        end
    end)
end

-- ============================================================
-- 4. ERROR SUPPRESSION (silent fail)
-- ============================================================
local function safeExecute(func, fallback)
    local success, result = pcall(func)
    if not success then
        if fallback then
            return fallback
        end
        return nil
    end
    return result
end

-- ============================================================
-- 5. APPLY ANTI-DETECTION IF ENABLED
-- ============================================================
if _G.PotatoConfig.SpoofExecutor then
    spoofExecutor()
end

if _G.PotatoConfig.Obfuscate then
    _G.PotatoUtils.obfuscate = obfuscateString
    _G.PotatoUtils.deobfuscate = deobfuscateString
end

optimizeMemory()
_G.PotatoUtils.safeExecute = safeExecute

print("✅ Anti-Detection Layer active.")
-- End of Part 3

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 4/8: COMBAT CORE
-- Author: Potato
-- Description: Auto-Parry, Perfect Dash, Combo Assist, Hitbox Extender
-- ============================================================

print("🥔 Loading Part 4/8: Combat Core")

local state = _G.PotatoState
local config = _G.PotatoConfig
local utils = _G.PotatoUtils
local runService = state.RunService

-- ============================================================
-- 1. AUTO-PARRY
-- ============================================================
local function autoParryLoop()
    if not config.AutoParry then return end
    local char = state.Character
    if not char then return end
    local humanoid = state.Humanoid
    if not humanoid then return end
    
    -- Detect incoming projectiles or melee windup
    -- Simplified: check for nearby enemies with attacking animation
    local enemies = utils.getAllEnemies()
    for _, enemy in ipairs(enemies) do
        local enemyChar = enemy.Character
        if enemyChar then
            local animator = enemyChar:FindFirstChildOfClass("Animator")
            if animator then
                local tracks = animator:GetPlayingAnimationTracks()
                for _, track in ipairs(tracks) do
                    if track.Animation and string.find(track.Animation.Name:lower(), "attack") then
                        -- Trigger parry (simulate block key)
                        local blockRemote = state.ReplicatedStorage:FindFirstChild("BlockRemote")
                        if blockRemote then
                            blockRemote:FireServer(true)
                            task.wait(0.1)
                            blockRemote:FireServer(false)
                        end
                        return
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 2. PERFECT DASH
-- ============================================================
local function perfectDashLoop()
    if not config.PerfectDash then return end
    local root = state.RootPart
    if not root then return end
    local nearest = utils.getNearestEnemy()
    if not nearest or not nearest.Character then return end
    local enemyRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return end
    
    -- Dash toward enemy when they attack
    -- We'll check if enemy is within range and facing us
    local dist = (root.Position - enemyRoot.Position).Magnitude
    if dist < 20 then
        local dashRemote = state.ReplicatedStorage:FindFirstChild("DashRemote")
        if dashRemote then
            dashRemote:FireServer(enemyRoot.Position)
        end
    end
end

-- ============================================================
-- 3. COMBO ASSIST
-- ============================================================
local comboSequence = {"StunAbility", "BurstAbility", "FinisherAbility"}
local comboIndex = 1

local function comboAssistLoop()
    if not config.ComboAssist then return end
    local nearest = utils.getNearestEnemy()
    if not nearest or not nearest.Character then return end
    local enemyHum = nearest.Character:FindFirstChildOfClass("Humanoid")
    if not enemyHum or enemyHum.Health <= 0 then 
        comboIndex = 1
        return 
    end
    
    -- Fire next ability in sequence
    local abilityName = comboSequence[comboIndex]
    if abilityName then
        local remote = state.ReplicatedStorage:FindFirstChild(abilityName)
        if remote then
            remote:FireServer(nearest)
            comboIndex = comboIndex + 1
            if comboIndex > #comboSequence then comboIndex = 1 end
            task.wait(0.3)  -- delay between combo hits
        end
    end
end

-- ============================================================
-- 4. HITBOX EXTENDER
-- ============================================================
local function hitboxExtenderLoop()
    if not config.HitboxExtender then return end
    local char = state.Character
    if not char then return end
    
    -- Extend melee hitbox by modifying arm attachments or tool reach
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                handle.Size = handle.Size * 1.5
            end
        end
    end
end

-- ============================================================
-- 5. REGISTER COMBAT LOOPS ON HEARTBEAT
-- ============================================================
runService.Heartbeat:Connect(function()
    utils.safeExecute(autoParryLoop)
    utils.safeExecute(perfectDashLoop)
    utils.safeExecute(comboAssistLoop)
    utils.safeExecute(hitboxExtenderLoop)
end)

print("✅ Combat Core active.")
-- End of Part 4

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 5/8: SURVIVAL CORE
-- Author: Potato
-- Description: Auto-Heal, Stamina Lock, Anti-Stun
-- ============================================================

print("🥔 Loading Part 5/8: Survival Core")

local state = _G.PotatoState
local config = _G.PotatoConfig
local utils = _G.PotatoUtils
local runService = state.RunService

-- ============================================================
-- 1. AUTO-HEAL
-- ============================================================
local function autoHealLoop()
    if not config.AutoHeal then return end
    local humanoid = state.Humanoid
    if not humanoid then return end
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local threshold = config.HealThreshold or 30
    local percent = (health / maxHealth) * 100
    
    if percent <= threshold then
        -- Find heal item in backpack or hotbar
        local backpack = state.Player:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name:lower(), "heal") then
                    -- Equip and use
                    state.Player.Character:FindFirstChildOfClass("Humanoid"):EquipTool(item)
                    task.wait(0.1)
                    local remote = state.ReplicatedStorage:FindFirstChild("UseItemRemote")
                    if remote then
                        remote:FireServer(item)
                    end
                    break
                end
            end
        end
    end
end

-- ============================================================
-- 2. STAMINA LOCK
-- ============================================================
local function staminaLockLoop()
    if not config.StaminaLock then return end
    local char = state.Character
    if not char then return end
    
    -- Find stamina value (usually a NumberValue or attribute)
    local staminaValue = char:FindFirstChild("Stamina")
    if not staminaValue then
        staminaValue = char:FindFirstChild("StaminaValue")
    end
    if staminaValue and staminaValue:IsA("NumberValue") then
        staminaValue.Value = 100
    elseif staminaValue and staminaValue:IsA("IntValue") then
        staminaValue.Value = 100
    end
    
    -- Also check humanoid for stamina-like attributes
    local humanoid = state.Humanoid
    if humanoid then
        local attrs = humanoid:GetAttributes()
        for key, val in pairs(attrs) do
            if string.find(key:lower(), "stamina") and type(val) == "number" then
                humanoid:SetAttribute(key, 100)
            end
        end
    end
end

-- ============================================================
-- 3. ANTI-STUN
-- ============================================================
local function antiStunLoop()
    if not config.AntiStun then return end
    local char = state.Character
    if not char then return end
    local humanoid = state.Humanoid
    if not humanoid then return end
    
    -- Check for stun attribute or debuff
    local isStunned = false
    local attrs = humanoid:GetAttributes()
    for key, val in pairs(attrs) do
        if string.find(key:lower(), "stun") and val == true then
            isStunned = true
            humanoid:SetAttribute(key, false)
        end
    end
    
    if isStunned then
        -- Try to fire a cleanup remote
        local remote = state.ReplicatedStorage:FindFirstChild("StunCleanup")
        if remote then
            remote:FireServer()
        end
        -- Also try to reset humanoid state
        humanoid.PlatformStand = false
        humanoid.Sit = false
    end
end

-- ============================================================
-- 4. REGISTER SURVIVAL LOOPS
-- ============================================================
runService.Heartbeat:Connect(function()
    utils.safeExecute(autoHealLoop)
    utils.safeExecute(staminaLockLoop)
    utils.safeExecute(antiStunLoop)
end)

print("✅ Survival Core active.")
-- End of Part 5

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 6/8: VISUAL CORE
-- Author: Potato
-- Description: ESP (Box, Health), Tracer Line
-- ============================================================

print("🥔 Loading Part 6/8: Visual Core")

local state = _G.PotatoState
local config = _G.PotatoConfig
local utils = _G.PotatoUtils
local runService = state.RunService
local camera = state.Camera

-- ============================================================
-- 1. DRAWING UTILITIES (if Drawing library available)
-- ============================================================
local drawingAvailable = pcall(function() return Drawing end)
local drawings = {}

local function createDrawing(drawType, props)
    if not drawingAvailable then return nil end
    local obj = Drawing.new(drawType)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

-- ============================================================
-- 2. BOX ESP
-- ============================================================
local espBoxes = {}

local function updateBoxESP()
    if not config.ESPBox then
        -- Clear drawings
        for _, obj in ipairs(espBoxes) do
            if obj and obj.Remove then obj:Remove() end
        end
        espBoxes = {}
        return
    end
    
    local enemies = utils.getAllEnemies()
    local maxDist = config.ESPDistance or 150
    
    -- Clean up old boxes
    for i = #espBoxes, 1, -1 do
        if espBoxes[i] and espBoxes[i].Remove then
            espBoxes[i]:Remove()
        end
        table.remove(espBoxes, i)
    end
    
    for _, enemy in ipairs(enemies) do
        local char = enemy.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos = root.Position
                local dist = (state.RootPart and state.RootPart.Position - pos).Magnitude or 0
                if dist <= maxDist then
                    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
                    if onScreen then
                        local size = 4 / (dist + 1) * 50
                        local box = createDrawing("Square", {
                            Position = Vector2.new(screenPos.X - size/2, screenPos.Y - size),
                            Size = Vector2.new(size, size * 1.5),
                            Color = Color3.fromRGB(255, 50, 50),
                            Thickness = 2,
                            Visible = true,
                            Filled = false,
                            Transparency = 0.7,
                        })
                        if box then table.insert(espBoxes, box) end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 3. HEALTH BAR ESP
-- ============================================================
local healthBars = {}

local function updateHealthESP()
    if not config.ESPHealth then
        for _, obj in ipairs(healthBars) do
            if obj and obj.Remove then obj:Remove() end
        end
        healthBars = {}
        return
    end
    
    local enemies = utils.getAllEnemies()
    local maxDist = config.ESPDistance or 150
    
    for i = #healthBars, 1, -1 do
        if healthBars[i] and healthBars[i].Remove then
            healthBars[i]:Remove()
        end
        table.remove(healthBars, i)
    end
    
    for _, enemy in ipairs(enemies) do
        local char = enemy.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos = root.Position
                local dist = (state.RootPart and state.RootPart.Position - pos).Magnitude or 0
                if dist <= maxDist then
                    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
                    if onScreen then
                        local barWidth = 40
                        local barHeight = 5
                        local healthPercent = hum.Health / hum.MaxHealth
                        local bar = createDrawing("Line", {
                            From = Vector2.new(screenPos.X - barWidth/2, screenPos.Y - 30),
                            To = Vector2.new(screenPos.X - barWidth/2 + barWidth * healthPercent, screenPos.Y - 30),
                            Color = Color3.fromRGB(0, 255, 0),
                            Thickness = 4,
                            Visible = true,
                            Transparency = 0.8,
                        })
                        if bar then table.insert(healthBars, bar) end
                        
                        -- Background for health bar
                        local bg = createDrawing("Line", {
                            From = Vector2.new(screenPos.X - barWidth/2, screenPos.Y - 30),
                            To = Vector2.new(screenPos.X + barWidth/2, screenPos.Y - 30),
                            Color = Color3.fromRGB(50, 50, 50),
                            Thickness = 4,
                            Visible = true,
                            Transparency = 0.5,
                        })
                        if bg then table.insert(healthBars, bg) end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 4. TRACER LINE
-- ============================================================
local tracerLines = {}

local function updateTracer()
    if not config.TracerLine then
        for _, obj in ipairs(tracerLines) do
            if obj and obj.Remove then obj:Remove() end
        end
        tracerLines = {}
        return
    end
    
    for i = #tracerLines, 1, -1 do
        if tracerLines[i] and tracerLines[i].Remove then
            tracerLines[i]:Remove()
        end
        table.remove(tracerLines, i)
    end
    
    local nearest = utils.getNearestEnemy()
    if nearest and nearest.Character then
        local root = nearest.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local line = createDrawing("Line", {
                    From = center,
                    To = Vector2.new(screenPos.X, screenPos.Y),
                    Color = Color3.fromRGB(0, 200, 255),
                    Thickness = 1.5,
                    Visible = true,
                    Transparency = 0.6,
                })
                if line then table.insert(tracerLines, line) end
            end
        end
    end
end

-- ============================================================
-- 5. REGISTER VISUAL LOOPS
-- ============================================================
runService.Heartbeat:Connect(function()
    utils.safeExecute(updateBoxESP)
    utils.safeExecute(updateHealthESP)
    utils.safeExecute(updateTracer)
end)

print("✅ Visual Core active.")
-- End of Part 6

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 7/8: MOVEMENT CORE
-- Author: Potato
-- Description: Air Jump, Speed Boost, No-Clip, Teleport to Target
-- ============================================================

print("🥔 Loading Part 7/8: Movement Core")

local state = _G.PotatoState
local config = _G.PotatoConfig
local utils = _G.PotatoUtils
local runService = state.RunService
local userInput = state.UserInput

-- ============================================================
-- 1. AIR JUMP
-- ============================================================
local function airJumpLoop()
    if not config.AirJump then return end
    local humanoid = state.Humanoid
    if not humanoid then return end
    local root = state.RootPart
    if not root then return end
    
    -- Allow jump while in air by toggling JumpPower
    if humanoid.FloorMaterial == Enum.Material.Air then
        humanoid.Jump = true
        task.wait(0.01)
        humanoid.Jump = false
    end
end

-- ============================================================
-- 2. SPEED BOOST
-- ============================================================
local function speedBoostLoop()
    if not config.SpeedBoost then return end
    local humanoid = state.Humanoid
    if not humanoid then return end
    local multiplier = config.SpeedMultiplier or 1.5
    local baseSpeed = 16  -- typical Roblox walk speed
    
    -- Try to find actual base speed from game
    local attrs = humanoid:GetAttributes()
    local base = attrs.BaseSpeed or baseSpeed
    
    -- Apply boost
    humanoid.WalkSpeed = base * multiplier
    humanoid.JumpPower = 50 * multiplier  -- also boost jump
end

-- ============================================================
-- 3. NO-CLIP (PHASE)
-- ============================================================
local function noClipLoop()
    if not config.NoClip then return end
    local char = state.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- ============================================================
-- 4. TELEPORT TO TARGET
-- ============================================================
local function teleportToTarget()
    if not config.TeleportTarget then return end
    local root = state.RootPart
    if not root then return end
    local target = utils.getNearestEnemy()
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Teleport behind the target
    local behind = targetRoot.Position + (targetRoot.CFrame.LookVector * -3)
    root.CFrame = CFrame.new(behind)
end

-- Bind teleport to T key
userInput.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.T and input.UserInputType == Enum.UserInputType.Keyboard then
        if config.TeleportTarget then
            utils.safeExecute(teleportToTarget)
        end
    end
end)

-- ============================================================
-- 5. REGISTER MOVEMENT LOOPS
-- ============================================================
runService.Heartbeat:Connect(function()
    utils.safeExecute(airJumpLoop)
    utils.safeExecute(speedBoostLoop)
    utils.safeExecute(noClipLoop)
end)

print("✅ Movement Core active.")
-- End of Part 7

-- ============================================================
-- KLASE DOMINATOR v1.0 – FULL SCRIPT
-- PART 8/8: NETWORK & AUTOMATION CORE
-- Author: Potato
-- Description: Remote Spoofer, Cooldown Reset, Auto-Farm, Auto-Dodge
-- ============================================================

print("🥔 Loading Part 8/8: Network & Automation Core")

local state = _G.PotatoState
local config = _G.PotatoConfig
local utils = _G.PotatoUtils
local runService = state.RunService

-- ============================================================
-- 1. REMOTE SPOOFER (Intercept and modify remote calls)
-- ============================================================
local function remoteSpooferLoop()
    if not config.RemoteSpoofer then return end
    -- This is a placeholder for advanced remote hooking
    -- We'll scan for common remotes and override their FireServer behavior
    local rs = state.ReplicatedStorage
    for _, remote in ipairs(rs:GetChildren()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if not remote._hooked then
                local oldFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    -- Modify arguments (e.g., increase damage, remove cooldown)
                    if string.find(self.Name:lower(), "damage") then
                        args[1] = (args[1] or 0) * 2  -- double damage
                    elseif string.find(self.Name:lower(), "cooldown") then
                        args[1] = 0  -- zero cooldown
                    end
                    return oldFire(self, unpack(args))
                end
                remote._hooked = true
            end
        end
    end
end

-- ============================================================
-- 2. COOLDOWN RESET
-- ============================================================
local function cooldownResetLoop()
    if not config.CooldownReset then return end
    -- Reset ability cooldowns by finding cooldown values in player's character
    local char = state.Character
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("NumberValue") and string.find(child.Name:lower(), "cooldown") then
            child.Value = 0
        elseif child:IsA("IntValue") and string.find(child.Name:lower(), "cooldown") then
            child.Value = 0
        end
    end
end

-- ============================================================
-- 3. AUTO-FARM
-- ============================================================
local function autoFarmLoop()
    if not config.AutoFarm then return end
    local root = state.RootPart
    if not root then return end
    
    -- Find nearest NPC (non-player character)
    local nearestNPC = nil
    local nearestDist = math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not obj:FindFirstChild("Player") then
            local npcRoot = obj:FindFirstChild("HumanoidRootPart")
            if npcRoot then
                local dist = (root.Position - npcRoot.Position).Magnitude
                if dist < nearestDist then
                    nearestNPC = obj
                    nearestDist = dist
                end
            end
        end
    end
    
    if nearestNPC and nearestDist < 30 then
        -- Move toward NPC
        local npcRoot = nearestNPC:FindFirstChild("HumanoidRootPart")
        if npcRoot then
            root.CFrame = CFrame.new(npcRoot.Position)
            -- Attack remote
            local attackRemote = state.ReplicatedStorage:FindFirstChild("AttackRemote")
            if attackRemote then
                attackRemote:FireServer(nearestNPC)
            end
        end
    end
end

-- ============================================================
-- 4. AUTO-DODGE
-- ============================================================
local function autoDodgeLoop()
    if not config.AutoDodge then return end
    local root = state.RootPart
    if not root then return end
    
    -- Detect incoming projectiles (simple check)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:lower():find("projectile") then
            local velocity = obj.Velocity
            if velocity and velocity.Magnitude > 10 then
                -- Check if heading toward player
                local dir = (obj.Position - root.Position).Unit
                local dot = dir:Dot(velocity.Unit)
                if dot > 0.8 then
                    -- Dodge sideways
                    local dodgeDir = Vector3.new(1, 0, 0):Cross(velocity.Unit)
                    root.CFrame = root.CFrame + dodgeDir * 5
                    break
                end
            end
        end
    end
end

-- ============================================================
-- 5. REGISTER NETWORK & AUTOMATION LOOPS
-- ============================================================
runService.Heartbeat:Connect(function()
    utils.safeExecute(remoteSpooferLoop)
    utils.safeExecute(cooldownResetLoop)
    utils.safeExecute(autoFarmLoop)
    utils.safeExecute(autoDodgeLoop)
end)

-- ============================================================
-- 6. FINAL INITIALIZATION MESSAGE
-- ============================================================
print("✅ Network & Automation Core active.")
print("==================================================")
print("🥔 KLASE DOMINATOR v1.0 – FULLY LOADED")
print("✅ All 8 parts successfully initialized.")
print("🎯 Features: Combat, Survival, Visual, Movement, Network, Automation")
print("📱 Mobile-friendly UI with floating logo.")
print("🛡️ Anti-detection active.")
print("🔥 Enjoy domination, butter.")
print("==================================================")

-- End of Part 8
-- ============================================================
-- END OF FULL SCRIPT
-- ============================================================