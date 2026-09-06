--[[
    🌌 ORBIT PANEL V3
    Designed for use in your own Roblox experience.

    V3 UI:
    - Left side = feature selector
    - Right side = selected feature content
    - Scrollable feature list
    - Selected feature outline
    - Draggable main panel
    - Draggable galaxy reopen icon
    - Minimize / Close
    - Live UI settings

    Features:
    - Main
    - ESP
    - Orbit
    - Auto Punch
    - Target Lock
    - Infinite Stamina
    - Reset Position
    - Misc
    - Settings
    - Information
    - Credits

    Orbit presets are intentionally NOT included.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS / STATE
--==================================================

local UISettings = {
    BackgroundColor = Color3.fromRGB(22, 16, 35),
    SecondaryColor = Color3.fromRGB(31, 23, 48),
    AccentColor = Color3.fromRGB(170, 100, 255),
    OutlineColor = Color3.fromRGB(210, 170, 255),
    TextColor = Color3.fromRGB(245, 240, 255),
    MutedTextColor = Color3.fromRGB(175, 165, 190),

    Transparency = 0.08,
    BackgroundTransparency = 0.08,
    OutlineEnabled = true,

    Width = 560,
    Height = 390,
}

local State = {
    CurrentFeature = "Main",

    TargetLock = false,
    LockedTarget = nil,

    InfiniteStamina = false,

    OrbitEnabled = false,
    OrbitTarget = nil,
    OrbitSpeed = 5,
    OrbitRadius = 8,
    AutoOrbitStop = true,

    AutoPunch = false,
    AutoPunchRange = 15,
    AutoPunchInterval = 0.25,

    ESPEnabled = false,
    ESPNickname = true,
    ESPUsername = true,

    SavedCFrame = nil,

    Minimized = false,
    Closed = false,
}

local Connections = {}

local function disconnect(name)
    if Connections[name] then
        Connections[name]:Disconnect()
        Connections[name] = nil
    end
end

local function cleanup()
    for name, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
        end
        Connections[name] = nil
    end
end

--==================================================
-- HELPERS
--==================================================

local function getCharacter(player)
    return player and player.Character
end

local function getRoot(player)
    local character = getCharacter(player)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
    local character = getCharacter(player)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local humanoid = getHumanoid(player)
    local root = getRoot(player)
    return humanoid and humanoid.Health > 0 and root ~= nil
end

local function getNearestPlayer(maxDistance)
    local myRoot = getRoot(LocalPlayer)
    if not myRoot then
        return nil
    end

    local nearest = nil
    local nearestDistance = maxDistance or math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local root = getRoot(player)
            local distance = (root.Position - myRoot.Position).Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearest = player
            end
        end
    end

    return nearest
end

local function getEquippedTool()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Tool")
end

local function getFirstTool()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then
        return nil
    end

    return backpack:FindFirstChildOfClass("Tool")
end

local function activateEquippedTool()
    local tool = getEquippedTool()
    if tool and tool:IsA("Tool") then
        pcall(function()
            tool:Activate()
        end)
        return true
    end

    return false
end

local function notify(text)
    -- Small built-in notification.
    -- Replace this with your preferred notification system if desired.
    print("[Orbit Panel V3] " .. tostring(text))
end

--==================================================
-- UI CREATION
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OrbitPanelV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)
Main.Position = UDim2.new(0.5, -UISettings.Width / 2, 0.5, -UISettings.Height / 2)
Main.BackgroundColor3 = UISettings.BackgroundColor
Main.BackgroundTransparency = UISettings.BackgroundTransparency
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = UISettings.OutlineColor
MainStroke.Transparency = UISettings.OutlineEnabled and 0 or 1
MainStroke.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = UISettings.SecondaryColor
TopBar.BackgroundTransparency = UISettings.Transparency
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(14, 0)
Title.Size = UDim2.new(1, -105, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "🌌 Orbit Panel V3"
Title.TextColor3 = UISettings.TextColor
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Minimize = Instance.new("TextButton")
Minimize.BackgroundTransparency = 1
Minimize.Size = UDim2.fromOffset(38, 45)
Minimize.Position = UDim2.new(1, -78, 0, 0)
Minimize.Font = Enum.Font.GothamBold
Minimize.Text = "—"
Minimize.TextColor3 = UISettings.TextColor
Minimize.TextSize = 20
Minimize.Parent = TopBar

local Close = Instance.new("TextButton")
Close.BackgroundTransparency = 1
Close.Size = UDim2.fromOffset(38, 45)
Close.Position = UDim2.new(1, -39, 0, 0)
Close.Font = Enum.Font.GothamBold
Close.Text = "×"
Close.TextColor3 = UISettings.TextColor
Close.TextSize = 23
Close.Parent = TopBar

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Position = UDim2.fromOffset(8, 52)
Sidebar.Size = UDim2.new(0, 145, 1, -60)
Sidebar.BackgroundColor3 = UISettings.SecondaryColor
Sidebar.BackgroundTransparency = UISettings.Transparency
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 3
Sidebar.CanvasSize = UDim2.new()
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 9)
SidebarCorner.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 7)
SidebarPadding.PaddingBottom = UDim.new(0, 7)
SidebarPadding.PaddingLeft = UDim.new(0, 6)
SidebarPadding.PaddingRight = UDim.new(0, 6)
SidebarPadding.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Position = UDim2.fromOffset(161, 52)
Content.Size = UDim2.new(1, -169, 1, -60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new()
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 4)
ContentPadding.PaddingBottom = UDim.new(0, 10)
ContentPadding.PaddingLeft = UDim.new(0, 7)
ContentPadding.PaddingRight = UDim.new(0, 7)
ContentPadding.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

