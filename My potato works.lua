--[[
  ULTRA POTATO SCRIPT - KLASE SCHOOLYARD BRAWLER
  PART 1/8 - SETUP & REMOTE DETECTION
--]]

-- =============================[ SETUP ]====================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote detection (adjust to KLASE's actual remote names)
local remotes = {}
for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        remotes[child.Name] = child
    end
end
local punchRemote = remotes["Punch"] or remotes["Attack"] or remotes["Melee"] or nil
local parryRemote = remotes["Parry"] or remotes["Block"] or nil
local stompRemote = remotes["Stomp"] or remotes["GroundPound"] or nil
local healRemote = remotes["Heal"] or remotes["UseItem"] or nil
local finisherRemote = remotes["Finisher"] or remotes["Execute"] or nil
local dashRemote = remotes["Dash"] or remotes["Dodge"] or nil

-- =============================[ STATE ]====================================
local state = {
    enabled = true,
    uiVisible = true,
    minimized = false,
    floatingLogo = nil,
    settings = {
        autoParry = false,
        autoStomp = false,
        autoPunch = false,
        noCooldownPunch = false,
        silentAim = false,
        killAura = false,
        finisherSpam = false,
        infiniteStamina = false,
        speedBypass = false,
        orbit = false,
        fly = false,
        noclip = false,
        autoDash = false,
        noFallDamage = false,
        rainbowESP = false,
        playerList = false,
        nameTags = false,
        healthBars = false,
        enemyStaminaBars = false,
        yourStaminaBar = false,
        fovCircle = false,
        hudOverlay = false,
        autoHeal = false,
        antiStun = false,
        antiAFK = false,
        antiCheatBypass = false,
        damageTracker = false,
        autoReconnect = false,
    },
    orbitTarget = "Nearest",
    orbitRadius = 15,
    orbitSpeed = 2,
    orbitHeight = 3,
    sizePreset = "Medium",
    damageDealt = 0,
    reconnectAttempts = 0,
    manualTarget = "",
    toggleFunctions = {},
}
-- END PART 1

--[[
  PART 2/8 - ANTI-CHEAT, STAMINA, NO COOLDOWN PUNCH
--]]

-- =============================[ ANTI-CHEAT BYPASS ]=======================
local function bypassSpeed()
    if not state.settings.antiCheatBypass and not state.settings.speedBypass then return end
    if state.settings.speedBypass then
        RunService.Heartbeat:Connect(function()
            if Character and RootPart and Humanoid then
                local moveDir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,-1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit * 45
                    local newPos = RootPart.Position + (RootPart.CFrame.LookVector * moveDir.Z + RootPart.CFrame.RightVector * moveDir.X) * 0.016
                    RootPart.CFrame = CFrame.new(newPos, RootPart.Position + RootPart.CFrame.LookVector)
                end
            end
        end)
    end
    Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if state.settings.antiCheatBypass then
            Humanoid.WalkSpeed = 22
        end
    end)
    task.spawn(function()
        while state.settings.antiCheatBypass do
            Humanoid.WalkSpeed = 22
            task.wait(0.5)
        end
    end)
end

-- =============================[ INFINITE STAMINA ]=========================
local function infiniteStamina()
    if not state.settings.infiniteStamina then return end
    local staminaVal = Character:FindFirstChild("Stamina") or Character:FindFirstChild("StaminaValue")
    if staminaVal then
        staminaVal:GetPropertyChangedSignal("Value"):Connect(function()
            if state.settings.infiniteStamina then
                staminaVal.Value = 100
            end
        end)
        task.spawn(function()
            while state.settings.infiniteStamina do
                staminaVal.Value = 100
                task.wait(0.1)
            end
        end)
    end
    Humanoid.WalkSpeed = state.settings.infiniteStamina and 44 or 22
    Humanoid.JumpPower = state.settings.infiniteStamina and 75 or 50
end

