--[[
========================================================
                MM2 HUB V1.0
        Murder Mystery 2 Exploit Script
        
========================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--========================================================
-- CONFIG
--========================================================

local CONFIG = {
	Title = "MM2 HUB",
	Subtitle = "MURDER MYSTERY 2",

	Tabs = {
		{Icon = "⚔️", Name = "Combat"},
		{Icon = "🔫", Name = "Weapons"},
		{Icon = "👁️", Name = "Visual"},
		{Icon = "🏃", Name = "Movement"},
		{Icon = "😈", Name = "Troll"},
	},

	Size = Vector2.new(900, 550),

	Background = Color3.fromRGB(7, 9, 20),
	Panel = Color3.fromRGB(11, 15, 32),
	Panel2 = Color3.fromRGB(17, 22, 45),

	Accent = Color3.fromRGB(143, 65, 255),
	Accent2 = Color3.fromRGB(50, 175, 255),

	Text = Color3.fromRGB(245, 245, 255),
	SubText = Color3.fromRGB(145, 155, 190),

	Stroke = Color3.fromRGB(75, 75, 140),

	Blur = true,
	BlurSize = 8,
	AnimationSpeed = 0.3,
	Draggable = true,
}

--========================================================
-- HELPERS
--========================================================

local function Tween(object, time, properties, style, direction)
	local info = TweenInfo.new(time or CONFIG.AnimationSpeed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	return TweenService:Create(object, info, properties)
end

local function Corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
	return c
end

local function Stroke(object, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or CONFIG.Stroke
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = object
	return s
end

local function Gradient(object, color1, color2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	})
	g.Rotation = rotation or 0
	g.Parent = object
	return g
end

--========================================================
-- STATE (all features OFF)
--========================================================

local State = {
	KillAura = false,
	ShootMurd = false,
	AutoGetGun = false,
	ESP = false,
	NameTags = false,
	Speed = false,
	NoClip = false,
	AntiFling = false,
	NormalFling = false,
	Slam = false,
	Rocket = false,
	InvertedMovement = false,
	AntiFlingShield = false,
	TargetInfo = false,
	SelectedPlayer = nil,
}

--========================================================
-- REMOTES (found from RemoteSpy)
--========================================================

local function GetNil(name, debugId)
	for _, obj in ipairs(getnilinstances()) do
		if obj.Name == name then
			if debugId then
				local ok, id = pcall(function() return obj:GetDebugId() end)
				if ok and id == debugId then return obj end
			else
				return obj
			end
		end
	end
	return nil
end

local KnifeRemote = nil
local GunBeam = ReplicatedStorage:WaitForChild("WeaponEvents", 10) and ReplicatedStorage.WeaponEvents:FindFirstChild("GunBeam")

local function refreshRemotes()
	if not KnifeRemote then
		KnifeRemote = GetNil("KnifeStabbed", "1_979055") or GetNil("KnifeStabbed")
	end
end

--========================================================
-- GUI
--========================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "MM2Hub"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = PlayerGui

-- Blur
local BlurEffect
if CONFIG.Blur then
	BlurEffect = Instance.new("BlurEffect")
	BlurEffect.Name = "MM2Blur"
	BlurEffect.Size = 0
	BlurEffect.Parent = Lighting
	Tween(BlurEffect, 0.6, {Size = CONFIG.BlurSize}):Play()
end

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(CONFIG.Size.X, CONFIG.Size.Y)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = CONFIG.Background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI
Corner(Main, 20)
Stroke(Main, CONFIG.Stroke, 1.5, 0.15)
Gradient(Main, Color3.fromRGB(11, 8, 28), Color3.fromRGB(6, 17, 34), 35)

-- Neon border
local BorderGlow = Instance.new("UIStroke")
BorderGlow.Color = CONFIG.Accent
BorderGlow.Thickness = 2
BorderGlow.Transparency = 0.45
BorderGlow.Parent = Main

task.spawn(function()
	while Main.Parent do
		Tween(BorderGlow, 1.4, {Transparency = 0.15, Color = CONFIG.Accent2}):Play()
		task.wait(1.4)
		if not Main.Parent then break end
		Tween(BorderGlow, 1.4, {Transparency = 0.5, Color = CONFIG.Accent}):Play()
		task.wait(1.4)
	end
end)

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 72)
TopBar.BackgroundTransparency = 1
TopBar.Parent = Main

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.fromOffset(65, 55)
Logo.Position = UDim2.fromOffset(22, 8)
Logo.BackgroundTransparency = 1
Logo.Text = "🔪"
Logo.TextSize = 42
Logo.TextColor3 = CONFIG.Accent
Logo.Font = Enum.Font.GothamBold
Logo.Parent = TopBar

task.spawn(function()
	while Logo.Parent do
		Tween(Logo, 1.2, {TextColor3 = CONFIG.Accent2, Rotation = 5}):Play()
		task.wait(1.2)
		if not Logo.Parent then break end
		Tween(Logo, 1.2, {TextColor3 = CONFIG.Accent, Rotation = -5}):Play()
		task.wait(1.2)
	end
end)

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(90, 13)
Title.Size = UDim2.fromOffset(300, 30)
Title.BackgroundTransparency = 1
Title.Text = CONFIG.Title
Title.TextColor3 = CONFIG.Text
Title.TextSize = 25
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.fromOffset(92, 40)
Subtitle.Size = UDim2.fromOffset(300, 20)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = CONFIG.Subtitle
Subtitle.TextColor3 = CONFIG.SubText
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

-- Window buttons
local function CreateWindowButton(text, position)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromOffset(38, 38)
	Button.Position = UDim2.new(1, position, 0, 17)
	Button.AnchorPoint = Vector2.new(1, 0)
	Button.BackgroundColor3 = CONFIG.Panel2
	Button.Text = text
	Button.TextColor3 = CONFIG.SubText
	Button.TextSize = 18
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = TopBar
	Corner(Button, 10)
	Stroke(Button, CONFIG.Stroke, 1, 0.35)

	Button.MouseEnter:Connect(function()
		Tween(Button, 0.15, {BackgroundColor3 = CONFIG.Accent, TextColor3 = CONFIG.Text}):Play()
	end)
	Button.MouseLeave:Connect(function()
		Tween(Button, 0.15, {BackgroundColor3 = CONFIG.Panel2, TextColor3 = CONFIG.SubText}):Play()
	end)
	return Button
end

local Minimize = CreateWindowButton("—", -65)
local Close = CreateWindowButton("×", -18)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(15, 82)
Sidebar.Size = UDim2.new(0, 205, 1, -97)
Sidebar.BackgroundColor3 = CONFIG.Panel
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Corner(Sidebar, 15)
Stroke(Sidebar, CONFIG.Stroke, 1, 0.45)
Gradient(Sidebar, Color3.fromRGB(15, 12, 34), Color3.fromRGB(8, 18, 34), 90)

local TabContainer = Instance.new("Frame")
TabContainer.Position = UDim2.fromOffset(10, 15)
TabContainer.Size = UDim2.new(1, -20, 1, -30)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 9)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabContainer

-- Content area
local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(235, 82)
Content.Size = UDim2.new(1, -250, 1, -97)
Content.BackgroundColor3 = CONFIG.Panel
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Main
Corner(Content, 15)
Stroke(Content, CONFIG.Stroke, 1, 0.4)

-- Page system
local Pages = {}
local TabButtons = {}
local CurrentPage

local function CreatePage(index)
	local Page = Instance.new("ScrollingFrame")
	Page.Name = "Page_" .. index
	Page.Size = UDim2.fromScale(1, 1)
	Page.Position = UDim2.fromOffset(0, 0)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = CONFIG.Accent
	Page.Visible = false
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Parent = Content
	Pages[index] = Page
	return Page
end

--========================================================
-- COMPONENTS
--========================================================

local function CreateToggle(Page, y, labelText, defaultState, callback)
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, -50, 0, 55)
	Row.Position = UDim2.fromOffset(25, y)
	Row.BackgroundColor3 = CONFIG.Panel2
	Row.BorderSizePixel = 0
	Row.Parent = Page
	Corner(Row, 10)
	Stroke(Row, CONFIG.Stroke, 1, 0.5)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -120, 0, 30)
	Label.Position = UDim2.fromOffset(15, 12)
	Label.BackgroundTransparency = 1
	Label.Text = labelText
	Label.TextColor3 = CONFIG.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.GothamBold
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Row

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.fromOffset(80, 32)
	Btn.Position = UDim2.new(1, -95, 0.5, -16)
	Btn.BackgroundColor3 = defaultState and Color3.fromRGB(35, 120, 60) or Color3.fromRGB(60, 25, 35)
	Btn.Text = defaultState and "ON" or "OFF"
	Btn.TextColor3 = CONFIG.Text
	Btn.TextSize = 13
	Btn.Font = Enum.Font.GothamBold
	Btn.AutoButtonColor = false
	Btn.Parent = Row
	Corner(Btn, 8)

	local On = defaultState

	Btn.MouseButton1Click:Connect(function()
		On = not On
		Tween(Btn, 0.2, {
			BackgroundColor3 = On and Color3.fromRGB(35, 120, 60) or Color3.fromRGB(60, 25, 35)
		}):Play()
		Btn.Text = On and "ON" or "OFF"
		Btn.TextColor3 = On and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 120, 120)
		if callback then callback(On) end
	end)

	return Row
