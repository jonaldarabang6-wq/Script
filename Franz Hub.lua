--========================================================--
--                 K L A S E   P A N E L                 --
--                    UI / LOCAL SCRIPT                  --
--========================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- SETTINGS
--========================================================--

local Settings = {
    InfiniteStamina = false,
    ESP = false,
    AutoPunch = false,
    Orbit = false,
    AutoDodge = false,

    OrbitRadius = 15,
    OrbitSpeed = 5,
    OrbitTarget = nil,

    RainbowESP = true,
    ESPHealth = true,
    ESPNicknames = true,
}

--========================================================--
-- REMOVE OLD UI
--========================================================--

local old = PlayerGui:FindFirstChild("KlasePanel")

if old then
    old:Destroy()
end

--========================================================--
-- SCREEN GUI
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KlasePanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

--========================================================--
-- MAIN PANEL
--========================================================--

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 430, 0, 280)
Main.Position = UDim2.new(0.5, -215, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.25
MainStroke.Parent = Main

--========================================================--
-- TOP BAR
--========================================================--

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Size = UDim2.new(1, -130, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "KLASE PANEL"
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Parent = TopBar

--========================================================--
-- TOP BUTTONS
--========================================================--

local function createTopButton(text, x)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(0, 30, 0, 30)
    button.Position = UDim2.new(1, x, 0, 6)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(220, 220, 225)
    button.AutoButtonColor = false
    button.Parent = TopBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    return button
end

local MinimizeButton = createTopButton("—", -98)
local CloseButton = createTopButton("×", -62)
local RemoveButton = createTopButton("✕", -26)

--========================================================--
-- SIDEBAR
--========================================================--

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.new(0, 8, 0, 50)
Sidebar.Size = UDim2.new(0, 118, 1, -58)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 9)
SidebarCorner.Parent = Sidebar

local FeatureTitle = Instance.new("TextLabel")
FeatureTitle.BackgroundTransparency = 1
FeatureTitle.Position = UDim2.new(0, 10, 0, 7)
FeatureTitle.Size = UDim2.new(1, -20, 0, 22)
FeatureTitle.Font = Enum.Font.GothamBold
FeatureTitle.Text = "FEATURES"
FeatureTitle.TextSize = 10
FeatureTitle.TextColor3 = Color3.fromRGB(130, 130, 140)
FeatureTitle.TextXAlignment = Enum.TextXAlignment.Left
FeatureTitle.Parent = Sidebar

local FeatureList = Instance.new("ScrollingFrame")
FeatureList.Position = UDim2.new(0, 6, 0, 32)
FeatureList.Size = UDim2.new(1, -12, 1, -38)
FeatureList.BackgroundTransparency = 1
FeatureList.BorderSizePixel = 0
FeatureList.ScrollBarThickness = 2
FeatureList.Parent = Sidebar

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = FeatureList

--========================================================--
-- CONTENT
--========================================================--

local Content = Instance.new("Frame")
Content.Position = UDim2.new(0, 134, 0, 50)
Content.Size = UDim2.new(1, -142, 1, -58)
Content.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
Content.BorderSizePixel = 0
Content.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 9)
ContentCorner.Parent = Content

local ContentTitle = Instance.new("TextLabel")
ContentTitle.BackgroundTransparency = 1
ContentTitle.Position = UDim2.new(0, 14, 0, 10)
ContentTitle.Size = UDim2.new(1, -28, 0, 25)
ContentTitle.Font = Enum.Font.GothamBold
ContentTitle.Text = "Welcome"
ContentTitle.TextSize = 16
ContentTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = Content

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Position = UDim2.new(0, 10, 0, 42)
ContentScroll.Size = UDim2.new(1, -20, 1, -50)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 2
ContentScroll.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

--========================================================--
-- HELPERS
--========================================================--

local function clearContent()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function createLabel(text, size)
    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1, -4, 0, size or 28)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextSize = 11
    label.TextColor3 = Color3.fromRGB(170, 170, 180)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = ContentScroll

    return label
end