-- =============================[ NO COOLDOWN PUNCH FIX ]====================
local punchLoop
local function startNoCooldownPunch()
    if punchLoop then return end
    punchLoop = task.spawn(function()
        while state.settings.noCooldownPunch do
            if punchRemote and Character and Humanoid and Humanoid.Health > 0 then
                pcall(function() punchRemote:FireServer() end)
                for _, rem in pairs(remotes) do
                    if rem.Name:lower():find("punch") or rem.Name:lower():find("attack") or rem.Name:lower():find("melee") then
                        pcall(function() rem:FireServer() end)
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end
local function stopNoCooldownPunch()
    if punchLoop then task.cancel(punchLoop) punchLoop = nil end
end
-- END PART 2

--[[
  PART 3/8 - KILL AURA, ORBIT, FLY, NOCLIP
--]]

-- =============================[ KILL AURA ]================================
local killAuraLoop
local function startKillAura()
    if killAuraLoop then return end
    killAuraLoop = task.spawn(function()
        while state.settings.killAura do
            local nearest = nil
            local minDist = 30
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (RootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = player
                    end
                end
            end
            if nearest and nearest.Character and Humanoid.Health > 0 then
                RootPart.CFrame = CFrame.new(RootPart.Position, nearest.Character.HumanoidRootPart.Position)
                if punchRemote then pcall(function() punchRemote:FireServer() end) end
                if state.settings.autoStomp and nearest.Character.HumanoidRootPart.Position.Y < RootPart.Position.Y - 2 then
                    if stompRemote then pcall(function() stompRemote:FireServer() end) end
                end
            end
            task.wait(0.2)
        end
    end)
end
local function stopKillAura()
    if killAuraLoop then task.cancel(killAuraLoop) killAuraLoop = nil end
end

-- =============================[ ORBIT ]====================================
local orbitLoop
local function startOrbit()
    if orbitLoop then return end
    orbitLoop = task.spawn(function()
        local angle = 0
        while state.settings.orbit do
            local target = nil
            if state.orbitTarget == "Nearest" then
                local minDist = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (RootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if d < minDist then minDist = d; target = player end
                    end
                end
            elseif state.orbitTarget == "LowestHP" then
                local lowestHP = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                        local hp = player.Character.Humanoid.Health
                        if hp < lowestHP then lowestHP = hp; target = player end
                    end
                end
            elseif state.orbitTarget == "Manual" then
                target = Players:FindFirstChild(state.manualTarget or "")
            end
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = target.Character.HumanoidRootPart.Position
                angle = angle + state.orbitSpeed * 0.02
                local radius = state.orbitRadius
                local x = targetPos.X + radius * math.cos(angle)
                local z = targetPos.Z + radius * math.sin(angle)
                local y = targetPos.Y + state.orbitHeight
                RootPart.CFrame = CFrame.new(Vector3.new(x, y, z), targetPos)
                RootPart.CFrame = CFrame.new(RootPart.Position, targetPos)
            end
            task.wait(0.02)
        end
    end)
end
local function stopOrbit()
    if orbitLoop then task.cancel(orbitLoop) orbitLoop = nil end
end

-- =============================[ FLY ]======================================
local flyLoop
local function startFly()
    if flyLoop then return end
    flyLoop = task.spawn(function()
        while state.settings.fly do
            local move = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move + Vector3.new(0,-1,0) end
            if move.Magnitude > 0 then
                move = move.Unit * 50
                RootPart.CFrame = RootPart.CFrame + (RootPart.CFrame.LookVector * move.Z + RootPart.CFrame.RightVector * move.X + Vector3.new(0, move.Y, 0)) * 0.016
            end
            task.wait()
        end
    end)
end
local function stopFly()
    if flyLoop then task.cancel(flyLoop) flyLoop = nil end
end

-- =============================[ NOCLIP ]===================================
local function toggleNoclip(val)
    if val then
        RootPart.CanCollide = false
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        RootPart.CanCollide = true
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end
-- END PART 3

--[[
  PART 4/8 - AUTO PARRY, AUTO STOMP, AUTO DASH, NO FALL DAMAGE
--]]

-- =============================[ AUTO PARRY ]===============================
local parryLoop
local function startAutoParry()
    if parryLoop then return end
    parryLoop = task.spawn(function()
        while state.settings.autoParry do
            if parryRemote then pcall(function() parryRemote:FireServer() end) end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
            task.wait(0.3)
        end
    end)
end
local function stopAutoParry()
    if parryLoop then task.cancel(parryLoop) parryLoop = nil end
end

-- =============================[ AUTO STOMP ]===============================
local stompLoop
local function startAutoStomp()
    if stompLoop then return end
    stompLoop = task.spawn(function()
        while state.settings.autoStomp do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local enemyRoot = player.Character.HumanoidRootPart
                    if enemyRoot.Position.Y < RootPart.Position.Y - 3 and enemyRoot.Velocity.Y < 1 then
                        if stompRemote then pcall(function() stompRemote:FireServer() end) end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end
local function stopAutoStomp()
    if stompLoop then task.cancel(stompLoop) stompLoop = nil end
end

-- =============================[ AUTO DASH ]================================
local dashLoop
local function startAutoDash()
    if dashLoop then return end
    dashLoop = task.spawn(function()
        while state.settings.autoDash do
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                if dashRemote then pcall(function() dashRemote:FireServer() end) end
                task.wait(0.5)
            end
            task.wait()
        end
    end)
end
local function stopAutoDash()
    if dashLoop then task.cancel(dashLoop) dashLoop = nil end
end

-- =============================[ NO FALL DAMAGE ]===========================
local function noFallDamage()
    if not state.settings.noFallDamage then return end
    Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health > 0 and Humanoid.Health < 20 and RootPart.Velocity.Y < -30 then
            Humanoid.Health = Humanoid.Health + 20
        end
    end)
end

-- =============================[ AUTO HEAL ]================================
local healLoop
local function startAutoHeal()
    if healLoop then return end
    healLoop = task.spawn(function()
        while state.settings.autoHeal do
            if Humanoid.Health < 30 then
                if healRemote then pcall(function() healRemote:FireServer() end) end
                task.wait(1)
            end
            task.wait(0.5)
        end
    end)
end
local function stopAutoHeal()
    if healLoop then task.cancel(healLoop) healLoop = nil end
end

-- =============================[ ANTI STUN ]===============================
local function antiStun()
    if not state.settings.antiStun then return end
    Character:GetPropertyChangedSignal("Parent"):Connect(function()
        if not Character.Parent then return end
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end
-- END PART 4

--[[
  PART 5/8 - RAINBOW ESP & PLAYER LIST
--]]

-- =============================[ RAINBOW ESP ]==============================
local espObjects = {}
local espLoop
local function startESP()
    if espLoop then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local box = Instance.new("BoxHandleAdornment")
            box.Size = Vector3.new(4, 5, 2)
            box.Adornee = char:FindFirstChild("HumanoidRootPart") or char
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Transparency = 0.5
            box.Color3 = Color3.new(1,0,0)
            box.Parent = char
            
            local healthBar = Instance.new("BillboardGui")
            healthBar.Size = UDim2.new(0, 100, 0, 10)
            healthBar.Adornee = char:FindFirstChild("Head") or char
            healthBar.Parent = char
            local frame = Instance.new("Frame", healthBar)
            frame.Size = UDim2.new(1,0,1,0)
            frame.BackgroundColor3 = Color3.new(0,1,0)
            local bg = Instance.new("Frame", healthBar)
            bg.Size = UDim2.new(1,0,1,0)
            bg.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
            bg.ZIndex = 0
            
            espObjects[player] = {box = box, healthBar = healthBar, frame = frame}
        end
    end
    
    espLoop = task.spawn(function()
        while state.settings.rainbowESP do
            for player, data in pairs(espObjects) do
                if player and player.Character then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum then
                        local hp = hum.Health / hum.MaxHealth
                        data.frame.Size = UDim2.new(hp, 0, 1, 0)
                        data.frame.BackgroundColor3 = Color3.new(1-hp, hp, 0)
                        local hue = (tick() % 3) / 3
                        data.box.Color3 = Color3.fromHSV(hue, 1, 1)
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end
local function stopESP()
    if espLoop then task.cancel(espLoop) espLoop = nil end
    for _, data in pairs(espObjects) do
        if data.box then data.box:Destroy() end
        if data.healthBar then data.healthBar:Destroy() end
    end
    espObjects = {}
end

-- =============================[ PLAYER LIST ]==============================
local playerListGui
local playerListLoop
local function startPlayerList()
    if playerListGui then playerListGui:Destroy() end
    playerListGui = Instance.new("ScreenGui")
    playerListGui.Name = "PlayerList"
    playerListGui.Parent = LocalPlayer.PlayerGui
    local list = Instance.new("ScrollingFrame", playerListGui)
    list.Size = UDim2.new(0, 200, 0, 300)
    list.Position = UDim2.new(0.8,0,0.1,0)
    list.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    list.BackgroundTransparency = 0.3
    list.BorderSizePixel = 0
    list.Visible = state.settings.playerList
    
    playerListLoop = task.spawn(function()
        while state.settings.playerList do
            for _, child in ipairs(list:GetChildren()) do child:Destroy() end
            local y = 0
            for _, player in ipairs(Players:GetPlayers()) do
                local label = Instance.new("TextLabel", list)
                label.Size = UDim2.new(1,0,0,20)
                label.Position = UDim2.new(0,0,0,y)
                label.Text = player.Name .. (player == LocalPlayer and " (YOU)" or "")
                label.TextColor3 = Color3.new(1,1,1)
                label.BackgroundTransparency = 1
                label.TextXAlignment = Enum.TextXAlignment.Left
                y = y + 20
            end
            list.CanvasSize = UDim2.new(0,0,0,y)
            task.wait(1)
        end
    end)
end
local function stopPlayerList()
    if playerListLoop then task.cancel(playerListLoop) playerListLoop = nil end
    if playerListGui then playerListGui:Destroy() playerListGui = nil end
end
-- END PART 5

--[[
  PART 6/8 - HUD, FOV, ANTI-AFK, AUTO-RECONNECT, DAMAGE TRACKER
--]]

-- =============================[ HUD OVERLAY ]==============================
local hudGui
local hudLoop
local function startHUD()
    if hudGui then hudGui:Destroy() end
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "HUDOverlay"
    hudGui.Parent = LocalPlayer.PlayerGui
    local speedLabel = Instance.new("TextLabel", hudGui)
    speedLabel.Size = UDim2.new(0,150,0,30)
    speedLabel.Position = UDim2.new(0.01,0,0.85,0)
    speedLabel.Text = "Speed: 0"
    speedLabel.TextColor3 = Color3.new(1,1,1)
    speedLabel.BackgroundTransparency = 1
    local staminaLabel = Instance.new("TextLabel", hudGui)
    staminaLabel.Size = UDim2.new(0,150,0,30)
    staminaLabel.Position = UDim2.new(0.01,0,0.9,0)
    staminaLabel.Text = "Stamina: 100"
    staminaLabel.TextColor3 = Color3.new(1,1,1)
    staminaLabel.BackgroundTransparency = 1
    
    hudLoop = task.spawn(function()
        while state.settings.hudOverlay do
            local vel = RootPart.Velocity
            speedLabel.Text = "Speed: " .. math.floor(vel.Magnitude * 10) / 10
            local stam = Character:FindFirstChild("Stamina")
            if stam then staminaLabel.Text = "Stamina: " .. math.floor(stam.Value) end
            hudGui.Visible = state.settings.hudOverlay
            task.wait(0.1)
        end
    end)
end
local function stopHUD()
    if hudLoop then task.cancel(hudLoop) hudLoop = nil end
    if hudGui then hudGui:Destroy() hudGui = nil end
end

-- =============================[ FOV CIRCLE ]===============================
local fovCircle
local function toggleFOV(val)
    if fovCircle then fovCircle:Destroy() fovCircle = nil end
    if not val then return end
    fovCircle = Instance.new("ScreenGui")
    fovCircle.Name = "FOVCircle"
    fovCircle.Parent = LocalPlayer.PlayerGui
    local circle = Instance.new("ImageLabel", fovCircle)
    circle.Size = UDim2.new(0, 300, 0, 300)
    circle.Position = UDim2.new(0.5, -150, 0.5, -150)
    circle.BackgroundTransparency = 1
    circle.Image = "rbxassetid://123456789"
    circle.Visible = true
end

-- =============================[ ANTI-AFK ]=================================
local afkLoop
local function startAntiAFK()
    if afkLoop then return end
    afkLoop = task.spawn(function()
        while state.settings.antiAFK do
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, nil)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, nil)
            task.wait(60)
        end
    end)
end
local function stopAntiAFK()
    if afkLoop then task.cancel(afkLoop) afkLoop = nil end
end

-- =============================[ AUTO-RECONNECT ]===========================
local function autoReconnect()
    if not state.settings.autoReconnect then return end
    LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
        if not LocalPlayer.Parent then
            state.reconnectAttempts = state.reconnectAttempts + 1
            task.wait(2)
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end
    end)
end

-- =============================[ DAMAGE TRACKER ]===========================
local damageLoop
local function startDamageTracker()
    if damageLoop then return end
    Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health < Humanoid.MaxHealth then
            state.damageDealt = state.damageDealt + (Humanoid.MaxHealth - Humanoid.Health)
        end
    end)
    damageLoop = task.spawn(function()
        while state.settings.damageTracker do
            print("Total Damage Dealt: " .. state.damageDealt)
            task.wait(30)
        end
    end)
end
local function stopDamageTracker()
    if damageLoop then task.cancel(damageLoop) damageLoop = nil end
end
-- END PART 6
--[[
  PART 7/8 - FLOATING LOGO
--]]

-- =============================[ FLOATING LOGO ]============================
local logoGui
local function createFloatingLogo()
    if logoGui then return end
    logoGui = Instance.new("ScreenGui")
    logoGui.Name = "FloatingLogo"
    logoGui.Parent = LocalPlayer.PlayerGui
    logoGui.ResetOnSpawn = false
    
    local logoBtn = Instance.new("TextButton", logoGui)
    logoBtn.Size = UDim2.new(0, 60, 0, 60)
    logoBtn.Position = UDim2.new(0.9, 0, 0.85, 0)
    logoBtn.Text = "🥔"
    logoBtn.TextSize = 40
    logoBtn.BackgroundColor3 = Color3.new(0.2, 0.1, 0.3)
    logoBtn.BackgroundTransparency = 0.3
    logoBtn.BorderSizePixel = 0
    logoBtn.ClipsDescendants = true
    logoBtn.Name = "PotatoLogo"
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    logoBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = logoBtn.Position
        end
    end)
    logoBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            logoBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    logoBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Tap to reopen
    logoBtn.MouseButton1Click:Connect(function()
        if screenGui then
            screenGui.Enabled = true
            mainFrame.Visible = true
            state.minimized = false
            if logoGui then logoGui:Destroy() logoGui = nil end
        else
            createUI()
            if logoGui then logoGui:Destroy() logoGui = nil end
        end
    end)
    state.floatingLogo = logoBtn