end

local function CreateLabel(Page, y, text)
	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, -50, 0, 28)
	L.Position = UDim2.fromOffset(25, y)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = CONFIG.Accent
	L.TextSize = 14
	L.Font = Enum.Font.GothamBold
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Parent = Page
	return L
end

local function CreateButton(Page, y, text, callback)
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, -50, 0, 42)
	Btn.Position = UDim2.fromOffset(25, y)
	Btn.BackgroundColor3 = CONFIG.Panel2
	Btn.Text = text
	Btn.TextColor3 = CONFIG.Text
	Btn.TextSize = 14
	Btn.Font = Enum.Font.GothamBold
	Btn.AutoButtonColor = false
	Btn.Parent = Page
	Corner(Btn, 10)
	Stroke(Btn, CONFIG.Accent, 1, 0.4)

	Btn.MouseEnter:Connect(function()
		Tween(Btn, 0.15, {BackgroundColor3 = CONFIG.Accent}):Play()
	end)
	Btn.MouseLeave:Connect(function()
		Tween(Btn, 0.15, {BackgroundColor3 = CONFIG.Panel2}):Play()
	end)

	Btn.MouseButton1Click:Connect(callback)
	return Btn
end

--========================================================
-- FEATURE LOGIC
--========================================================

-- Kill Aura
local killAuraConn
local function getNearestPlayer(range)
	local nearest, minD = nil, range or 10
	local myChar = Player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (myRoot.Position - hrp.Position).Magnitude
				if d < minD then
					minD = d
					nearest = p
				end
			end
		end
	end
	return nearest
