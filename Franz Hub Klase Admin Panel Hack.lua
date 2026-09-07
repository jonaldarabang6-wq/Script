--// K L A S E   P A N E L
--// LocalScript
--// Real UI + ESP + Orbit + Stamina Lock + Auto Punch

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    InfiniteStamina = false,
    ESP = false,
    ESPNicknames = true,
    ESPHealth = true,
    RainbowESP = true,

    AutoPunch = false,
    AuraRange = 15,

    Orbit = false,
    OrbitRadius = 15,
    OrbitSpeed = 5,
    OrbitTarget = nil,
}

--==================================================
-- CLEAN OLD PANEL
--==================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("KlasePanel")
if old then
    old:Destroy()
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KlasePanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(520, 330)
Main.Position = UDim2.new(0.5, -260, 0.5, -165)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(70, 70, 80)
Stroke.Parent = Main

--==================================================
-- TOP BAR
--==================================================

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -150, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "KLASE PANEL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(40, 32)
Minimize.Position = UDim2.new(1, -90, 0, 7)
Minimize.BackgroundTransparency = 1
Minimize.Text = "—"
Minimize.TextSize = 22
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = TopBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(40, 32)
Close.Position = UDim2.new(1, -45, 0, 7)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextSize = 24
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.Parent = TopBar

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 135, 1, -45)
Sidebar.Position = UDim2.fromOffset(0, 45)
Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local FeatureList = Instance.new("ScrollingFrame")
FeatureList.Size = UDim2.new(1, -10, 1, -10)
FeatureList.Position = UDim2.fromOffset(5, 5)
FeatureList.BackgroundTransparency = 1
FeatureList.BorderSizePixel = 0
FeatureList.ScrollBarThickness = 3
FeatureList.CanvasSize = UDim2.new()
FeatureList.Parent = Sidebar

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = FeatureList

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -135, 1, -45)
Content.Position = UDim2.fromOffset(135, 45)
Content.BackgroundTransparency = 1
Content.Parent = Main

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -12, 1, -12)
ContentScroll.Position = UDim2.fromOffset(6, 6)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.CanvasSize = UDim2.new()
ContentScroll.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.Parent = ContentScroll

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.fromOffset(
        0,
        ContentLayout.AbsoluteContentSize.Y + 15
    )
end)

--==================================================
-- HELPERS
--==================================================

local function clearContent()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function label(text, size)
    local x = Instance.new("TextLabel")
    x.Size = UDim2.new(1, -10, 0, size or 30)
    x.BackgroundTransparency = 1
    x.Text = text
    x.TextColor3 = Color3.new(1, 1, 1)
    x.TextSize = 15
    x.Font = Enum.Font.Gotham
    x.TextWrapped = true
    x.TextXAlignment = Enum.TextXAlignment.Left
    x.Parent = ContentScroll
    return x
end

