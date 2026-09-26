--[[
    Franz Hub | MM2
    For Delta Executor (Android)
    Silent Aim freeze fixed
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local State = {
    ESP = false, ESPBox = true, ESPName = true, ESPRole = true, ESPDistance = true, ESPTracer = false,
    SilentAim = false, SilentAimFOV = 120, SilentAimHitChance = 100, SilentAimPart = "Head", SilentAimWallCheck = false,
    Aimbot = false, AimbotFOV = 150, AimbotSmoothness = 0.25,
    Hitbox = false, HitboxSize = 8,
    AutoShoot = false, AutoShootRange = 200,
    GunGrab = false, CoinFarm = false,
    Speed = false, SpeedValue = 50, Jump = false, JumpValue = 100,
    Fly = false, FlySpeed = 80, Noclip = false, InfJump = false,
    AntiRagdoll = false,
}

local ESPObjects = {}

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
end

local function GetRole(plr)
    if not plr or not plr.Character then return "Unknown" end
    local char = plr.Character
    if char:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or char:FindFirstChild("Colt") then return "Sheriff" end
    return "Innocent"
end

local function GetRoleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 0, 0) end
    if role == "Sheriff" then return Color3.fromRGB(0, 150, 255) end
    return Color3.fromRGB(0, 255, 100)
end

local function IsAlive(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0
end

local function CreateESP(plr)
    if plr == LP or ESPObjects[plr] or not plr.Character then return end
    local box = Drawing.new("Square")
    box.Thickness = 1; box.Filled = false; box.Transparency = 1; box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true; name.Visible = false
    local role = Drawing.new("Text")
    role.Size = 13; role.Center = true; role.Outline = true; role.Visible = false
    local dist = Drawing.new("Text")
    dist.Size = 12; dist.Center = true; dist.Outline = true; dist.Visible = false
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1; tracer.Transparency = 1; tracer.Visible = false
    ESPObjects[plr] = {box = box, name = name, role = role, dist = dist, tracer = tracer}
end

local function RemoveESP(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do pcall(function() obj:Remove() end) end
        ESPObjects[plr] = nil
    end
end

local function UpdateESP()
    for plr, data in pairs(ESPObjects) do
        if not State.ESP or not IsAlive(plr) or plr == LP then
            data.box.Visible = false; data.name.Visible = false
            data.role.Visible = false; data.dist.Visible = false; data.tracer.Visible = false
            continue
        end
        local char = plr.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            data.box.Visible = false; data.name.Visible = false
            data.role.Visible = false; data.dist.Visible = false; data.tracer.Visible = false
            continue
        end
        local roleStr = GetRole(plr)
        local color = GetRoleColor(roleStr)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height * 0.6
        data.box.Size = Vector2.new(width, height)
        data.box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2 + (pos.Y - headPos.Y))
        data.box.Color = color
        data.box.Visible = State.ESPBox
        data.name.Text = plr.Name
        data.name.Position = Vector2.new(pos.X, pos.Y - height/2 - 20)
        data.name.Visible = State.ESPName
        data.role.Text = "[" .. roleStr .. "]"
        data.role.Position = Vector2.new(pos.X, pos.Y - height/2 - 6)
        data.role.Color = color
        data.role.Visible = State.ESPRole
        local distance = math.floor((LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
        data.dist.Text = tostring(distance) .. " studs"
        data.dist.Position = Vector2.new(pos.X, pos.Y + height/2 + 4)
        data.dist.Visible = State.ESPDistance
        if State.ESPTracer and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = Camera:WorldToViewportPoint(LP.Character.HumanoidRootPart.Position)
            data.tracer.From = Vector2.new(myPos.X, myPos.Y + 50)
            data.tracer.To = Vector2.new(pos.X, pos.Y - height/2)
            data.tracer.Color = color
            data.tracer.Visible = true
        else
            data.tracer.Visible = false
        end
    end
end

-- ============================================================
-- SILENT AIM (Camera freeze fixed)
-- ============================================================
local function GetClosestTarget(fov, wallCheck, partName)
    local closest, closestDist = nil, fov
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP or not IsAlive(plr) then continue end
        local part = plr.Character:FindFirstChild(partName or State.SilentAimPart)
        if not part then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if mag < closestDist then
            if wallCheck then
                local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position))
                local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character})
                if hit and not hit:IsDescendantOf(plr.Character) then continue end
            end
            closestDist = mag
            closest = plr
        end
    end
    return closest
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()

    if State.SilentAim and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList") then

        -- FIX 1: skip camera's own raycasts
        if typeof(self) == "Instance" and self:IsA("Camera") then
            return oldNamecall(self, ...)
        end

        -- FIX 2: only activate when a tool is equipped
        local char = LP.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then
            return oldNamecall(self, ...)
        end

        -- FIX 3: only redirect if a valid target is in FOV
        if math.random(1, 100) <= State.SilentAimHitChance then
            local target = GetClosestTarget(State.SilentAimFOV, State.SilentAimWallCheck)
            if target and target.Character then
                local part = target.Character:FindFirstChild(State.SilentAimPart)
                if part then
                    local args = {...}
                    local origin = Camera.CFrame.Position
                    local dir = (part.Position - origin).Unit * 1000
                    if method == "Raycast" then
                        return oldNamecall(self, origin, dir, args[3], args[4])
                    elseif method == "FindPartOnRay" then
                        return oldNamecall(self, Ray.new(origin, dir), args[1])
                    elseif method == "FindPartOnRayWithIgnoreList" then
                        return oldNamecall(self, Ray.new(origin, dir), args[1])
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