--==================================================
-- DRAGGING
--==================================================

local function makeDraggable(handle, object)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(TopBar, Main)

--==================================================
-- GALAXY REOPEN ICON
--==================================================

local GalaxyButton = Instance.new("TextButton")
GalaxyButton.Name = "GalaxyReopen"
GalaxyButton.Size = UDim2.fromOffset(58, 58)
GalaxyButton.Position = UDim2.new(0.85, 0, 0.75, 0)
GalaxyButton.BackgroundColor3 = UISettings.SecondaryColor
GalaxyButton.BackgroundTransparency = UISettings.Transparency
GalaxyButton.BorderSizePixel = 0
GalaxyButton.Text = "🌌"
GalaxyButton.TextSize = 30
GalaxyButton.Visible = false
GalaxyButton.ZIndex = 50
GalaxyButton.Parent = ScreenGui

local GalaxyCorner = Instance.new("UICorner")
GalaxyCorner.CornerRadius = UDim.new(1, 0)
GalaxyCorner.Parent = GalaxyButton

local GalaxyStroke = Instance.new("UIStroke")
GalaxyStroke.Thickness = 1.5
GalaxyStroke.Color = UISettings.OutlineColor
GalaxyStroke.Parent = GalaxyButton

makeDraggable(GalaxyButton, GalaxyButton)

local function openPanel()
    State.Closed = false
    Main.Visible = true
    GalaxyButton.Visible = false

    Main.Size = UDim2.fromOffset(0, 0)

    TweenService:Create(
        Main,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)}
    ):Play()
end

local function closePanel()
    State.Closed = true
    Main.Visible = false
    GalaxyButton.Visible = true
end

local function minimizePanel()
    State.Minimized = true
    Main.Visible = false
    GalaxyButton.Visible = true
end

Minimize.MouseButton1Click:Connect(minimizePanel)
Close.MouseButton1Click:Connect(closePanel)
GalaxyButton.MouseButton1Click:Connect(openPanel)

--==================================================
-- CONTENT HELPERS
--==================================================

local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function createTitle(text, description)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, description and 57 or 35)
    holder.Parent = Content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 28)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = UISettings.TextColor
    label.TextSize = 20
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    if description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.fromOffset(0, 28)
        desc.Size = UDim2.new(1, 0, 0, 29)
        desc.Font = Enum.Font.Gotham
        desc.Text = description
        desc.TextColor3 = UISettings.MutedTextColor
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = holder
    end

    return holder
end