local function button(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = true
    b.Parent = ContentScroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b

    return b
end

local function toggle(text, getter, setter)
    local b

    local function update()
        b.Text = text .. (getter() and "  [ON]" or "  [OFF]")
    end

    b = button("")
    update()

    b.MouseButton1Click:Connect(function()
        setter(not getter())
        update()
    end)

    return b
end

--==================================================
-- ESP
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "KlaseESP"
ESPFolder.Parent = ScreenGui

local ESPObjects = {}

local function removeESP(player)
    local data = ESPObjects[player]

    if data then
        for _, object in pairs(data) do
            if typeof(object) == "Instance" then
                object:Destroy()
            end
        end

        ESPObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    removeESP(player)

    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")

    if not humanoid or not head then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "KlaseHighlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0
    highlight.Parent = ESPFolder

    -- Nickname + health
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KlaseInfo"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(150, 45)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESPFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local healthBack = Instance.new("Frame")
    healthBack.Size = UDim2.new(0.8, 0, 0, 7)
    healthBack.Position = UDim2.new(0.1, 0, 0, 25)
    healthBack.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    healthBack.BorderSizePixel = 0
    healthBack.Parent = billboard

    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(1, 0)
    healthCorner.Parent = healthBack

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.fromScale(1, 1)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBack

    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(1, 0)
    healthBarCorner.Parent = healthBar

    ESPObjects[player] = {
        Highlight = highlight,
        Billboard = billboard,
        HealthBar = healthBar,
        Humanoid = humanoid,
    }
end

local function updateESP()
    if not Settings.ESP then
        for player in pairs(ESPObjects) do
            removeESP(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPObjects[player]
                or not ESPObjects[player].Humanoid
                or not ESPObjects[player].Humanoid.Parent
            then
                createESP(player)
            end

            local data = ESPObjects[player]

            if data then
                local humanoid = data.Humanoid
                local health = math.max(humanoid.Health, 0)
                local maxHealth = math.max(humanoid.MaxHealth, 1)
                local percentage = math.clamp(health / maxHealth, 0, 1)

                data.HealthBar.Size = UDim2.new(
                    percentage,
                    0,
                    1,
                    0
                )

                if percentage >= 0.5 then
                    data.HealthBar.BackgroundColor3 =
                        Color3.fromRGB(70, 220, 90)
                elseif percentage >= 0.25 then
                    data.HealthBar.BackgroundColor3 =
                        Color3.fromRGB(255, 170, 50)
                elseif percentage > 0 then
                    data.HealthBar.BackgroundColor3 =
                        Color3.fromRGB(230, 60, 60)
                else
                    data.HealthBar.BackgroundColor3 =
                        Color3.fromRGB(80, 80, 80)
                end

                data.Billboard.Enabled =
                    Settings.ESPNicknames or Settings.ESPHealth
            end
        end
    end
end

local function setESP(enabled)
    Settings.ESP = enabled

    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            createESP(player)
        end
    else
        for player in pairs(ESPObjects) do
            removeESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if Settings.ESP then
            createESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)

            if Settings.ESP then
                createESP(player)
            end
        end)
    end
end

-- Rainbow effect
task.spawn(function()
    while ScreenGui.Parent do
        local hue = (os.clock() * 0.15) % 1
        local rainbow = Color3.fromHSV(hue, 1, 1)

        for _, data in pairs(ESPObjects) do
            if data.Highlight then
                data.Highlight.FillColor = rainbow
                data.Highlight.OutlineColor = rainbow
            end
        end

        task.wait(0.03)
    end
end)

RunService.RenderStepped:Connect(updateESP)

--==================================================
-- INFINITE STAMINA
--==================================================

local staminaConnections = {}

local function lockStamina(valueObject)
    if staminaConnections[valueObject] then
        return
    end

    staminaConnections[valueObject] =
        valueObject:GetPropertyChangedSignal("Value"):Connect(function()

            if not Settings.InfiniteStamina then
                return
            end

            local maxStamina =
                valueObject:GetAttribute("MaxStamina")

            if typeof(maxStamina) ~= "number" then
                maxStamina = 100
            end

            valueObject.Value = maxStamina
        end)

    local maxStamina =
        valueObject:GetAttribute("MaxStamina")

    if typeof(maxStamina) ~= "number" then
        maxStamina = 100
    end

    valueObject.Value = maxStamina
end

local function scanForStamina()
    local character = LocalPlayer.Character
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("NumberValue") or object:IsA("IntValue") then
            if string.find(
                string.lower(object.Name),
                "stamina"
            ) then
                lockStamina(object)
            end
        end
    end

    for _, object in ipairs(PlayerGui:GetDescendants()) do
        if object:IsA("NumberValue") or object:IsA("IntValue") then
            if string.find(
                string.lower(object.Name),
                "stamina"
            ) then
                lockStamina(object)
            end
        end
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        if Settings.InfiniteStamina then
            scanForStamina()
        end

        task.wait(0.1)
    end
end)

