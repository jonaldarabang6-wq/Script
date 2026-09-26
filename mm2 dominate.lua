-- DOMINATOR PRIME
-- Part 1/8 — Core / Configuration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CFG = {
    SilentAim = true,
    Range = 180,
    FOV = 110,
    Prediction = 0.12,
    MaxPrediction = 0.30,
    FireCooldown = 0.25,

    ESP = true,
    ESPDistance = 600,
    ESPUpdate = 0.05,

    AutoGun = false,
    GunWait = 0.30,
    GunRange = 250,

    Speed = false,
    SpeedValue = 32,

    Hitbox = false,
    HitboxMultiplier = 2,
    HitboxMax = 12,

    TargetPart = "HumanoidRootPart",
    TeamCheck = false,
}

local COLORS = {
    Murderer = Color3.fromRGB(255,60,60),
    Sheriff = Color3.fromRGB(60,130,255),
    Hero = Color3.fromRGB(255,220,50),
    Innocent = Color3.fromRGB(60,255,100),
    Unknown = Color3.fromRGB(220,220,220),
}

local State = {
    Destroyed = false,
    Target = nil,
    Murderer = nil,
    LastShot = 0,
    LastTargetScan = 0,
    LastESP = 0,
    LastGunScan = 0,
    GunBusy = false,
    GunDeathPending = false,
    RoundId = nil,
    RoundActive = false,

    Connections = {},
    PlayerConnections = {},
    ESP = {},
    Velocities = {},
    Roles = {},
    Hitboxes = {},
    GunStates = {},
}

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(State.Connections, c)
    return c
end

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
end

local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