end

local function startKillAura()
	if killAuraConn then killAuraConn:Disconnect() end
	killAuraConn = RunService.Heartbeat:Connect(function()
		if not State.KillAura then return end
		refreshRemotes()
		if not KnifeRemote then return end
		local target = getNearestPlayer(10)
		if target and target.Character then
			local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
			local tgtRoot = target.Character:FindFirstChild("HumanoidRootPart")
			if myRoot and tgtRoot then
				myRoot.CFrame = CFrame.new(myRoot.Position, tgtRoot.Position)
				pcall(function() KnifeRemote:FireServer() end)
			end
		end
	end)
end

local function stopKillAura()
	if killAuraConn then killAuraConn:Disconnect() killAuraConn = nil end
end

-- Shoot Murd
local function shootMurd()
	local murderer = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character then
			local bp = p:FindFirstChild("Backpack")
			if bp then
				for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and t.Name:lower():find("knife") then
						murderer = p
						break
					end
				end
			end
			if murderer then break end
		end
	end
	if not murderer or not murderer.Character then
		StarterGui:SetCore("SendNotification", {
			Title = "MM2 Hub",
			Text = "No murderer found.",
			Duration = 3,
		})
		return
	end
	local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	local tgtRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
	local tgtHead = murderer.Character:FindFirstChild("Head")
	if not myRoot or not tgtRoot then return end
	local aim = tgtHead or tgtRoot
	myRoot.CFrame = CFrame.new(myRoot.Position, aim.Position)
	local remote = GunBeam
	if not remote then
		for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
			if v:IsA("RemoteEvent") and v.Name:lower():find("gun") then
				remote = v
				break
			end
		end
	end
	if remote then
		pcall(function()
			remote:FireServer(myRoot.CFrame, CFrame.new(aim.Position))
		end)
	end
	StarterGui:SetCore("SendNotification", {
		Title = "Shoot Murd",
		Text = "Fired at " .. murderer.Name,
		Duration = 2,
	})