local function createButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = UISettings.SecondaryColor
    button.BackgroundTransparency = UISettings.Transparency
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.Text = text
    button.TextColor3 = UISettings.TextColor
    button.TextSize = 13
    button.AutoButtonColor = true
    button.Parent = Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)
    return button
end

local function createToggle(text, value, callback)
    local button = createButton(text .. ": " .. (value and "ON" or "OFF"), function()
        value = not value
        callback(value)
        button.Text = text .. ": " .. (value and "ON" or "OFF")
    end)

    return button
end

local function createValueBox(labelText, value, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 70)
    holder.BackgroundTransparency = 1
    holder.Parent = Content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Font = Enum.Font.GothamSemibold
    label.Text = labelText
    label.TextColor3 = UISettings.TextColor
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local box = Instance.new("TextBox")
    box.Position = UDim2.fromOffset(0, 28)
    box.Size = UDim2.new(1, 0, 0, 36)
    box.BackgroundColor3 = UISettings.SecondaryColor
    box.BackgroundTransparency = UISettings.Transparency
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.Text = tostring(value)
    box.TextColor3 = UISettings.TextColor
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box

    box.FocusLost:Connect(function()
        local number = tonumber(box.Text)
        if number then
            callback(number)
        else
            box.Text = tostring(value)
        end
    end)

    return holder, box
end

local function createInfo(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 50)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = UISettings.MutedTextColor
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = Content
    return label
end

local function playerList()
    local list = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player)
        end
    end

    table.sort(list, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    return list
end

local function createPlayerSelector()
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 88)
    holder.BackgroundTransparency = 1
    holder.Parent = Content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Font = Enum.Font.GothamSemibold
    label.Text = "Target Player"
    label.TextColor3 = UISettings.TextColor
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local selector = Instance.new("TextButton")
    selector.Position = UDim2.fromOffset(0, 28)
    selector.Size = UDim2.new(1, 0, 0, 36)
    selector.BackgroundColor3 = UISettings.SecondaryColor
    selector.BackgroundTransparency = UISettings.Transparency
    selector.BorderSizePixel = 0
    selector.Font = Enum.Font.Gotham
    selector.Text = "Select Player ▼"
    selector.TextColor3 = UISettings.TextColor
    selector.TextSize = 13
    selector.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = selector

    local popup = Instance.new("ScrollingFrame")
    popup.Position = UDim2.new(0, 0, 0, 67)
    popup.Size = UDim2.new(1, 0, 0, 130)
    popup.BackgroundColor3 = UISettings.BackgroundColor
    popup.BackgroundTransparency = UISettings.Transparency
    popup.BorderSizePixel = 0
    popup.ScrollBarThickness = 3
    popup.Visible = false
    popup.ZIndex = 10
    popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
    popup.Parent = holder

    local popupLayout = Instance.new("UIListLayout")
    popupLayout.Padding = UDim.new(0, 3)
    popupLayout.Parent = popup

    local function refresh()
        for _, child in ipairs(popup:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, player in ipairs(playerList()) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -5, 0, 34)
            button.BackgroundColor3 = UISettings.SecondaryColor
            button.BackgroundTransparency = UISettings.Transparency
            button.BorderSizePixel = 0
            button.Font = Enum.Font.Gotham
            button.Text = player.DisplayName .. "  @" .. player.Name
            button.TextColor3 = UISettings.TextColor
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.ZIndex = 11
            button.Parent = popup

            button.MouseButton1Click:Connect(function()
                State.OrbitTarget = player
                State.LockedTarget = player
                selector.Text = player.DisplayName .. "  @" .. player.Name
                popup.Visible = false
            end)
        end
    end

    selector.MouseButton1Click:Connect(function()
        popup.Visible = not popup.Visible
        if popup.Visible then
            refresh()
        end
    end)

    Players.PlayerAdded:Connect(refresh)
    Players.PlayerRemoving:Connect(function(player)
        if State.OrbitTarget == player then
            State.OrbitTarget = nil
        end
        if State.LockedTarget == player then
            State.LockedTarget = nil
        end
        refresh()
    end)

    return holder
end

--==================================================
-- ESP
--==================================================

local ESPObjects = {}