local function createToggle(text, enabled, callback)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -4, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 11
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Parent = ContentScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    local state = enabled

    local function update()
        button.Text = "   " .. text .. "     " .. (state and "ON" or "OFF")

        if state then
            button.TextColor3 = Color3.fromRGB(150, 255, 170)
            button.BackgroundColor3 = Color3.fromRGB(28, 48, 34)
        else
            button.TextColor3 = Color3.fromRGB(190, 190, 200)
            button.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
        end
    end

    update()

    button.MouseButton1Click:Connect(function()
        state = not state

        callback(state)
        update()
    end)

    return button
end

local function createValueButton(text, value, callback)
    local holder = Instance.new("Frame")

    holder.Size = UDim2.new(1, -4, 0, 38)
    holder.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
    holder.BorderSizePixel = 0
    holder.Parent = ContentScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = holder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.Text = text
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(205, 205, 215)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0.55, 0, 0, 0)
    valueLabel.Size = UDim2.new(0.45, -10, 1, 0)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(value)
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = holder

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 25, 0, 25)
    minus.Position = UDim2.new(1, -62, 0, 6)
    minus.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    minus.Text = "-"
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.Parent = holder

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 25, 0, 25)
    plus.Position = UDim2.new(1, -32, 0, 6)
    plus.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    plus.Text = "+"
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.Parent = holder

    minus.MouseButton1Click:Connect(function()
        value = math.max(1, value - 1)
        valueLabel.Text = tostring(value)
        callback(value)
    end)

    plus.MouseButton1Click:Connect(function()
        value += 1
        valueLabel.Text = tostring(value)
        callback(value)
    end)

    return holder
end

--========================================================--
-- FEATURE BUTTONS
--========================================================--

local featureButtons = {}
local featurePages = {}

local function createFeatureButton(name, icon)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -4, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
    button.BorderSizePixel = 0
    button.Text = icon .. "  " .. name
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 10
    button.TextColor3 = Color3.fromRGB(185, 185, 195)
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Parent = FeatureList

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    featureButtons[name] = button

    return button
end

createFeatureButton("Stamina", "⚡")
createFeatureButton("ESP", "👁")
createFeatureButton("Auto Punch", "👊")
createFeatureButton("Orbit", "🌀")
createFeatureButton("Auto Dodge", "🥷")

--========================================================--
-- PAGES
--========================================================--

featurePages.Stamina = function()
    clearContent()

    ContentTitle.Text = "⚡ Infinite Stamina"

    createLabel(
        "Keeps your stamina at its maximum value.",
        42
    )

    createToggle(
        "Infinite Stamina",
        Settings.InfiniteStamina,
        function(state)
            Settings.InfiniteStamina = state
        end
    )
end

featurePages.ESP = function()
    clearContent()

    ContentTitle.Text = "👁 ESP"

    createLabel(
        "Player information and full-body highlighting.",
        32
    )

    createToggle(
        "Rainbow Full-Body",
        Settings.RainbowESP,
        function(state)
            Settings.RainbowESP = state
        end
    )

    createToggle(
        "Player Nicknames",
        Settings.ESPNicknames,
        function(state)
            Settings.ESPNicknames = state
        end
    )

    createToggle(
        "Health Display",
        Settings.ESPHealth,
        function(state)
            Settings.ESPHealth = state
        end
    )
end

featurePages["Auto Punch"] = function()
    clearContent()

    ContentTitle.Text = "👊 Auto Punch"

    createLabel(
        "Automatically activates the equipped Tool when a target is inside the aura range.",
        50
    )

    createToggle(
        "Auto Punch",
        Settings.AutoPunch,
        function(state)
            Settings.AutoPunch = state
        end
    )

    createValueButton(
        "Aura Range",
        Settings.AuraRange or 15,
        function(value)
            Settings.AuraRange = value
        end
    )
end