local function root(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
end

local function humanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function alive(character)
    local h = humanoid(character)
    return h and h.Health > 0 and root(character) ~= nil
end

local function attr(instance, name)
    if not instance then return nil end
    return instance:GetAttribute(name)
end

local function normalizeRole(role)
    if typeof(role) ~= "string" then
        return "Unknown"
    end

    role = role:lower()

    if role == "murderer" or role == "killer" then
        return "Murderer"
    elseif role == "sheriff" then
        return "Sheriff"
    elseif role == "hero" then
        return "Hero"
    elseif role == "innocent" or role == "civilian" then
        return "Innocent"
    end

    return "Unknown"
end

-- DOMINATOR PRIME
-- Part 2/8 — Role / Round Engine

local function getRole(player)
    if not player then return "Unknown" end

    local names = {
        "Role",
        "PlayerRole",
        "RoundRole",
        "TeamRole",
    }

    for _, name in ipairs(names) do
        local value = attr(player, name)
        if value ~= nil then
            local role = normalizeRole(value)
            if role ~= "Unknown" then
                return role
            end
        end
    end

    local character = player.Character

    for _, name in ipairs(names) do
        local value = attr(character, name)
        if value ~= nil then
            local role = normalizeRole(value)
            if role ~= "Unknown" then
                return role
            end
        end
    end

    if attr(player, "IsMurderer") == true
        or attr(character, "IsMurderer") == true then
        return "Murderer"
    end

    if attr(player, "IsSheriff") == true
        or attr(character, "IsSheriff") == true then
        return "Sheriff"
    end

    if attr(player, "IsHero") == true
        or attr(character, "IsHero") == true then
        return "Hero"
    end

    if attr(player, "IsInnocent") == true
        or attr(character, "IsInnocent") == true then
        return "Innocent"
    end

    return "Unknown"
end

local function updateRole(player)
    local role = getRole(player)
    State.Roles[player] = role
    return role
end

local function scanRoles()
    State.Murderer = nil

    for _, player in ipairs(Players:GetPlayers()) do
        local role = updateRole(player)

        if role == "Murderer" then
            State.Murderer = player
        end
    end

    return State.Murderer
end

local function getRoundInfo()
    local active = attr(Workspace, "RoundActive")

    if active == nil then
        active = attr(Workspace, "MatchActive")
    end

    if active == nil then
        active = true
    end

    local id = attr(Workspace, "RoundId")

    if id == nil then
        id = attr(Workspace, "MatchId")
    end

    if id == nil then
        id = attr(Workspace, "RoundNumber")
    end

    return active == true, id
end

local function refreshRound()
    local active, id = getRoundInfo()

    if id ~= State.RoundId then
        State.RoundId = id
        State.RoundActive = active
        scanRoles()
    elseif active ~= State.RoundActive then
        State.RoundActive = active
        scanRoles()
    end
end

local function watchAttributes(player)
    if State.PlayerConnections[player] then
        for _, c in ipairs(State.PlayerConnections[player]) do
            safe(function() c:Disconnect() end)
        end
    end

    State.PlayerConnections[player] = {}

    local function add(signal, fn)
        local c = signal:Connect(fn)
        table.insert(State.PlayerConnections[player], c)
    end

    add(player.AttributeChanged, function()
        updateRole(player)
        scanRoles()
    end)

    if player.Character then
        add(player.Character.AttributeChanged, function()
            updateRole(player)
            scanRoles()
        end)
    end
end

local function trackGunRoleDeath(player, character)
    local role = getRole(player)

    if role ~= "Sheriff" and role ~= "Hero" then
        return
    end

    State.GunStates[player] = true

    local h = humanoid(character)

    if h then
        local c
        c = h.Died:Connect(function()
            State.GunDeathPending = true
            State.GunStates[player] = false
        end)

        table.insert(State.Connections, c)
    end
end

local function watchPlayer(player)
    watchAttributes(player)

    local function characterAdded(character)
        State.Velocities[player] = {}
        updateRole(player)
        trackGunRoleDeath(player, character)

        task.defer(scanRoles)
    end

    local function characterRemoving()
        local oldRole = State.Roles[player]

        if oldRole == "Sheriff" or oldRole == "Hero" then
            State.GunDeathPending = true
        end

        task.defer(scanRoles)
    end

    local c1 = player.CharacterAdded:Connect(characterAdded)
    local c2 = player.CharacterRemoving:Connect(characterRemoving)

    State.PlayerConnections[player].c1 = c1
    State.PlayerConnections[player].c2 = c2

    if player.Character then
        characterAdded(player.Character)
    end
end

-- DOMINATOR PRIME
-- Part 3/8 — Persistent Murderer ESP

local function roleColor(role)
    return COLORS[role] or COLORS.Unknown
end

local function destroyESP(player)
    local data = State.ESP[player]

    if data then
        if data.Highlight then
            safe(function() data.Highlight:Destroy() end)
        end

        if data.Billboard then
            safe(function() data.Billboard:Destroy() end)
        end

        State.ESP[player] = nil
    end
end

local function createESP(player)
    if player == LP then return end
    if not CFG.ESP then return end

    local character = player.Character
    if not character then return end

    local r = root(character)
    if not r then return end

    destroyESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "DominatorESP"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DominatorInfo"
    billboard.Adornee = r
    billboard.Size = UDim2.fromOffset(190, 55)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextStrokeTransparency = 0.35
    label.Parent = billboard

    State.ESP[player] = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
    }
end

local function updateESP(player)
    local data = State.ESP[player]
    local character = player.Character

    if not CFG.ESP or not character or not alive(character) then
        destroyESP(player)
        return
    end

    if not data or data.Character ~= character then
        createESP(player)
        data = State.ESP[player]
    end

    if not data then return end

    local r = root(character)
    local myRoot = root(LP.Character)

    if not r or not myRoot then return end

    local distance = (r.Position - myRoot.Position).Magnitude

    if distance > CFG.ESPDistance then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        return
    end

    data.Highlight.Enabled = true
    data.Billboard.Enabled = true

    local role = updateRole(player)
    local color = roleColor(role)

    data.Highlight.FillColor = color
    data.Highlight.OutlineColor = color

    data.Label.Text = player.DisplayName
        .. "\n[" .. role .. "] "
        .. math.floor(distance) .. " studs"

    data.Label.TextColor3 = color
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            updateESP(player)
        end
    end
end

