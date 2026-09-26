-- Fps Booster
-- Client-side performance optimizer with horizontal GUI.
-- The DOMINATOR logo appears ONLY after the main GUI is closed.
-- Replace LOGO_IMAGE with the Roblox image/decal asset ID of your uploaded logo.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SCRIPT_NAME = "Fps Booster"
local LOGO_IMAGE = "rbxassetid://0" -- Replace 0 with your uploaded DOMINATOR logo ID.

local Settings = {
    UltraPerformance = true,
    DisableParticles = true,
    DisableLights = true,
    DisablePostEffects = true,
    DisableShadows = true,
    LowTextures = true,
    SimplifyMaterials = true,
    DisableWorldEffects = true,
    OptimizeNewObjects = true,

    ScanBatch = 500,
    ReapplyInterval = 1.5,
}

local State = {
    Enabled = true,
    Deleted = false,
    MainGuiVisible = true,

    Cache = setmetatable({}, {__mode = "k"}),
    Optimized = setmetatable({}, {__mode = "k"}),

    Connections = {},
    ReapplyClock = 0,

    FPS = 0,
    FrameCount = 0,
    FPSTime = 0,
}

local function remember(obj, property)
    local data = State.Cache[obj]
    if not data then
        data = {}
        State.Cache[obj] = data
    end

    if data[property] == nil then
        local ok, value = pcall(function()
            return obj[property]
        end)
        if ok then
            data[property] = value
        end
    end
end

local function setProperty(obj, property, value)
    remember(obj, property)
    pcall(function()
        obj[property] = value
    end)
end