local function removeESP(player)
    local data = ESPObjects[player]
    if not data then
        return
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    ESPObjects[player] = nil
end

local function createESP(player)
    if player == LocalPlayer or not State.ESPEnabled then
        return
    end

    removeESP(player)

    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not character or not head then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "OrbitESP"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = UISettings.OutlineColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OrbitESPName"
    billboard.Size = UDim2.fromOffset(220, 45)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextColor3 = UISettings.TextColor
    text.TextStrokeTransparency = 0.5
    text.TextSize = 13
    text.TextWrapped = true

    local nameText = ""
    if State.ESPNickname then
        nameText = player.DisplayName
    end
    if State.ESPUsername then
        if nameText ~= "" then
            nameText = nameText .. "\n"
        end
        nameText = nameText .. "@" .. player.Name
    end

    text.Text = nameText
    text.Parent = billboard

    ESPObjects[player] = {
        Highlight = highlight,
        Billboard = billboard,
    }
end

local function refreshESP()
    for player in pairs(ESPObjects) do
        removeESP(player)
    end

    if not State.ESPEnabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
end

--==================================================
-- FEATURE PAGES
--==================================================

local FeatureButtons = {}

local function renderMain()
    clearContent()

    createTitle("📌 Main", "General Orbit Panel controls.")

    createToggle("Target Lock", State.TargetLock, function(value)
        State.TargetLock = value
        if not value then
            State.LockedTarget = nil
        end
    end)

    createInfo("Target Lock finds the nearest valid player when no target has been selected.")

    createToggle("Infinite Stamina", State.InfiniteStamina, function(value)
        State.InfiniteStamina = value
    end)

    createInfo("Keeps detected stamina NumberValue/IntValue objects filled while enabled.")

    createButton("📍 Reset Position", function()
        local root = getRoot(LocalPlayer)
        if root and State.SavedCFrame then
            root.CFrame = State.SavedCFrame
        end
    end)

    createButton("💾 Save Current Position", function()
        local root = getRoot(LocalPlayer)
        if root then
            State.SavedCFrame = root.CFrame
            notify("Position saved.")
        end
    end)
end

local function renderESP()
    clearContent()

    createTitle("👁️ ESP", "Highlight players and show their names.")

    createToggle("Player ESP", State.ESPEnabled, function(value)
        State.ESPEnabled = value
        refreshESP()
    end)

    createToggle("Nickname", State.ESPNickname, function(value)
        State.ESPNickname = value
        refreshESP()
    end)

    createToggle("Username", State.ESPUsername, function(value)
        State.ESPUsername = value
        refreshESP()
    end)

    createInfo("ESP uses a white/transparent visual style and displays DisplayName and/or @Username.")
end

local function renderOrbit()
    clearContent()

    createTitle("🌀 Orbit", "Orbit around a selected player with adjustable radius and speed.")

    createPlayerSelector()

    local _, radiusBox = createValueBox(
        "Orbit Radius",
        State.OrbitRadius,
        function(value)
            State.OrbitRadius = math.clamp(value, 1, 100)
        end
    )

    local radiusInfo = createInfo("Change how far you will orbit around a player.")
    radiusInfo.Size = UDim2.new(1, 0, 0, 35)

    local _, speedBox = createValueBox(
        "Orbit Speed",
        State.OrbitSpeed,
        function(value)
            State.OrbitSpeed = math.clamp(value, 0.1, 50)
        end
    )

    local speedInfo = createInfo("Change how fast you will orbit around the selected player.")
    speedInfo.Size = UDim2.new(1, 0, 0, 35)

    createToggle("Turn Off On WalkSpeed 22+", State.AutoOrbitStop, function(value)
        State.AutoOrbitStop = value
    end)

    local status = createInfo(
        "Orbit Status: " .. (State.OrbitEnabled and "ON" or "OFF") ..
        "\nTarget: " .. (State.OrbitTarget and State.OrbitTarget.DisplayName or "None")
    )
    status.Size = UDim2.new(1, 0, 0, 45)

    createButton(State.OrbitEnabled and "⏹ Stop Orbit" or "▶ Start Orbit", function()
        if State.OrbitEnabled then
            State.OrbitEnabled = false
            State.OrbitTarget = nil
        else
            if not State.OrbitTarget then
                State.OrbitTarget = getNearestPlayer()
            end

            if State.OrbitTarget then
                State.OrbitEnabled = true
            else
                notify("No valid target found.")
            end
        end

        renderOrbit()
    end)