-- ============================================================
-- AIMBOT
-- ============================================================
local function UpdateAimbot()
    if not State.Aimbot then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local target = GetClosestTarget(State.AimbotFOV, false, "Head")
    if target and target.Character then
        local part = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local goal = CFrame.new(Camera.CFrame.Position, part.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, State.AimbotSmoothness)
        end
    end
end

-- ============================================================
-- HITBOX EXPANDER
-- ============================================================
local function UpdateHitbox()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP or not IsAlive(plr) then continue end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if State.Hitbox then
                hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
                hrp.Massless = true
            else
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end

-- ============================================================
-- AUTO SHOOT
-- ============================================================
local autoShootConn
local function StartAutoShoot()
    if autoShootConn then autoShootConn:Disconnect() end
    autoShootConn = RunService.RenderStepped:Connect(function()
        if not State.AutoShoot then return end
        if not LP.Character then return end
        local tool = LP.Character:FindFirstChildOfClass("Tool")
        if not tool then return end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr == LP or not IsAlive(plr) then continue end
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist <= State.AutoShootRange then
                    pcall(function() tool:Activate() end)
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- GUN GRAB
-- ============================================================
local gunGrabConn
local function StartGunGrab()
    if gunGrabConn then gunGrabConn:Disconnect() end
    gunGrabConn = RunService.Heartbeat:Connect(function()
        if not State.GunGrab then return end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "Gun" or obj.Name == "Revolver" or obj.Name == "Colt" or obj.Name == "Chroma" then
                local handle = obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
                if handle and handle:IsA("BasePart") then
                    pcall(function()
                        firetouchinterest(LP.Character.HumanoidRootPart, handle, 0)
                        firetouchinterest(LP.Character.HumanoidRootPart, handle, 1)
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- COIN FARM
-- ============================================================
local coinConn
local function StartCoinFarm()
    if coinConn then coinConn:Disconnect() end
    coinConn = RunService.Heartbeat:Connect(function()
        if not State.CoinFarm then return end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj.Name == "Coin" or obj.Name == "CoinContainer" or obj.Name == "Money") and obj:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(LP.Character.HumanoidRootPart, obj, 0)
                    firetouchinterest(LP.Character.HumanoidRootPart, obj, 1)
                end)
            end
        end
    end)
end

-- ============================================================
-- JUMP
-- ============================================================
local function UpdateJump()
    if not LP.Character or not LP.Character:FindFirstChild("Humanoid") then return end
    LP.Character.Humanoid.JumpPower = State.Jump and State.JumpValue or 50
    LP.Character.Humanoid.UseJumpPower = true
end

-- ============================================================
-- FLY
-- ============================================================
local FlyBV, FlyBG
local flyConn

local function StartFly()
    if FlyBV then FlyBV:Destroy() end
    if FlyBG then FlyBG:Destroy() end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBV.Velocity = Vector3.zero
    FlyBV.Parent = LP.Character.HumanoidRootPart
    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBG.P = 1000
    FlyBG.Parent = LP.Character.HumanoidRootPart
end

local function StopFly()
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
end

local function StartFlyLoop()
    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.RenderStepped:Connect(function()
        if not State.Fly then
            if FlyBV then StopFly() end
            return
        end
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
        if not FlyBV then StartFly() end
        local move = Vector3.zero
        local cam = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        FlyBV.Velocity = move * State.FlySpeed
        FlyBG.CFrame = cam
    end)
end

-- ============================================================
-- NOCLIP
-- ============================================================
local noclipConn
local function StartNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        if LP.Character then
            for _, part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================
local infJumpConn
local function StartInfJump()
    if infJumpConn then infJumpConn:Disconnect() end
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if State.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ============================================================
-- ANTI-RAGDOLL
-- ============================================================
local antiRagConn
local function StartAntiRagdoll()
    if antiRagConn then antiRagConn:Disconnect() end
    antiRagConn = RunService.Heartbeat:Connect(function()
        if not State.AntiRagdoll then return end
        if LP.Character then
            local humanoid = LP.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                if LP.Character:FindFirstChild("HumanoidRootPart") then
                    LP.Character.HumanoidRootPart.Velocity = Vector3.zero
                end
            end
        end
    end)
end

-- ============================================================
-- KILL ALL
-- ============================================================
local function KillAll()
    if not LP.Character or not LP.Character:FindFirstChildOfClass("Tool") then
        Notify("Kill All", "Equip a weapon first")
        return
    end
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP or not IsAlive(plr) then continue end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp and LP.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local oldCF = LP.Character.HumanoidRootPart.CFrame
                LP.Character.HumanoidRootPart.CFrame = hrp.CFrame
                tool:Activate()
                task.wait(0.05)
                LP.Character.HumanoidRootPart.CFrame = oldCF
            end)
        end
    end
    Notify("Kill All", "Done")