featurePages.Orbit = function()
    clearContent()

    ContentTitle.Text = "🌀 Orbit"

    createToggle(
        "Orbit",
        Settings.Orbit,
        function(state)
            Settings.Orbit = state
        end
    )

    createValueButton(
        "Orbit Radius",
        Settings.OrbitRadius,
        function(value)
            Settings.OrbitRadius = value
        end
    )

    createValueButton(
        "Orbit Speed",
        Settings.OrbitSpeed,
        function(value)
            Settings.OrbitSpeed = value
        end
    )

    createLabel(
        "Current Target: " ..
        (Settings.OrbitTarget and Settings.OrbitTarget.Name or "None"),
        30
    )

    createLabel(
        "TARGETS — A-Z",
        24
    )

    local targetPlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(targetPlayers, player)
        end
    end

    table.sort(targetPlayers, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)

    for _, player in ipairs(targetPlayers) do
        local targetButton = Instance.new("TextButton")

        targetButton.Size = UDim2.new(1, -4, 0, 34)
        targetButton.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
        targetButton.BorderSizePixel = 0
        targetButton.Text = "   " .. player.Name
        targetButton.Font = Enum.Font.GothamSemibold
        targetButton.TextSize = 10
        targetButton.TextColor3 = Color3.fromRGB(200, 200, 210)
        targetButton.TextXAlignment = Enum.TextXAlignment.Left
        targetButton.AutoButtonColor = false
        targetButton.Parent = ContentScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = targetButton

        targetButton.MouseButton1Click:Connect(function()
            Settings.OrbitTarget = player

            for _, object in ipairs(ContentScroll:GetChildren()) do
                if object:IsA("TextButton") then
                    object.BackgroundColor3 =
                        Color3.fromRGB(31, 31, 38)
                end
            end

            targetButton.BackgroundColor3 =
                Color3.fromRGB(40, 65, 48)
        end)
    end
end

featurePages["Auto Dodge"] = function()
    clearContent()

    ContentTitle.Text = "🥷 Auto Dodge"

    createLabel(
        "Detect incoming attacks and prioritize a directional dodge.",
        45
    )

    createToggle(
        "Auto Dodge",
        Settings.AutoDodge,
        function(state)
            Settings.AutoDodge = state
        end
    )

    createLabel(
        "Emergency displacement: only when attacker is 1–2 studs away.",
        42
    )

    createLabel(
        "Return delay: 0.25 seconds.",
        28
    )
end

--========================================================--
-- PAGE SELECTION
--========================================================--

local selectedFeature

local function selectFeature(name)
    selectedFeature = name

    for featureName, button in pairs(featureButtons) do
        if featureName == name then
            button.BackgroundColor3 =
                Color3.fromRGB(45, 55, 65)

            button.TextColor3 =
                Color3.fromRGB(235, 240, 245)
        else
            button.BackgroundColor3 =
                Color3.fromRGB(27, 27, 33)

            button.TextColor3 =
                Color3.fromRGB(185, 185, 195)
        end
    end

    if featurePages[name] then
        featurePages[name]()
    end
end

for name, button in pairs(featureButtons) do
    button.MouseButton1Click:Connect(function()
        selectFeature(name)
    end)
end

--========================================================--
-- FLOATING BUTTON
--========================================================--

local FloatingButton = Instance.new("TextButton")

FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.new(0, 52, 0, 52)
FloatingButton.Position = UDim2.new(0, 20, 0.5, -26)
FloatingButton.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "K"
FloatingButton.Font = Enum.Font.GothamBlack
FloatingButton.TextSize = 20
FloatingButton.TextColor3 = Color3.fromRGB(235, 235, 240)
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingButton

--========================================================--
-- DRAGGING
--========================================================--

local function makeDraggable(object)
    local dragging = false
    local dragStart
    local startPosition

    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
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

makeDraggable(TopBar)
makeDraggable(FloatingButton)

--========================================================--
-- MINIMIZE
--========================================================--

MinimizeButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingButton.Visible = true
end)

FloatingButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    FloatingButton.Visible = false
end)

--========================================================--
-- CLOSE
--========================================================--

CloseButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingButton.Visible = true
end)

--========================================================--
-- REMOVE
--========================================================--

RemoveButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--========================================================--
-- DEFAULT PAGE
--========================================================--

selectFeature("Stamina")

--========================================================--
-- OPEN ANIMATION
--========================================================--

Main.Size = UDim2.new(0, 390, 0, 250)

TweenService:Create(
    Main,
    TweenInfo.new(
        0.35,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ),
    {
        Size = UDim2.new(0, 430, 0, 280)
    }
):Play()