end

local function renderAutoPunch()
    clearContent()

    createTitle("👊 Auto Punch", "Automatically activate the equipped Tool in your own experience.")

    createToggle("Auto Punch", State.AutoPunch, function(value)
        State.AutoPunch = value
    end)

    local _, rangeBox = createValueBox(
        "Attack Range",
        State.AutoPunchRange,
        function(value)
            State.AutoPunchRange = math.clamp(value, 1, 100)
        end
    )

    createInfo("Only select a nearby player within this distance for the local targeting logic.")

    local _, intervalBox = createValueBox(
        "Attack Interval",
        State.AutoPunchInterval,
        function(value)
            State.AutoPunchInterval = math.max(value, 0.05)
        end
    )

    createInfo("Time between each Tool activation.")

    createInfo(
        "Status:\nTool Equipped: " ..
        (getEquippedTool() and "Yes" or "No") ..
        "\nTarget: " ..
        ((getNearestPlayer(State.AutoPunchRange) and getNearestPlayer(State.AutoPunchRange).DisplayName) or "None")
    )
end

local function renderTargetLock()
    clearContent()

    createTitle("🎯 Target Lock", "Lock onto a valid player.")

    createToggle("Target Lock", State.TargetLock, function(value)
        State.TargetLock = value
        if not value then
            State.LockedTarget = nil
        end
        renderTargetLock()
    end)

    local target = State.LockedTarget
    createInfo(
        "Current Target: " ..
        (target and target.DisplayName .. "  @" .. target.Name or "None")
    )

    createButton("🎯 Find Nearest Target", function()
        State.LockedTarget = getNearestPlayer()
        renderTargetLock()
    end)

    createButton("Clear Target", function()
        State.LockedTarget = nil
        renderTargetLock()
    end)
end

local function renderStamina()
    clearContent()

    createTitle("♾️ Infinite Stamina", "Client-side stamina testing control for your own experience.")

    createToggle("Infinite Stamina", State.InfiniteStamina, function(value)
        State.InfiniteStamina = value
        renderStamina()
    end)

    createInfo("The script searches PlayerGui and Character for NumberValue/IntValue objects containing 'stamina'.")
end

local function renderResetPosition()
    clearContent()

    createTitle("📍 Reset Position", "Save a position and return to it later.")

    createButton("💾 Save Position", function()
        local root = getRoot(LocalPlayer)
        if root then
            State.SavedCFrame = root.CFrame
            notify("Position saved.")
            renderResetPosition()
        end
    end)

    createButton("📍 Reset Position", function()
        local root = getRoot(LocalPlayer)
        if root and State.SavedCFrame then
            root.CFrame = State.SavedCFrame
        end
    end)

    createInfo(
        "Saved: " .. (State.SavedCFrame and "Yes" or "No")
    )
end

local function renderMisc()
    clearContent()

    createTitle("🧰 Misc", "Extra utility controls.")

    createButton("🔄 Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            LocalPlayer
        )
    end)

    createButton("🌐 Server Hop", function()
        -- Server hopping requires your own server-selection implementation.
        notify("Server Hop placeholder — connect this to your server browser.")
    end)

    createButton("📋 Copy Job ID", function()
        if setclipboard then
            setclipboard(game.JobId)
            notify("Job ID copied.")
        else
            notify("Clipboard API unavailable.")
        end
    end)

    createButton("🎮 Copy Game ID", function()
        if setclipboard then
            setclipboard(tostring(game.GameId))
            notify("Game ID copied.")
        else
            notify("Clipboard API unavailable.")
        end
    end)

    createInfo(
        "FPS and ping can be displayed through the small status labels below."
    )

    local performance = createInfo("FPS: calculating...\nPing: calculating...")
    performance.Size = UDim2.new(1, 0, 0, 45)

    task.spawn(function()
        while performance.Parent do
            local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 1 / 240))
            local ping = "?"
            pcall(function()
                ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
            end)

            if performance.Parent then
                performance.Text = "FPS: " .. fps .. "\nPing: " .. ping
            end
        end
    end)