end

-- ============================================================
-- SERVER HOP
-- ============================================================
local function ServerHop()
    local http = game:GetService("HttpService")
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function() return http:JSONDecode(game:HttpGet(url)) end)
    if not ok or not res or not res.data then Notify("Server Hop", "Failed"); return end
    for _, s in pairs(res.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LP)
            end)
            return
        end
    end
    Notify("Server Hop", "No servers found")
end

-- ============================================================
-- EVENT HOOKS
-- ============================================================
local function OnCharacterAdded(plr)
    task.wait(0.5)
    if plr == LP then
        task.wait(1)
        UpdateJump()
    end
    if State.ESP then CreateESP(plr) end
end

local function OnPlayerAdded(plr)
    if plr ~= LP then
        plr.CharacterAdded:Connect(function() OnCharacterAdded(plr) end)
        if plr.Character then OnCharacterAdded(plr) end
    end
end

for _, plr in pairs(Players:GetPlayers()) do OnPlayerAdded(plr) end
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(RemoveESP)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    UpdateJump()
end)

-- ============================================================
-- START BACKGROUND LOOPS
-- ============================================================
StartAutoShoot()
StartGunGrab()
StartCoinFarm()
StartFlyLoop()
StartNoclip()
StartInfJump()
StartAntiRagdoll()

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAimbot()
end)

RunService.Heartbeat:Connect(function()
    UpdateHitbox()
end)