local function clearAllESP()
    for player in pairs(State.ESP) do
        destroyESP(player)
    end
end

-- DOMINATOR PRIME
-- Part 4/8 — Prediction / Target Engine

local function movementState(character)
    local h = humanoid(character)
    if not h then return "Unknown" end

    local state = h:GetState()

    if state == Enum.HumanoidStateType.Climbing then
        return "Climbing"
    elseif state == Enum.HumanoidStateType.Swimming then
        return "Swimming"
    elseif state == Enum.HumanoidStateType.Jumping then
        return "Jumping"
    elseif state == Enum.HumanoidStateType.Freefall then
        return "Freefall"
    elseif state == Enum.HumanoidStateType.Running then
        return "Running"
    end

    return "Grounded"
end

local function recordVelocity(player)
    local character = player.Character
    local r = root(character)

    if not r then return end

    local list = State.Velocities[player]

    if not list then
        list = {}
        State.Velocities[player] = list
    end

    table.insert(list, 1, r.AssemblyLinearVelocity)

    while #list > 8 do
        table.remove(list)
    end
end

local function averageVelocity(player)
    local list = State.Velocities[player]

    if not list or #list == 0 then
        return Vector3.zero
    end

    local total = Vector3.zero

    for _, velocity in ipairs(list) do
        total += velocity
    end

    return total / #list
end

local function predict(player)
    local character = player.Character
    local r = root(character)

    if not r then
        return nil
    end

    local velocity = averageVelocity(player)
    local time = CFG.Prediction
    local state = movementState(character)

    if state == "Running" then
        time += 0.015
    elseif state == "Jumping" then
        time += 0.035
    elseif state == "Freefall" then
        time += 0.045
    elseif state == "Climbing" then
        time += 0.025
    elseif state == "Swimming" then
        time += 0.035
    end

    time = clamp(time, 0, CFG.MaxPrediction)

    return r.Position + velocity * time
end

local function screenDistance(position)
    local point, visible = Camera:WorldToViewportPoint(position)

    if not visible or point.Z <= 0 then
        return math.huge
    end

    local center = Camera.ViewportSize / 2
    return (Vector2.new(point.X, point.Y) - center).Magnitude
end

local function chooseTarget()
    local murderer = State.Murderer

    if not murderer then
        scanRoles()
        murderer = State.Murderer
    end

    if not murderer then
        return nil
    end

    local character = murderer.Character

    if not alive(character) then
        return nil
    end

    local myRoot = root(LP.Character)
    local targetRoot = root(character)

    if not myRoot or not targetRoot then
        return nil
    end

    local distance = (targetRoot.Position - myRoot.Position).Magnitude

    if distance > CFG.Range then
        return nil
    end

    local predicted = predict(murderer)

    if not predicted then
        return nil
    end

    if screenDistance(predicted) > CFG.FOV then
        return nil
    end

    return murderer, predicted
end

local function getShotInterface()
    local folder = ReplicatedStorage:FindFirstChild("DominatorClient")
    if not folder then return nil end

    return folder:FindFirstChild("FireAtPosition")
end

local function fireAtPosition(position, target)
    local event = getShotInterface()

    if not event then
        return false
    end

    if event:IsA("RemoteEvent") then
        event:FireServer(position, target)
        return true
    end

    if event:IsA("BindableEvent") then
        event:Fire(position, target)
        return true
    end

    return false
end

local function requestShot()
    if not CFG.SilentAim then return end

    local now = os.clock()

    if now - State.LastShot < CFG.FireCooldown then
        return
    end

    local target, position = chooseTarget()

    if not target or not position then
        return
    end

    State.Target = target
    State.LastShot = now

    fireAtPosition(position, target)
end

-- DOMINATOR PRIME
-- Part 5/8 — Auto Get Gun

local function gunNameAllowed(name)
    if not name then return false end

    name = name:lower()

    return name:find("gun")
        or name:find("sheriff")
        or name:find("revolver")
        or name:find("pistol")
end