end

local function applySettings()
    Main.BackgroundColor3 = UISettings.BackgroundColor
    Main.BackgroundTransparency = UISettings.BackgroundTransparency

    MainStroke.Color = UISettings.OutlineColor
    MainStroke.Transparency = UISettings.OutlineEnabled and 0 or 1

    TopBar.BackgroundColor3 = UISettings.SecondaryColor
    TopBar.BackgroundTransparency = UISettings.Transparency

    Sidebar.BackgroundColor3 = UISettings.SecondaryColor
    Sidebar.BackgroundTransparency = UISettings.Transparency

    GalaxyButton.BackgroundColor3 = UISettings.SecondaryColor
    GalaxyButton.BackgroundTransparency = UISettings.Transparency
    GalaxyStroke.Color = UISettings.OutlineColor

    for _, button in pairs(FeatureButtons) do
        button.BackgroundColor3 = UISettings.SecondaryColor
        button.BackgroundTransparency = UISettings.Transparency
        button.TextColor3 = UISettings.TextColor
    end

    refreshESP()
end

local function renderSettings()
    clearContent()

    createTitle("⚙️ Settings", "Customize Orbit Panel V3 in real time.")

    createInfo("The controls below are intended to update the UI immediately.")

    createValueBox("UI Width", UISettings.Width, function(value)
        UISettings.Width = math.clamp(value, 350, 900)
        Main.Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)
    end)

    createValueBox("UI Height", UISettings.Height, function(value)
        UISettings.Height = math.clamp(value, 250, 700)
        Main.Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)
    end)

    createValueBox("Transparency (0 - 1)", UISettings.Transparency, function(value)
        UISettings.Transparency = math.clamp(value, 0, 1)
        applySettings()
    end)

    createValueBox("Background Transparency (0 - 1)", UISettings.BackgroundTransparency, function(value)
        UISettings.BackgroundTransparency = math.clamp(value, 0, 1)
        applySettings()
    end)

    createToggle("Outline", UISettings.OutlineEnabled, function(value)
        UISettings.OutlineEnabled = value
        applySettings()
    end)

    createButton("🎨 Cycle UI Color", function()
        if UISettings.BackgroundColor == Color3.fromRGB(22, 16, 35) then
            UISettings.BackgroundColor = Color3.fromRGB(15, 30, 45)
            UISettings.SecondaryColor = Color3.fromRGB(22, 45, 62)
        elseif UISettings.BackgroundColor == Color3.fromRGB(15, 30, 45) then
            UISettings.BackgroundColor = Color3.fromRGB(35, 22, 22)
            UISettings.SecondaryColor = Color3.fromRGB(55, 32, 32)
        else
            UISettings.BackgroundColor = Color3.fromRGB(22, 16, 35)
            UISettings.SecondaryColor = Color3.fromRGB(31, 23, 48)
        end

        applySettings()
    end)

    createButton("🎨 Cycle Outline Color", function()
        if UISettings.OutlineColor == Color3.fromRGB(210, 170, 255) then
            UISettings.OutlineColor = Color3.fromRGB(120, 220, 255)
        elseif UISettings.OutlineColor == Color3.fromRGB(120, 220, 255) then
            UISettings.OutlineColor = Color3.fromRGB(255, 180, 180)
        else
            UISettings.OutlineColor = Color3.fromRGB(210, 170, 255)
        end

        applySettings()
    end)

    createButton("🔄 Reset UI Settings", function()
        UISettings.BackgroundColor = Color3.fromRGB(22, 16, 35)
        UISettings.SecondaryColor = Color3.fromRGB(31, 23, 48)
        UISettings.OutlineColor = Color3.fromRGB(210, 170, 255)
        UISettings.Transparency = 0.08
        UISettings.BackgroundTransparency = 0.08
        UISettings.OutlineEnabled = true
        UISettings.Width = 560
        UISettings.Height = 390

        Main.Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)
        applySettings()
        renderSettings()
    end)