end

local function destroyFloatingLogo()
    if logoGui then logoGui:Destroy() logoGui = nil end
end
-- END PART 7

--[[
  PART 8/8 - UI CONSTRUCTION & MAIN INIT
--]]

-- =============================[ UI CONSTRUCTION ]==========================
local screenGui
local mainFrame
local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PotatoUI"
    screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = state.sizePreset == "Small" and UDim2.new(0, 300, 0, 500) or 
                     state.sizePreset == "Large" and UDim2.new(0, 450, 0, 650) or 
                     UDim2.new(0, 375, 0, 575)
    mainFrame.Position = UDim2.new(0.5, -mainFrame.Size.X.Offset/2, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    
    -- Dragging
    local dragMain = false
    local dragStartM, startPosM
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragMain = true
            dragStartM = input.Position
            startPosM = mainFrame.Position
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if dragMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStartM
            mainFrame.Position = UDim2.new(startPosM.X.Scale, startPosM.X.Offset + delta.X, startPosM.Y.Scale, startPosM.Y.Offset + delta.Y)
        end
    end)
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragMain = false
        end
    end)
    
    -- Title Bar
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1,0,0,30)
    titleBar.BackgroundColor3 = Color3.new(0.3, 0.1, 0.4)
    titleBar.BackgroundTransparency = 0.3
    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(0.7,0,1,0)
    title.Text = "🥔 POTATO PANEL"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0.05,0,0,0)
    
    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0,30,0,30)
    minBtn.Position = UDim2.new(0.7,0,0,0)
    minBtn.Text = "─"
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.BackgroundTransparency = 0.5
    minBtn.MouseButton1Click:Connect(function()
        state.minimized = not state.minimized
        mainFrame.Visible = not state.minimized
        if state.minimized then createFloatingLogo() else destroyFloatingLogo() end
    end)
    
    local removeBtn = Instance.new("TextButton", titleBar)
    removeBtn.Size = UDim2.new(0,30,0,30)
    removeBtn.Position = UDim2.new(0.8,0,0,0)
    removeBtn.Text = "✕"
    removeBtn.TextColor3 = Color3.new(1,1,1)
    removeBtn.BackgroundTransparency = 0.5
    removeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        createFloatingLogo()
    end)
    
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0,30,0,30)