local function findGun()
    local preferred = Workspace:FindFirstChild("DominatorGuns")

    if preferred then
        for _, object in ipairs(preferred:GetDescendants()) do
            if object:IsA("Tool") then
                return object
            end
        end
    end

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Tool") and gunNameAllowed(object.Name) then
            local handle = object:FindFirstChild("Handle")

            if handle then
                return object
            end
        end
    end

    return nil
end

local function requestGunPickup(gun)
    if not gun then return false end

    local folder = ReplicatedStorage:FindFirstChild("DominatorClient")
    if not folder then return false end

    local event = folder:FindFirstChild("RequestGunPickup")

    if not event then
        return false
    end

    if event:IsA("RemoteEvent") then
        event:FireServer(gun)
        return true
    elseif event:IsA("BindableEvent") then
        event:Fire(gun)
        return true
    end

    return false
end

local function runAutoGun()
    if not CFG.AutoGun then return end
    if State.GunBusy then return end
    if not State.GunDeathPending then return end

    State.GunBusy = true
    State.GunDeathPending = false

    local character = LP.Character
    local myRoot = root(character)

    if not myRoot then
        State.GunBusy = false
        return
    end

    local gun = findGun()

    if not gun then
        State.GunBusy = false
        return
    end

    local handle = gun:FindFirstChild("Handle")

    if not handle then
        State.GunBusy = false
        return
    end

    local original = character:GetPivot()
    local destination = handle.CFrame + Vector3.new(0, 2, 0)

    if (destination.Position - myRoot.Position).Magnitude > CFG.GunRange then
        State.GunBusy = false
        return
    end

    character:PivotTo(destination)

    task.wait(CFG.GunWait)

    requestGunPickup(gun)

    task.wait(0.05)

    if CFG.AutoGun and character.Parent then
        character:PivotTo(original)
    end

    State.GunBusy = false
end

local function enableAutoGun()
    State.GunDeathPending = false

    for _, player in ipairs(Players:GetPlayers()) do
        local role = updateRole(player)

        if role == "Sheriff" or role == "Hero" then
            local character = player.Character
            if character then
                trackGunRoleDeath(player, character)
            end
        end
    end
end

-- DOMINATOR PRIME
-- Part 6/8 — Speed / Hitbox Debug

local function applySpeed()
    local character = LP.Character
    local h = humanoid(character)

    if not h then return end

    if CFG.Speed then
        h.WalkSpeed = math.clamp(
            tonumber(CFG.SpeedValue) or 16,
            0,
            250
        )
    end
end

local function restoreHitbox(player)
    local saved = State.Hitboxes[player]

    if not saved then return end

    for part, data in pairs(saved) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
            part.Massless = data.Massless
        end
    end

    State.Hitboxes[player] = nil
end

local function updateHitbox(player)
    if not CFG.Hitbox then
        restoreHitbox(player)
        return
    end

    if player == LP then return end

    local character = player.Character
    if not alive(character) then return end

    local part = character:FindFirstChild(CFG.TargetPart)

    if not part or not part:IsA("BasePart") then
        return
    end

    if not State.Hitboxes[player] then
        State.Hitboxes[player] = {
            [part] = {
                Size = part.Size,
                Transparency = part.Transparency,
                CanCollide = part.CanCollide,
                Massless = part.Massless,
            }
        }
    end

    local original = State.Hitboxes[player][part]

    if not original then
        State.Hitboxes[player][part] = {
            Size = part.Size,
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
            Massless = part.Massless,
        }

        original = State.Hitboxes[player][part]
    end

    local size = original.Size * CFG.HitboxMultiplier

    size = Vector3.new(
        math.min(size.X, CFG.HitboxMax),
        math.min(size.Y, CFG.HitboxMax),
        math.min(size.Z, CFG.HitboxMax)
    )

    part.Size = size
    part.Transparency = 0.65
    part.CanCollide = false
    part.Massless = true
end

local function updateAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            updateHitbox(player)
        end
    end
end

local function restoreAllHitboxes()
    for player in pairs(State.Hitboxes) do
        restoreHitbox(player)
    end