end

local function renderInformation()
    clearContent()

    createTitle("ℹ️ Information", "Orbit Panel V3 overview.")

    createInfo([[
🌌 Orbit Panel V3

A redesigned panel using a two-sided layout:

LEFT
Feature selector.

RIGHT
Controls for the selected feature.

V3 keeps the useful V2.1 and V2.2 features while removing the old Orbit presets.

Orbit Presets:
REMOVED

Built with Roblox Lua.
]])

    createInfo("🌀 Orbit — adjustable radius, speed, target and auto-stop.")
    createInfo("👁️ ESP — player highlights and name display.")
    createInfo("👊 Auto Punch — equipped-tool testing control.")
    createInfo("🎯 Target Lock — target selection and nearest-target logic.")
    createInfo("⚙️ Settings — live UI customization.")
end

local function renderCredits()
    clearContent()

    createTitle("💳 Credits", "Orbit Panel V3.")

    createInfo([[
🌌 ORBIT PANEL V3

Created & Developed by
Franz 🔥

UI Design
Designed by Franz

Scripting & Development
Built with Roblox Lua

Special Thanks
Thanks to everyone who tested
Orbit Panel and gave feedback 🤝

Version
Orbit Panel V3

"Built from an idea into reality."
]])
end

local Renderers = {
    Main = renderMain,
    ESP = renderESP,
    Orbit = renderOrbit,
    ["Auto Punch"] = renderAutoPunch,
    ["Target Lock"] = renderTargetLock,
    ["Infinite Stamina"] = renderStamina,
    ["Reset Position"] = renderResetPosition,
    Misc = renderMisc,
    Settings = renderSettings,
    Information = renderInformation,
    Credits = renderCredits,
}

--==================================================
-- SIDEBAR
--==================================================

local FeatureList = {
    "📌 Main",
    "👁️ ESP",
    "🌀 Orbit",
    "👊 Auto Punch",
    "🎯 Target Lock",
    "♾️ Infinite Stamina",
    "📍 Reset Position",
    "🧰 Misc",
    "⚙️ Settings",
    "ℹ️ Information",
    "💳 Credits",
}

local FeatureMap = {
    ["📌 Main"] = "Main",
    ["👁️ ESP"] = "ESP",
    ["🌀 Orbit"] = "Orbit",
    ["👊 Auto Punch"] = "Auto Punch",
    ["🎯 Target Lock"] = "Target Lock",
    ["♾️ Infinite Stamina"] = "Infinite Stamina",
    ["📍 Reset Position"] = "Reset Position",
    ["🧰 Misc"] = "Misc",
    ["⚙️ Settings"] = "Settings",
    ["ℹ️ Information"] = "Information",
    ["💳 Credits"] = "Credits",
}

local function selectFeature(featureName)
    State.CurrentFeature = featureName

    for name, button in pairs(FeatureButtons) do
        if name == featureName then
            button.BackgroundColor3 = UISettings.AccentColor
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = UISettings.SecondaryColor
            button.TextColor3 = UISettings.TextColor
        end
    end

    local renderer = Renderers[featureName]
    if renderer then
        renderer()
    end
end

for index, displayName in ipairs(FeatureList) do
    local featureName = FeatureMap[displayName]

    local button = Instance.new("TextButton")
    button.Name = featureName
    button.LayoutOrder = index
    button.Size = UDim2.new(1, 0, 0, 34)
    button.BackgroundColor3 = UISettings.SecondaryColor
    button.BackgroundTransparency = UISettings.Transparency
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.Text = displayName
    button.TextColor3 = UISettings.TextColor
    button.TextSize = 12
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = Sidebar

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Name = "SelectionOutline"
    stroke.Color = UISettings.OutlineColor
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = button

    button.MouseButton1Click:Connect(function()
        selectFeature(featureName)
    end)

    FeatureButtons[featureName] = button
end