end

-- Auto Get Gun
local autoGunConn
local function startAutoGun()
	if autoGunConn then autoGunConn:Disconnect() end
	autoGunConn = RunService.Heartbeat:Connect(function()
		if not State.AutoGetGun then return end
		local myChar = Player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Tool") and obj.Name:lower():find("gun") then
				local p = obj.Parent
				if p and p ~= myChar and not p:IsA("Backpack") then
					local saved = myRoot.CFrame
					pcall(function()
						myRoot.CFrame = CFrame.new(obj.Position)
						task.wait(0.15)
						myRoot.CFrame = saved
					end)
					break
				end
			end
		end
	end)
end

local function stopAutoGun()
	if autoGunConn then autoGunConn:Disconnect() autoGunConn = nil end
end
-- END PART 2

-- ESP Roles
local espObjects = {}
local espConn
local function getRole(p)
	local bp = p:FindFirstChild("Backpack")
	local char = p.Character
	local hasKnife, hasGun = false, false
	local function scan(container)
		if not container then return end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if n:find("knife") then hasKnife = true end
				if n:find("gun") then hasGun = true end
			end
		end
	end
	scan(bp)
	scan(char)
	if hasKnife then return "Murderer", Color3.fromRGB(255, 60, 60) end
	if hasGun then return "Sheriff", Color3.fromRGB(60, 160, 255) end
	return "Innocent", Color3.fromRGB(80, 255, 120)
end