end

local function setSpeed(value)
    local n = tonumber(value)

    if not n then
        return false
    end

    CFG.SpeedValue = math.clamp(n, 0, 250)
    applySpeed()

    return true
end

-- DOMINATOR PRIME
-- Part 7/8 — UI

local UI = {}
local gui

local function createUI()
    if gui then
        gui:Destroy()
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "DOMINATOR_PRIME"
    gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(410, 500)
    main.Position = UDim2.new(0.5, -205, 0.5, -250)
    main.BackgroundColor3 = Color3.fromRGB(18,18,22)
    main.BorderSizePixel = 0
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,50)
    title.BackgroundTransparency = 1
    title.Text = "DOMINATOR PRIME"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 21
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Position = UDim2.fromOffset(15,48)
    status.Size = UDim2.new(1,-30,0,42)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(180,180,180)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextWrapped = true
    status.Parent = main

    local holder = Instance.new("Frame")
    holder.Position = UDim2.fromOffset(15,95)
    holder.Size = UDim2.new(1,-30,1,-110)
    holder.BackgroundTransparency = 1
    holder.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.Parent = holder

    local function button(text, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,0,0,34)
        b.BackgroundColor3 = Color3.fromRGB(35,35,42)
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 13
        b.Text = text
        b.AutoButtonColor = true
        b.Parent = holder

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,7)
        c.Parent = b

        b.MouseButton1Click:Connect(callback)

        return b
    end

    local function toggle(name, getter, setter)
        local b

        local function update()
            b.Text = name .. ": " .. (getter() and "ON" or "OFF")
        end

        b = button("", function()
            setter(not getter())
            update()
        end)

        update()
        return b
    end

    toggle("Silent Target", function()
        return CFG.SilentAim
    end, function(v)
        CFG.SilentAim = v
    end)

    toggle("Murderer ESP", function()
        return CFG.ESP
    end, function(v)
        CFG.ESP = v
        if not v then
            clearAllESP()
        end
    end)

    toggle("Auto Get Gun", function()
        return CFG.AutoGun
    end, function(v)
        CFG.AutoGun = v
        if v then enableAutoGun() end
    end)

    toggle("Speed", function()
        return CFG.Speed
    end, function(v)
        CFG.Speed = v
        applySpeed()
    end)

    toggle("Hitbox Debug", function()
        return CFG.Hitbox
    end, function(v)
        CFG.Hitbox = v
        if not v then
            restoreAllHitboxes()
        end
    end)

    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(1,0,0,38)
    speedBox.BackgroundColor3 = Color3.fromRGB(30,30,36)
    speedBox.TextColor3 = Color3.new(1,1,1)
    speedBox.PlaceholderColor3 = Color3.fromRGB(150,150,150)
    speedBox.PlaceholderText = "Speed value..."
    speedBox.Text = tostring(CFG.SpeedValue)
    speedBox.Font = Enum.Font.Gotham
    speedBox.TextSize = 14
    speedBox.ClearTextOnFocus = false
    speedBox.Parent = holder

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0,7)
    sc.Parent = speedBox

    speedBox.FocusLost:Connect(function()
        setSpeed(speedBox.Text)
        speedBox.Text = tostring(CFG.SpeedValue)
    end)

    UI.Status = status
    UI.Main = main

    local dragging = false
    local dragStart
    local startPosition

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local floating = Instance.new("TextButton")
    floating.Size = UDim2.fromOffset(48,48)
    floating.Position = UDim2.new(0,20,0.5,-24)
    floating.BackgroundColor3 = Color3.fromRGB(25,25,30)
    floating.Text = "D"
    floating.TextColor3 = Color3.new(1,1,1)
    floating.TextSize = 22
    floating.Font = Enum.Font.GothamBold
    floating.Parent = gui

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1,0)
    fc.Parent = floating

    floating.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
end