--==================================================
-- AUTO PUNCH
--==================================================

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.1)

        if not Settings.AutoPunch then
            continue
        end

        local character = LocalPlayer.Character
        if not character then
            continue
        end

        local myRoot =
            character:FindFirstChild("HumanoidRootPart")

        local tool =
            character:FindFirstChildOfClass("Tool")

        if not myRoot or not tool then
            continue
        end

        for _, enemy in ipairs(Players:GetPlayers()) do
            if enemy ~= LocalPlayer and enemy.Character then

                local enemyRoot =
                    enemy.Character:FindFirstChild("HumanoidRootPart")

                local humanoid =
                    enemy.Character:FindFirstChildOfClass("Humanoid")

                if enemyRoot and humanoid and humanoid.Health > 0 then

                    local distance =
                        (myRoot.Position - enemyRoot.Position).Magnitude

                    if distance <= Settings.AuraRange then
                        tool:Activate()
                        break
                    end
                end
            end
        end
    end
end)

--==================================================
-- ORBIT
--==================================================

RunService.RenderStepped:Connect(function()
    if not Settings.Orbit then
        return
    end

    local target = Settings.OrbitTarget

    if not target
        or not target.Parent
        or not target.Character
    then
        return
    end

    local myCharacter = LocalPlayer.Character
    if not myCharacter then
        return
    end

    local myRoot =
        myCharacter:FindFirstChild("HumanoidRootPart")

    local targetRoot =
        target.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot or not targetRoot then
        return
    end

    local angle =
        os.clock() * Settings.OrbitSpeed

    local offset = Vector3.new(
        math.cos(angle) * Settings.OrbitRadius,
        0,
        math.sin(angle) * Settings.OrbitRadius
    )

    local position =
        targetRoot.Position + offset

    myRoot.CFrame =
        CFrame.lookAt(position, targetRoot.Position)
end)

--==================================================
-- PAGES
--==================================================

local FeatureButtons = {}