local function startESP()
	if espConn then espConn:Disconnect() end
	espConn = RunService.Heartbeat:Connect(function()
		if not State.ESP then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player and p.Character then
				local role, color = getRole(p)
				if not espObjects[p] then
					local bb = Instance.new("BillboardGui")
					bb.Name = "MM2ESP"
					bb.Size = UDim2.new(0, 120, 0, 30)
					bb.AlwaysOnTop = true
					bb.Parent = p.Character
					local lbl = Instance.new("TextLabel", bb)
					lbl.Size = UDim2.new(1, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.TextStrokeTransparency = 0
					lbl.TextSize = 16
					lbl.Font = Enum.Font.GothamBold
					lbl.Text = role
					lbl.TextColor3 = color
					espObjects[p] = {bb = bb, lbl = lbl}
				else
					local data = espObjects[p]
					data.lbl.Text = role
					data.lbl.TextColor3 = color
					data.bb.Adornee = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
				end
			end
		end
	end)
end

local function stopESP()
	if espConn then espConn:Disconnect() espConn = nil end
	for p, data in pairs(espObjects) do
		if data.bb then data.bb:Destroy() end
	end
	espObjects = {}
end

-- Name Tags
local nameConn
local nameObjs = {}
local function startNameTags()
	if nameConn then nameConn:Disconnect() end
	nameConn = RunService.Heartbeat:Connect(function()
		if not State.NameTags then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player and p.Character then
				if not nameObjs[p] then
					local bb = Instance.new("BillboardGui")
					bb.Size = UDim2.new(0, 120, 0, 20)
					bb.AlwaysOnTop = true
					bb.StudsOffset = Vector3.new(0, 3, 0)
					bb.Parent = p.Character
					local lbl = Instance.new("TextLabel", bb)
					lbl.Size = UDim2.new(1, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.TextStrokeTransparency = 0
					lbl.TextSize = 13
					lbl.Font = Enum.Font.GothamBold
					lbl.Text = p.DisplayName
					lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
					nameObjs[p] = bb
					bb.Adornee = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
				end
			end
		end
	end)
end

local function stopNameTags()
	if nameConn then nameConn:Disconnect() nameConn = nil end
	for p, bb in pairs(nameObjs) do
		if bb then bb:Destroy() end
	end
	nameObjs = {}
end

-- Speed
local function applySpeed(on)
	local char = Player.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = on and 60 or 16
	end
end

Player.CharacterAdded:Connect(function(char)
	task.wait(1)
	if State.Speed then
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = 60 end
	end
end)

-- NoClip
local noclipConn
local function applyNoClip(on)
	State.NoClip = on
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			if not State.NoClip then return end
			local char = Player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

-- Anti-Fling
local antiFlingConn
local function startAntiFling()
	if antiFlingConn then antiFlingConn:Disconnect() end
	antiFlingConn = RunService.Stepped:Connect(function()
		if not State.AntiFling then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part.Name == "HumanoidRootPart" and part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
		local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
		if myRoot and myRoot.AssemblyLinearVelocity.Magnitude > 300 then
			myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

local function stopAntiFling()
	if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
end

-- Fling functions
local flingConn
local function flingNormal(target)
	if not target or not target.Character then return end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for _, c in ipairs(hrp:GetChildren()) do
		if c:IsA("BodyVelocity") or c:IsA("BodyAngularVelocity") then c:Destroy() end
	end
	local bv = Instance.new("BodyVelocity", hrp)
	bv.Velocity = Vector3.new(0, 9999, 0)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	local bav = Instance.new("BodyAngularVelocity", hrp)
	bav.AngularVelocity = Vector3.new(math.random(-9999,9999), math.random(-9999,9999), math.random(-9999,9999))
	bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	task.delay(1, function()
		if bv.Parent then bv:Destroy() end
		if bav.Parent then bav:Destroy() end
	end)
end

local function flingSlam(target)
	if not target or not target.Character then return end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not myRoot then return end
	myRoot.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
	myRoot.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
end

local function flingRocket(target)
	if not target or not target.Character then return end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for _, c in ipairs(hrp:GetChildren()) do
		if c:IsA("BodyVelocity") or c:IsA("BodyAngularVelocity") then c:Destroy() end
	end
	local bv = Instance.new("BodyVelocity", hrp)
	bv.Velocity = Vector3.new(0, 5000, 0)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	local bav = Instance.new("BodyAngularVelocity", hrp)
	bav.AngularVelocity = Vector3.new(0, 500, 0)
	bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	task.delay(1.5, function()
		if bv.Parent then bv:Destroy() end
		if bav.Parent then bav:Destroy() end
	end)
end

local invertedConn
local function startInverted(target)
	if invertedConn then invertedConn:Disconnect() end
	invertedConn = RunService.Heartbeat:Connect(function()
		if not State.InvertedMovement then return end
		if not target or not target.Character then return end
		local tgtRoot = target.Character:FindFirstChild("HumanoidRootPart")
		local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
		if tgtRoot and myRoot then
			local dir = (myRoot.Position - tgtRoot.Position).Unit
			local standPos = tgtRoot.Position + dir * 2
			myRoot.CFrame = CFrame.new(standPos, tgtRoot.Position)
		end
	end)
end

local function stopInverted()
	if invertedConn then invertedConn:Disconnect() invertedConn = nil end
end

local function stopAllFling()
	if flingConn then flingConn:Disconnect() flingConn = nil end
	stopInverted()
end

-- Anti-Fling Shield
local shieldConn
local function startShield()
	if shieldConn then shieldConn:Disconnect() end
	shieldConn = RunService.Stepped:Connect(function()
		if not State.AntiFlingShield then return end
		local myChar = Player.Character
		if myChar then
			for _, part in ipairs(myChar:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end)
end

local function stopShield()
	if shieldConn then shieldConn:Disconnect() shieldConn = nil end
end
-- END PART 3

--========================================================
-- PAGES
--========================================================

-- Combat Page
local combatPage = CreatePage(1)
do
	local y = 20
	CreateLabel(combatPage, y, "⚔️ Combat")
	y = y + 35

	CreateToggle(combatPage, y, "Kill Aura", false, function(on)
		State.KillAura = on
		if on then startKillAura() else stopKillAura() end
	end)
	y = y + 65

	CreateToggle(combatPage, y, "Shoot Murd", false, function(on)
		State.ShootMurd = on
		if on then shootMurd() end
	end)
	y = y + 65

	CreateButton(combatPage, y, "🎯 Fire at Murderer", function()
		shootMurd()
	end)
	y = y + 55

	combatPage.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

-- Weapons Page
local weaponsPage = CreatePage(2)
do
	local y = 20
	CreateLabel(weaponsPage, y, "🔫 Weapons")
	y = y + 35

	CreateToggle(weaponsPage, y, "Auto Get Gun", false, function(on)
		State.AutoGetGun = on
		if on then startAutoGun() else stopAutoGun() end
	end)
	y = y + 65

	weaponsPage.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

-- Visual Page
local visualPage = CreatePage(3)
do
	local y = 20
	CreateLabel(visualPage, y, "👁️ Visual")
	y = y + 35

	CreateToggle(visualPage, y, "ESP Roles", false, function(on)
		State.ESP = on
		if on then startESP() else stopESP() end
	end)
	y = y + 65

	CreateToggle(visualPage, y, "Name Tags", false, function(on)
		State.NameTags = on
		if on then startNameTags() else stopNameTags() end
	end)
	y = y + 65

	visualPage.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

-- Movement Page
local movementPage = CreatePage(4)
do
	local y = 20
	CreateLabel(movementPage, y, "🏃 Movement")
	y = y + 35

	CreateToggle(movementPage, y, "Speed Boost", false, function(on)
		State.Speed = on
		applySpeed(on)
	end)
	y = y + 65

	CreateToggle(movementPage, y, "NoClip", false, function(on)
		applyNoClip(on)
	end)
	y = y + 65

	CreateToggle(movementPage, y, "Anti-Fling", false, function(on)
		State.AntiFling = on
		if on then startAntiFling() else stopAntiFling() end
	end)
	y = y + 65

	movementPage.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

-- Troll Page
local trollPage = CreatePage(5)
do
	local y = 20
	CreateLabel(trollPage, y, "😈 Troll")
	y = y + 35

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Size = UDim2.new(1, -50, 0, 28)
	selectedLabel.Position = UDim2.fromOffset(25, y)
	selectedLabel.BackgroundColor3 = CONFIG.Panel2
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = CONFIG.Text
	selectedLabel.TextSize = 13
	selectedLabel.Font = Enum.Font.GothamBold
	selectedLabel.Parent = trollPage
	Corner(selectedLabel, 8)
	y = y + 38

	local playerList = Instance.new("ScrollingFrame")
	playerList.Size = UDim2.new(1, -50, 0, 150)
	playerList.Position = UDim2.fromOffset(25, y)
	playerList.BackgroundColor3 = CONFIG.Panel2
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 4
	playerList.ScrollBarImageColor3 = CONFIG.Accent
	playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
	playerList.Parent = trollPage
	Corner(playerList, 10)

	local function refreshPlayerList()
		for _, c in ipairs(playerList:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local ly = 4
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player then
				local btn = Instance.new("TextButton", playerList)
				btn.Size = UDim2.new(1, -8, 0, 28)
				btn.Position = UDim2.fromOffset(4, ly)
				btn.BackgroundColor3 = CONFIG.Panel
				btn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
				btn.TextColor3 = CONFIG.Text
				btn.TextSize = 12
				btn.Font = Enum.Font.Gotham
				btn.AutoButtonColor = false
				btn.Parent = playerList
				Corner(btn, 6)
				btn.MouseButton1Click:Connect(function()
					State.SelectedPlayer = p
					selectedLabel.Text = "Selected: " .. p.DisplayName
				end)
				ly = ly + 32
			end
		end
		playerList.CanvasSize = UDim2.new(0, 0, 0, ly + 4)
	end

	refreshPlayerList()
	Players.PlayerAdded:Connect(refreshPlayerList)
	Players.PlayerRemoving:Connect(refreshPlayerList)

	y = y + 160

	CreateButton(trollPage, y, "🚀 Normal Fling", function()
		if State.SelectedPlayer then flingNormal(State.SelectedPlayer) end
	end)
	y = y + 50

	CreateButton(trollPage, y, "💥 Slam", function()
		if State.SelectedPlayer then flingSlam(State.SelectedPlayer) end
	end)
	y = y + 50

	CreateButton(trollPage, y, "🎇 Rocket", function()
		if State.SelectedPlayer then flingRocket(State.SelectedPlayer) end
	end)
	y = y + 50

	CreateToggle(trollPage, y, "Inverted Movement", false, function(on)
		State.InvertedMovement = on
		if on then startInverted(State.SelectedPlayer) else stopInverted() end
	end)
	y = y + 65

	CreateToggle(trollPage, y, "Anti-Fling Shield", false, function(on)
		State.AntiFlingShield = on
		if on then startShield() else stopShield() end
	end)
	y = y + 65

	CreateButton(trollPage, y, "⏹️ Stop All Flings", function()
		stopAllFling()
	end)
	y = y + 55

	trollPage.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

--========================================================
-- TAB CREATION
--========================================================

for index, tabData in ipairs(CONFIG.Tabs) do
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 52)
	Button.BackgroundColor3 = CONFIG.Panel
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.LayoutOrder = index
	Button.Parent = TabContainer
	Corner(Button, 11)
	Stroke(Button, CONFIG.Stroke, 1, 0.7)

	local Icon = Instance.new("TextLabel")
	Icon.Size = UDim2.fromOffset(35, 52)
	Icon.Position = UDim2.fromOffset(12, 0)
	Icon.BackgroundTransparency = 1
	Icon.Text = tabData.Icon
	Icon.TextSize = 21
	Icon.TextColor3 = CONFIG.SubText
	Icon.Font = Enum.Font.GothamBold
	Icon.Parent = Button

	local Name = Instance.new("TextLabel")
	Name.Size = UDim2.new(1, -60, 1, 0)
	Name.Position = UDim2.fromOffset(55, 0)
	Name.BackgroundTransparency = 1
	Name.Text = tabData.Name
	Name.TextColor3 = CONFIG.SubText
	Name.TextSize = 14
	Name.Font = Enum.Font.GothamMedium
	Name.TextXAlignment = Enum.TextXAlignment.Left
	Name.Parent = Button

	local Indicator = Instance.new("Frame")
	Indicator.Size = UDim2.fromOffset(3, 28)
	Indicator.Position = UDim2.new(0, 0, 0.5, 0)
	Indicator.AnchorPoint = Vector2.new(0, 0.5)
	Indicator.BackgroundColor3 = CONFIG.Accent
	Indicator.BorderSizePixel = 0
	Indicator.BackgroundTransparency = 1
	Indicator.Parent = Button
	Corner(Indicator, 5)

	TabButtons[index] = {Button = Button, Icon = Icon, Name = Name, Indicator = Indicator}

	Button.MouseEnter:Connect(function()
		if CurrentPage ~= index then
			Tween(Button, 0.15, {BackgroundColor3 = CONFIG.Panel2}):Play()
		end
	end)
	Button.MouseLeave:Connect(function()
		if CurrentPage ~= index then
			Tween(Button, 0.15, {BackgroundColor3 = CONFIG.Panel}):Play()
		end
	end)

	Button.MouseButton1Click:Connect(function()
		if CurrentPage and Pages[CurrentPage] then
			Pages[CurrentPage].Visible = false
			local old = TabButtons[CurrentPage]
			Tween(old.Button, 0.2, {BackgroundColor3 = CONFIG.Panel}):Play()
			Tween(old.Indicator, 0.2, {BackgroundTransparency = 1}):Play()
			Tween(old.Icon, 0.2, {TextColor3 = CONFIG.SubText}):Play()
			Tween(old.Name, 0.2, {TextColor3 = CONFIG.SubText}):Play()
		end
		CurrentPage = index
		local page = Pages[index]
		page.Visible = true
		page.Position = UDim2.fromOffset(25, 0)
		Tween(page, CONFIG.AnimationSpeed, {Position = UDim2.fromOffset(0, 0)}):Play()
		local nt = TabButtons[index]
		Tween(nt.Button, 0.2, {BackgroundColor3 = Color3.fromRGB(35, 27, 65)}):Play()
		Tween(nt.Indicator, 0.2, {BackgroundTransparency = 0}):Play()
		Tween(nt.Icon, 0.2, {TextColor3 = CONFIG.Text}):Play()
		Tween(nt.Name, 0.2, {TextColor3 = CONFIG.Text}):Play()
	end)
end

CurrentPage = 1
Pages[1].Visible = true
TabButtons[1].Button.BackgroundColor3 = Color3.fromRGB(35, 27, 65)
TabButtons[1].Indicator.BackgroundTransparency = 0
TabButtons[1].Icon.TextColor3 = CONFIG.Text
TabButtons[1].Name.TextColor3 = CONFIG.Text

--========================================================
-- MINIMIZE / CLOSE
--========================================================

local Open = true

Minimize.MouseButton1Click:Connect(function()
	if Open then
		Open = false
		Tween(Main, 0.35, {Size = UDim2.fromOffset(CONFIG.Size.X, 72)}):Play()
	else
		Open = true
		Tween(Main, 0.4, {Size = UDim2.fromOffset(CONFIG.Size.X, CONFIG.Size.Y)}):Play()
	end
end)

local logoGui
local function createFloatingLogo()
	if logoGui then return end
	logoGui = Instance.new("ScreenGui")
	logoGui.Name = "MM2FloatingLogo"
	logoGui.Parent = PlayerGui
	logoGui.ResetOnSpawn = false

	local logoBtn = Instance.new("TextButton", logoGui)
	logoBtn.Size = UDim2.new(0, 60, 0, 60)
	logoBtn.Position = UDim2.new(0.9, 0, 0.8, 0)
	logoBtn.Text = "🔪"
	logoBtn.TextSize = 30
	logoBtn.BackgroundColor3 = CONFIG.Panel
	logoBtn.BorderSizePixel = 0
	logoBtn.Active = true
	logoBtn.Draggable = true
	Corner(logoBtn, 30)
	Stroke(logoBtn, CONFIG.Accent, 2, 0.2)

	logoBtn.MouseButton1Click:Connect(function()
		GUI.Enabled = true
		if logoGui then logoGui:Destroy() logoGui = nil end
	end)
end

local function destroyFloatingLogo()
	if logoGui then logoGui:Destroy() logoGui = nil end
end

Close.MouseButton1Click:Connect(function()
	local anim = Tween(Main, 0.35, {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1
	}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	anim:Play()
	if BlurEffect then
		Tween(BlurEffect, 0.35, {Size = 0}):Play()
	end
	anim.Completed:Wait()
	GUI.Enabled = false
	Main.Size = UDim2.fromOffset(CONFIG.Size.X, CONFIG.Size.Y)
	Main.BackgroundTransparency = 0
	createFloatingLogo()
end)

if CONFIG.Draggable then
	local Dragging = false
	local DragStart
	local StartPosition

	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not Dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local Delta = input.Position - DragStart
			Main.Position = UDim2.new(
				StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
				StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
			)
		end
	end)
end

local FinalSize = UDim2.fromOffset(CONFIG.Size.X, CONFIG.Size.Y)
Main.Size = UDim2.fromOffset(0, 0)
Tween(Main, 0.6, {Size = FinalSize}, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

print("🥔 MM2 HUB loaded! All features OFF by default.")
-- END PART 4