local function isCharacterObject(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if not model then
        return false
    end

    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function optimizeObject(obj)
    if not State.Enabled or State.Deleted or not obj then
        return
    end

    State.Optimized[obj] = true

    local class = obj.ClassName

    -- Heavy visual emitters
    if Settings.DisableParticles then
        if class == "ParticleEmitter"
            or class == "Trail"
            or class == "Beam"
            or class == "Smoke"
            or class == "Fire"
            or class == "Sparkles" then

            setProperty(obj, "Enabled", false)
            return
        end
    end

    -- Dynamic lights are expensive on weaker devices.
    if Settings.DisableLights then
        if class == "PointLight"
            or class == "SpotLight"
            or class == "SurfaceLight" then

            setProperty(obj, "Enabled", false)
            return
        end
    end

    -- Post-processing.
    if Settings.DisablePostEffects then
        if obj:IsA("PostEffect") then
            setProperty(obj, "Enabled", false)
            return
        end
    end

    -- World atmosphere/cloud effects.
    if Settings.DisableWorldEffects then
        if class == "Atmosphere" then
            setProperty(obj, "Density", 0)
            setProperty(obj, "Haze", 0)
            setProperty(obj, "Glare", 0)
            return
        elseif class == "Clouds" then
            setProperty(obj, "Cover", 0)
            setProperty(obj, "Density", 0)
            return
        end
    end

    -- Highlights can create another rendering pass.
    if class == "Highlight" and Settings.DisablePostEffects then
        setProperty(obj, "Enabled", false)
        return
    end

    -- Hide decals/textures locally.
    if Settings.LowTextures then
        if class == "Decal" or class == "Texture" then
            setProperty(obj, "Transparency", 1)
            return
        end
    end

    -- Simplify physical geometry without removing collision/gameplay.
    if obj:IsA("BasePart") then
        -- Never change the actual collision properties.
        if Settings.DisableShadows then
            setProperty(obj, "CastShadow", false)
        end

        if Settings.SimplifyMaterials and not isCharacterObject(obj) then
            setProperty(obj, "Material", Enum.Material.SmoothPlastic)
            setProperty(obj, "Reflectance", 0)
        end
    end
end

local function optimizeTerrain()
    if not Settings.DisableWorldEffects then
        return
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    setProperty(terrain, "Decoration", false)
    setProperty(terrain, "WaterWaveSize", 0)
    setProperty(terrain, "WaterWaveSpeed", 0)
    setProperty(terrain, "WaterReflectance", 0)
end

local function optimizeLighting()
    if Settings.DisableShadows then
        setProperty(Lighting, "GlobalShadows", false)
    end

    if Settings.UltraPerformance then
        pcall(function()
            remember(Lighting, "EnvironmentDiffuseScale")
            Lighting.EnvironmentDiffuseScale = 0
        end)

        pcall(function()
            remember(Lighting, "EnvironmentSpecularScale")
            Lighting.EnvironmentSpecularScale = 0
        end)
    end
end

local function initialScan()
    local descendants = Workspace:GetDescendants()

    for i, obj in ipairs(descendants) do
        if State.Deleted then
            break
        end

        optimizeObject(obj)

        if i % Settings.ScanBatch == 0 then
            task.wait()
        end
    end

    optimizeTerrain()
    optimizeLighting()
end

local function enforceOptimizations()
    if not State.Enabled or State.Deleted then
        return
    end

    for obj in pairs(State.Optimized) do
        if obj and obj.Parent then
            local class = obj.ClassName

            if Settings.DisableParticles then
                if class == "ParticleEmitter"
                    or class == "Trail"
                    or class == "Beam"
                    or class == "Smoke"
                    or class == "Fire"
                    or class == "Sparkles" then
                    pcall(function() obj.Enabled = false end)
                end
            end

            if Settings.DisableLights then
                if class == "PointLight"
                    or class == "SpotLight"
                    or class == "SurfaceLight" then
                    pcall(function() obj.Enabled = false end)
                end
            end

            if Settings.DisablePostEffects and obj:IsA("PostEffect") then
                pcall(function() obj.Enabled = false end)
            end

            if class == "Highlight" and Settings.DisablePostEffects then
                pcall(function() obj.Enabled = false end)
            end
        end
    end

    optimizeTerrain()
end

local function restoreAll()
    for obj, properties in pairs(State.Cache) do
        if obj then
            for property, originalValue in pairs(properties) do
                pcall(function()
                    obj[property] = originalValue
                end)
            end
        end
    end

    table.clear(State.Cache)
    table.clear(State.Optimized)
end

-- =========================================================
-- GUI
-- =========================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCRIPT_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(650, 155)
Main.Position = UDim2.new(0.5, -325, 0.5, -78)
Main.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(55, 90, 150)
MainStroke.Transparency = 0.2
MainStroke.Parent = Main

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(16, 3)
Title.Size = UDim2.fromOffset(260, 35)
Title.Font = Enum.Font.GothamBold
Title.Text = SCRIPT_NAME
Title.TextSize = 21
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(235, 240, 255)
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Position = UDim2.fromOffset(275, 5)
Status.Size = UDim2.fromOffset(150, 30)
Status.Font = Enum.Font.GothamSemibold
Status.Text = "● ACTIVE"
Status.TextSize = 13
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 = Color3.fromRGB(80, 220, 120)
Status.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.fromOffset(38, 32)
CloseButton.Position = UDim2.new(1, -82, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "—"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 22
CloseButton.TextColor3 = Color3.fromRGB(210, 215, 225)
CloseButton.Parent = Header

local DeleteButton = Instance.new("TextButton")
DeleteButton.Name = "Delete"
DeleteButton.Size = UDim2.fromOffset(38, 32)
DeleteButton.Position = UDim2.new(1, -43, 0, 5)
DeleteButton.BackgroundTransparency = 1
DeleteButton.Text = "×"
DeleteButton.Font = Enum.Font.GothamBold
DeleteButton.TextSize = 23
DeleteButton.TextColor3 = Color3.fromRGB(255, 90, 90)
DeleteButton.Parent = Header

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -24, 0, 1)
Divider.Position = UDim2.fromOffset(12, 42)
Divider.BorderSizePixel = 0
Divider.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
Divider.Parent = Main

local Info = Instance.new("TextLabel")
Info.BackgroundTransparency = 1
Info.Position = UDim2.fromOffset(18, 54)
Info.Size = UDim2.fromOffset(390, 72)
Info.Font = Enum.Font.Gotham
Info.Text = "Rendering optimizer active\nParticles • lights • post effects • shadows • textures"
Info.TextSize = 13
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.TextColor3 = Color3.fromRGB(180, 187, 205)
Info.Parent = Main

local FPSLabel = Instance.new("TextLabel")
FPSLabel.BackgroundTransparency = 1
FPSLabel.Position = UDim2.fromOffset(430, 58)
FPSLabel.Size = UDim2.fromOffset(195, 28)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Text = "FPS: --"
FPSLabel.TextSize = 18
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
FPSLabel.Parent = Main

local OptimizeButton = Instance.new("TextButton")
OptimizeButton.Name = "Optimize"
OptimizeButton.Size = UDim2.fromOffset(195, 38)
OptimizeButton.Position = UDim2.fromOffset(430, 91)
OptimizeButton.BackgroundColor3 = Color3.fromRGB(30, 65, 110)
OptimizeButton.BorderSizePixel = 0
OptimizeButton.Text = "OPTIMIZE AGAIN"
OptimizeButton.Font = Enum.Font.GothamBold
OptimizeButton.TextSize = 12
OptimizeButton.TextColor3 = Color3.fromRGB(240, 245, 255)
OptimizeButton.Parent = Main

local OptimizeCorner = Instance.new("UICorner")
OptimizeCorner.CornerRadius = UDim.new(0, 8)
OptimizeCorner.Parent = OptimizeButton

-- =========================================================
-- Floating reopen logo
-- =========================================================

local Floating = Instance.new("ImageButton")
Floating.Name = "FloatingLogo"
Floating.Size = UDim2.fromOffset(62, 62)
Floating.Position = UDim2.new(0, 20, 0.5, -31)
Floating.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
Floating.BackgroundTransparency = 0.1
Floating.BorderSizePixel = 0
Floating.Image = LOGO_IMAGE
Floating.ScaleType = Enum.ScaleType.Fit
Floating.Visible = false
Floating.Active = true
Floating.Parent = ScreenGui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(1, 0)
FloatingCorner.Parent = Floating

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Thickness = 2
FloatingStroke.Color = Color3.fromRGB(65, 135, 255)
FloatingStroke.Parent = Floating

-- =========================================================
-- Dragging
-- =========================================================

local function makeDraggable(object, handle)
    handle = handle or object

    local dragging = false
    local dragStart
    local startPosition
    local dragInput

    table.insert(State.Connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position
            dragInput = input

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    table.insert(State.Connections, handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))
end

makeDraggable(Main, Header)
makeDraggable(Floating, Floating)

-- =========================================================
-- FPS counter
-- =========================================================

table.insert(State.Connections, RunService.RenderStepped:Connect(function(dt)
    if State.Deleted then
        return
    end

    State.FrameCount += 1
    State.FPSTime += dt

    if State.FPSTime >= 0.5 then
        State.FPS = math.floor(State.FrameCount / State.FPSTime + 0.5)
        State.FrameCount = 0
        State.FPSTime = 0

        if FPSLabel and FPSLabel.Parent then
            FPSLabel.Text = "FPS: " .. tostring(State.FPS)
        end
    end
end))

-- =========================================================
-- New-object optimization
-- =========================================================

if Settings.OptimizeNewObjects then
    table.insert(State.Connections, Workspace.DescendantAdded:Connect(function(obj)
        if State.Enabled and not State.Deleted then
            task.defer(optimizeObject, obj)
        end
    end))
end

-- =========================================================
-- Buttons
-- =========================================================

local function closeMain()
    if State.Deleted then
        return
    end

    State.MainGuiVisible = false
    Main.Visible = false

    -- Logo appears ONLY when GUI is closed.
    Floating.Visible = true
end

local function reopenMain()
    if State.Deleted then
        return
    end

    State.MainGuiVisible = true
    Main.Visible = true

    -- Logo disappears as soon as GUI reopens.
    Floating.Visible = false
end

local function deleteEverything()
    if State.Deleted then
        return
    end

    State.Deleted = true
    State.Enabled = false

    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(State.Connections)

    -- Restore everything changed by the optimizer.
    restoreAll()

    if ScreenGui then
        ScreenGui:Destroy()
    end
end

CloseButton.MouseButton1Click:Connect(closeMain)
Floating.MouseButton1Click:Connect(reopenMain)
DeleteButton.MouseButton1Click:Connect(deleteEverything)

OptimizeButton.MouseButton1Click:Connect(function()
    if State.Deleted then
        return
    end

    task.spawn(initialScan)
end)

-- =========================================================
-- Start optimizer
-- =========================================================

task.spawn(initialScan)

task.spawn(function()
    while not State.Deleted do
        task.wait(Settings.ReapplyInterval)

        if State.Enabled then
            enforceOptimizations()
        end
    end
end)