-- ============================================================
-- FRANZ GUI
-- ============================================================
local function CreateGUI()
    local old = LP.PlayerGui:FindFirstChild("FranzHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FranzHub"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LP.PlayerGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 230, 0, 400)
    main.Position = UDim2.new(0, 10, 0, 80)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 100)
    stroke.Thickness = 1
    stroke.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    title.BackgroundTransparency = 0.2
    title.BorderSizePixel = 0
    title.Text = "Franz Hub | MM2"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.new(0, 30, 0, 30)
    minimize.Position = UDim2.new(1, -35, 0, 3)
    minimize.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    minimize.BorderSizePixel = 0
    minimize.Text = "-"
    minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 18
    minimize.Parent = title

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimize

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -45)
    scroll.Position = UDim2.new(0, 5, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local minimized = false
    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            main.Size = UDim2.new(0, 230, 0, 35)
            scroll.Visible = false
            minimize.Text = "+"
        else
            main.Size = UDim2.new(0, 230, 0, 400)
            scroll.Visible = true
            minimize.Text = "-"
        end
    end)

    local function MakeSection(text)
        local sec = Instance.new("TextLabel")
        sec.Size = UDim2.new(1, -10, 0, 24)
        sec.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        sec.BackgroundTransparency = 0.3
        sec.BorderSizePixel = 0
        sec.Text = "  " .. text
        sec.TextColor3 = Color3.fromRGB(255, 200, 100)
        sec.Font = Enum.Font.GothamBold
        sec.TextSize = 12
        sec.TextXAlignment = Enum.TextXAlignment.Left
        sec.Parent = scroll
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = sec
    end

    local function MakeToggle(name, getter, setter)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = scroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 40, 0, 20)
        indicator.Position = UDim2.new(1, -48, 0.5, -10)
        indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        indicator.BorderSizePixel = 0
        indicator.Parent = btn

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(1, 0)
        ic.Parent = indicator

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 16, 0, 16)
        dot.Position = UDim2.new(0, 2, 0.5, -8)
        dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        dot.BorderSizePixel = 0
        dot.Parent = indicator

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot

        local function refresh()
            if getter() then
                indicator.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                dot.Position = UDim2.new(1, -18, 0.5, -8)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            else
                indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                dot.Position = UDim2.new(0, 2, 0.5, -8)
                dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            end
        end

        btn.MouseButton1Click:Connect(function()
            setter(not getter())
            refresh()
        end)

        refresh()
    end

    local function MakeSlider(name, min, max, getter, setter)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 46)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        frame.BorderSizePixel = 0
        frame.Parent = scroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 2)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. tostring(getter())
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 12)
        bar.Position = UDim2.new(0, 10, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        bar.BorderSizePixel = 0
        bar.Parent = frame

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = fill

        local dragging = false
        local function update(input)
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = name .. ": " .. tostring(value)
            setter(value)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input)
            end
        end)
        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                update(input)
            end
        end)
    end

    local function MakeButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = scroll

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        btn.MouseButton1Click:Connect(callback)
    end

    MakeSection("ESP")
    MakeToggle("ESP Enabled", function() return State.ESP end, function(v)
        State.ESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        end
    end)
    MakeToggle("Box", function() return State.ESPBox end, function(v) State.ESPBox = v end)
    MakeToggle("Name", function() return State.ESPName end, function(v) State.ESPName = v end)
    MakeToggle("Role", function() return State.ESPRole end, function(v) State.ESPRole = v end)
    MakeToggle("Distance", function() return State.ESPDistance end, function(v) State.ESPDistance = v end)
    MakeToggle("Tracer", function() return State.ESPTracer end, function(v) State.ESPTracer = v end)

    MakeSection("Silent Aim")
    MakeToggle("Silent Aim", function() return State.SilentAim end, function(v) State.SilentAim = v end)
    MakeSlider("FOV", 10, 500, function() return State.SilentAimFOV end, function(v) State.SilentAimFOV = v end)
    MakeSlider("Hit Chance %", 1, 100, function() return State.SilentAimHitChance end, function(v) State.SilentAimHitChance = v end)
    MakeToggle("Wall Check", function() return State.SilentAimWallCheck end, function(v) State.SilentAimWallCheck = v end)

    MakeSection("Aimbot")
    MakeToggle("Aimbot", function() return State.Aimbot end, function(v) State.Aimbot = v end)
    MakeSlider("Aimbot FOV", 10, 500, function() return State.AimbotFOV end, function(v) State.AimbotFOV = v end)
    MakeSlider("Smoothness %", 1, 100, function() return math.floor(State.AimbotSmoothness * 100) end, function(v) State.AimbotSmoothness = v / 100 end)

    MakeSection("Combat")
    MakeToggle("Hitbox Expander", function() return State.Hitbox end, function(v) State.Hitbox = v end)
    MakeSlider("Hitbox Size", 2, 30, function() return State.HitboxSize end, function(v) State.HitboxSize = v end)
    MakeToggle("Auto Shoot", function() return State.AutoShoot end, function(v) State.AutoShoot = v end)
    MakeSlider("Shoot Range", 50, 500, function() return State.AutoShootRange end, function(v) State.AutoShootRange = v end)

    MakeSection("Farm")
    MakeToggle("Gun Grab", function() return State.GunGrab end, function(v) State.GunGrab = v end)
    MakeToggle("Coin Farm", function() return State.CoinFarm end, function(v) State.CoinFarm = v end)

    MakeSection("Movement")
    MakeToggle("Speed", function() return State.Speed end, function(v) State.Speed = v; UpdateSpeed() end)
    MakeSlider("Speed Value", 16, 200, function() return State.SpeedValue end, function(v) State.SpeedValue = v; UpdateSpeed() end)
    MakeToggle("Jump", function() return State.Jump end, function(v) State.Jump = v; UpdateJump() end)
    MakeSlider("Jump Value", 50, 500, function() return State.JumpValue end, function(v) State.JumpValue = v; UpdateJump() end)
    MakeToggle("Fly", function() return State.Fly end, function(v) State.Fly = v end)
    MakeSlider("Fly Speed", 20, 300, function() return State.FlySpeed end, function(v) State.FlySpeed = v end)
    MakeToggle("Noclip", function() return State.Noclip end, function(v) State.Noclip = v end)
    MakeToggle("Infinite Jump", function() return State.InfJump end, function(v) State.InfJump = v end)

    MakeSection("Misc")
    MakeToggle("Anti-Ragdoll", function() return State.AntiRagdoll end, function(v) State.AntiRagdoll = v end)
    MakeButton("Kill All", KillAll)
    MakeButton("Server Hop", ServerHop)

    MakeSection("Config")
    MakeButton("Reset All", function()
        for k, _ in pairs(State) do
            if type(State[k]) == "boolean" then State[k] = false end
        end
        Notify("Franz Hub", "All toggles reset")
    end)
end

-- ============================================================
-- SPEED (unchanged, kept exactly as your original)
-- ============================================================
local function UpdateSpeed()
    if not LP.Character or not LP.Character:FindFirstChild("Humanoid") then return end
    LP.Character.Humanoid.WalkSpeed = State.Speed and State.SpeedValue or 16
end

CreateGUI()
Notify("Franz Hub", "Loaded. Silent Aim freeze fixed.")