local function updateStatus()
    if not UI.Status then return end

    local role = getRole(LP)
    local target = State.Target
    local murderer = State.Murderer

    local targetName = target and target.Name or "None"
    local murdererName = murderer and murderer.Name or "None"

    UI.Status.Text =
        "Role: " .. role
        .. "  |  Target: " .. targetName
        .. "\nMurderer: " .. murdererName
end

-- DOMINATOR PRIME
-- Part 8/8 — Initialization / Main Engine

local function setupPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            watchPlayer(player)
        end
    end

    connect(Players.PlayerAdded, function(player)
        if player == LP then return end

        watchPlayer(player)
        task.defer(function()
            updateRole(player)
            scanRoles()
            createESP(player)
        end)
    end)

    connect(Players.PlayerRemoving, function(player)
        destroyESP(player)
        restoreHitbox(player)

        State.Velocities[player] = nil
        State.Roles[player] = nil
        State.GunStates[player] = nil

        local connections = State.PlayerConnections[player]

        if connections then
            for _, c in pairs(connections) do
                safe(function() c:Disconnect() end)
            end
        end

        State.PlayerConnections[player] = nil

        if State.Target == player then
            State.Target = nil
        end

        if State.Murderer == player then
            State.Murderer = nil
        end
    end)
end

local function setupLocalPlayer()
    local function characterAdded(character)
        local h = humanoid(character)

        if h then
            h.Died:Connect(function()
                task.delay(0.1, function()
                    if not State.Destroyed then
                        applySpeed()
                    end
                end)
            end)
        end

        task.defer(applySpeed)
    end

    connect(LP.CharacterAdded, characterAdded)

    if LP.Character then
        characterAdded(LP.Character)
    end
end

local function setupRoundWatcher()
    connect(Workspace.AttributeChanged, function(attribute)
        if attribute == "RoundActive"
            or attribute == "MatchActive"
            or attribute == "RoundId"
            or attribute == "MatchId"
            or attribute == "RoundNumber" then

            refreshRound()
            scanRoles()
            refreshESP()
        end
    end)
end

local function cleanup()
    if State.Destroyed then return end

    State.Destroyed = true

    for _, c in ipairs(State.Connections) do
        safe(function() c:Disconnect() end)
    end

    for player, connections in pairs(State.PlayerConnections) do
        for _, c in pairs(connections) do
            safe(function() c:Disconnect() end)
        end
        State.PlayerConnections[player] = nil
    end

    clearAllESP()
    restoreAllHitboxes()

    if gui then
        safe(function() gui:Destroy() end)
        gui = nil
    end
end

local function initialize()
    setupPlayers()
    setupLocalPlayer()
    setupRoundWatcher()

    refreshRound()
    scanRoles()
    refreshESP()
    createUI()

    connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end

        if input.KeyCode == Enum.KeyCode.F then
            if UI.Main then
                UI.Main.Visible = not UI.Main.Visible
            end
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            requestShot()
        end
    end)

    local targetTimer = 0
    local espTimer = 0
    local roleTimer = 0
    local gunTimer = 0
    local hitboxTimer = 0

    connect(RunService.Heartbeat, function(dt)
        if State.Destroyed then return end

        targetTimer += dt
        espTimer += dt
        roleTimer += dt
        gunTimer += dt
        hitboxTimer += dt

        if targetTimer >= 0.04 then
            targetTimer = 0

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    recordVelocity(player)
                end
            end

            if State.Murderer then
                local target, position = chooseTarget()
                State.Target = target
                State.TargetPosition = position
            end
        end

        if roleTimer >= 0.10 then
            roleTimer = 0
            refreshRound()
            scanRoles()
        end

        if espTimer >= CFG.ESPUpdate then
            espTimer = 0
            refreshESP()
            updateStatus()
        end

        if gunTimer >= 0.10 then
            gunTimer = 0
            runAutoGun()
        end

        if hitboxTimer >= 0.15 then
            hitboxTimer = 0
            updateAllHitboxes()
        end

        applySpeed()
    end)

    connect(LP.AncestryChanged, function(_, parent)
        if not parent then
            cleanup()
        end
    end)
end

initialize()

-- DOMINATOR PRIME END