local function createFeatureButton(name, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -5, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    b.BorderSizePixel = 0
    b.Text = icon .. "  " .. name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamMedium
    b.Parent = FeatureList

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b

    FeatureButtons[name] = b

    return b
end

local function showPage(name)

    clearContent()

    for featureName, b in pairs(FeatureButtons) do
        if featureName == name then
            b.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        else
            b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        end
    end

    if name == "Stamina" then

        label("⚡ INFINITE STAMINA", 35)

        toggle(
            "Infinite Stamina",
            function()
                return Settings.InfiniteStamina
            end,
            function(value)
                Settings.InfiniteStamina = value
            end
        )

        label(
            "Locks detected NumberValue/IntValue stamina values to MaxStamina.",
            50
        )

    elseif name == "ESP" then

        label("👁 ESP SETTINGS", 35)

        local espToggle = toggle(
            "ESP",
            function()
                return Settings.ESP
            end,
            setESP
        )

        toggle(
            "Nicknames",
            function()
                return Settings.ESPNicknames
            end,
            function(value)
                Settings.ESPNicknames = value
            end
        )

        toggle(
            "Health",
            function()
                return Settings.ESPHealth
            end,
            function(value)
                Settings.ESPHealth = value
            end
        )

        toggle(
            "Rainbow",
            function()
                return Settings.RainbowESP
            end,
            function(value)
                Settings.RainbowESP = value
            end
        )

    elseif name == "Auto Punch" then

        label("👊 AUTO PUNCH", 35)

        toggle(
            "Auto Punch",
            function()
                return Settings.AutoPunch
            end,
            function(value)
                Settings.AutoPunch = value
            end
        )

        label(
            "Automatically activates your equipped Tool when another player is within range.",
            55
        )

        local range = button(
            "Aura Range: " .. Settings.AuraRange
        )

        range.MouseButton1Click:Connect(function()
            Settings.AuraRange += 5

            if Settings.AuraRange > 50 then
                Settings.AuraRange = 5
            end

            range.Text =
                "Aura Range: " .. Settings.AuraRange
        end)

    elseif name == "Orbit" then

        label("🌀 ORBIT", 35)

        toggle(
            "Orbit",
            function()
                return Settings.Orbit
            end,
            function(value)
                Settings.Orbit = value
            end
        )

        local radius = button(
            "Orbit Radius: " .. Settings.OrbitRadius
        )

        radius.MouseButton1Click:Connect(function()
            Settings.OrbitRadius += 5

            if Settings.OrbitRadius > 50 then
                Settings.OrbitRadius = 5
            end

            radius.Text =
                "Orbit Radius: " .. Settings.OrbitRadius
        end)

        local speed = button(
            "Orbit Speed: " .. Settings.OrbitSpeed
        )

        speed.MouseButton1Click:Connect(function()
            Settings.OrbitSpeed += 1

            if Settings.OrbitSpeed > 15 then
                Settings.OrbitSpeed = 1
            end

            speed.Text =
                "Orbit Speed: " .. Settings.OrbitSpeed
        end)

        label(
            "Select a player:",
            30
        )

        local players = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(players, player)
            end
        end

        table.sort(players, function(a, b)
            return a.DisplayName:lower()
                < b.DisplayName:lower()
        end)

        for _, player in ipairs(players) do

            local targetButton =
                button("○ " .. player.DisplayName)

            targetButton.MouseButton1Click:Connect(function()

                Settings.OrbitTarget = player

                for _, child in ipairs(ContentScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.TextColor3 =
                            Color3.new(1, 1, 1)
                    end
                end

                targetButton.TextColor3 =
                    Color3.fromRGB(80, 220, 255)

                targetButton.Text =
                    "● " .. player.DisplayName
            end)
        end

    elseif name == "Auto Dodge" then

        label("🥷 AUTO DODGE", 35)

        label(
            "Auto Dodge requires Klase's actual client-side attack/damage detection. I am not inventing a RemoteEvent or pretending this part works without that information.",
            90
        )

        label(
            "Once the real attack detector is available, it can be connected here without changing the UI.",
            70
        )
    end
end

--==================================================
-- FEATURE BUTTONS
--==================================================

local staminaButton =
    createFeatureButton("Stamina", "⚡")

local espButton =
    createFeatureButton("ESP", "👁")

local punchButton =
    createFeatureButton("Auto Punch", "👊")

local orbitButton =
    createFeatureButton("Orbit", "🌀")

local dodgeButton =
    createFeatureButton("Auto Dodge", "🥷")

staminaButton.MouseButton1Click = function()
    showPage("Stamina")
end

espButton.MouseButton1Click = function()
    showPage("ESP")
end

punchButton.MouseButton1Click = function()
    showPage("Auto Punch")
end

orbitButton.MouseButton1Click = function()
    showPage("Orbit")
end

dodgeButton.MouseButton1Click = function()
    showPage("Auto Dodge")
end

--==================================================
-- FLOATING BUTTON
--==================================================

local FloatingButton = Instance.new("TextButton")
FloatingButton.Size = UDim2.fromOffset(55, 55)
FloatingButton.Position = UDim2.new(0, 20, 0.5, -25)
FloatingButton.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "K"
FloatingButton.TextColor3 = Color3.new(1, 1, 1)
FloatingButton.TextSize = 22
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.Visible = false
FloatingButton.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingButton

FloatingButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    FloatingButton.Visible = false
end)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingButton.Visible = true
end)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatingButton.Visible = true
end)

--==================================================
-- DRAGGING
--==================================================

local function makeDraggable(handle, object)

    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState ==
                    Enum.UserInputState.End
                then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or input.UserInputType ==
            Enum.UserInputType.Touch
        then

            local delta =
                input.Position - dragStart

            object.Position =
                UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
        end
    end)
end

makeDraggable(TopBar, Main)
makeDraggable(FloatingButton, FloatingButton)

--==================================================
-- OPENING ANIMATION
--==================================================

local originalSize = Main.Size

Main.Size = UDim2.fromOffset(0, 0)

TweenService:Create(
    Main,
    TweenInfo.new(
        0.35,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ),
    {
        Size = originalSize
    }
):Play()

--==================================================
-- DEFAULT PAGE
--==================================================

showPage("Stamina")

print("Klase Panel loaded successfully.")
      