-- Override selection visuals with outline as well.
local originalSelectFeature = selectFeature
selectFeature = function(featureName)
    State.CurrentFeature = featureName

    for name, button in pairs(FeatureButtons) do
        local stroke = button:FindFirstChild("SelectionOutline")

        if name == featureName then
            button.BackgroundColor3 = UISettings.AccentColor
            if stroke then
                stroke.Color = UISettings.OutlineColor
                stroke.Transparency = 0
            end
        else
            button.BackgroundColor3 = UISettings.SecondaryColor
            if stroke then
                stroke.Transparency = 1
            end
        end

        button.TextColor3 = UISettings.TextColor
    end

    local renderer = Renderers[featureName]
    if renderer then
        renderer()
    end
end

--==================================================
-- GAME LOOPS
--==================================================

Connections.Orbit = RunService.Heartbeat:Connect(function()
    if not State.OrbitEnabled then
        return
    end

    local target = State.OrbitTarget

    if not target or not isAlive(target) then
        State.OrbitEnabled = false
        State.OrbitTarget = nil
        return
    end

    local myRoot = getRoot(LocalPlayer)
    local targetRoot = getRoot(target)
    local humanoid = getHumanoid(LocalPlayer)

    if not myRoot or not targetRoot then
        return
    end

    if State.AutoOrbitStop and humanoid and humanoid.WalkSpeed >= 22 then
        State.OrbitEnabled = false
        return
    end

    local angle = os.clock() * State.OrbitSpeed
    local offset = Vector3.new(
        math.cos(angle) * State.OrbitRadius,
        0,
        math.sin(angle) * State.OrbitRadius
    )

    myRoot.CFrame = CFrame.lookAt(
        targetRoot.Position + offset,
        targetRoot.Position
    )
end)

Connections.TargetLock = RunService.Heartbeat:Connect(function()
    if not State.TargetLock then
        return
    end

    if not State.LockedTarget or not isAlive(State.LockedTarget) then
        State.LockedTarget = getNearestPlayer()
    end
end)

Connections.InfiniteStamina = RunService.Heartbeat:Connect(function()
    if not State.InfiniteStamina then
        return
    end

    local containers = {
        PlayerGui,
        LocalPlayer.Character,
    }

    for _, container in ipairs(containers) do
        if container then
            for _, object in ipairs(container:GetDescendants()) do
                if (object:IsA("NumberValue") or object:IsA("IntValue"))
                    and object.Name:lower():find("stamina") then

                    local maxStamina = object:GetAttribute("MaxStamina") or 100

                    pcall(function()
                        object.Value = maxStamina
                    end)
                end
            end
        end
    end
end)

Connections.AutoPunch = RunService.Heartbeat:Connect(function()
    if not State.AutoPunch then
        return
    end

    local tool = getEquippedTool()
    if not tool then
        return
    end

    if not State._LastPunch then
        State._LastPunch = 0
    end

    if os.clock() - State._LastPunch < State.AutoPunchInterval then
        return
    end

    local target = getNearestPlayer(State.AutoPunchRange)

    if target then
        State._LastPunch = os.clock()
        activateEquippedTool()
    end
end)

--==================================================
-- CHARACTER / PLAYER EVENTS
--==================================================

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and not State.SavedCFrame then
        State.SavedCFrame = root.CFrame
    end

    refreshESP()
end)

Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.ESPEnabled then
            createESP(player)
        end
    end)
end)

Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
    removeESP(player)

    if State.OrbitTarget == player then
        State.OrbitTarget = nil
        State.OrbitEnabled = false
    end

    if State.LockedTarget == player then
        State.LockedTarget = nil
    end
end)

--==================================================
-- DELETE / CLEANUP
--==================================================

local function deletePanel()
    cleanup()

    for player in pairs(ESPObjects) do
        removeESP(player)
    end

    ScreenGui:Destroy()
end

-- Rebind Close to actual delete behavior.
Close.MouseButton1Click:Connect(deletePanel)

--==================================================
-- STARTUP
--==================================================

local root = getRoot(LocalPlayer)
if root then
    State.SavedCFrame = root.CFrame
end

selectFeature("Main")

Main.Size = UDim2.fromOffset(0, 0)

TweenService:Create(
    Main,
    TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.fromOffset(UISettings.Width, UISettings.Height)}
):Play()

notify("Orbit Panel V3 loaded.")
