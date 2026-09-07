--// TACTICAL FPS PANEL
--// LocalScript - StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
	Aim = false,
	WallCheck = true,
	FOV = 180,
	Prediction = 0.12,

	ESP = false,
	ESPTransparency = 0.72,
	RainbowSpeed = 0.2
}

local Connections = {}
local Highlights = {}
local Removed = false

local function Connect(connection)
	table.insert(Connections, connection)
	return connection
end

local function New(class, properties, parent)
	local object = Instance.new(class)

	for property, value in pairs(properties) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

--==================================================
-- GUI
--==================================================

local GUI = New("ScreenGui", {
	Name = "TacticalFPSPanel",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, LP:WaitForChild("PlayerGui"))

local Main = New("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(285, 255),
	Position = UDim2.new(0.5, -142, 0.5, -127),
	BackgroundColor3 = Color3.fromRGB(18, 19, 24),
	BorderSizePixel = 0
}, GUI)

New("UICorner", {
	CornerRadius = UDim.new(0, 12)
}, Main)

New("UIStroke", {
	Color = Color3.fromRGB(75, 78, 92),
	Thickness = 1
}, Main)

--==================================================
-- TITLE
--==================================================

local Title = New("TextLabel", {
	Size = UDim2.new(1, -115, 0, 42),
	Position = UDim2.fromOffset(14, 0),
	BackgroundTransparency = 1,
	Text = "TACTICAL  •  FPS",
	TextColor3 = Color3.new(1,1,1),
	TextSize = 15,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left
}, Main)

--==================================================
-- TOP BUTTONS
--==================================================

local function TopButton(text, x)
	local Button = New("TextButton", {
		Size = UDim2.fromOffset(30, 28),
		Position = UDim2.new(1, x, 0, 7),
		BackgroundColor3 = Color3.fromRGB(32, 34, 42),
		Text = text,
		TextColor3 = Color3.new(1,1,1),
		TextSize = 15,
		Font = Enum.Font.GothamBold
	}, Main)

	New("UICorner", {
		CornerRadius = UDim.new(0, 7)
	}, Button)

	return Button
end

local Minimize = TopButton("–", -100)
local Close = TopButton("×", -66)
local Remove = TopButton("□", -32)

--==================================================
-- CONTENT
--==================================================

local Content = New("Frame", {
	Size = UDim2.new(1, -20, 1, -54),
	Position = UDim2.fromOffset(10, 46),
	BackgroundTransparency = 1
}, Main)

local AimTab = New("TextButton", {
	Size = UDim2.fromOffset(125, 32),
	Position = UDim2.fromOffset(2, 0),
	BackgroundColor3 = Color3.fromRGB(45,48,60),
	Text = "🎯 AIM",
	TextColor3 = Color3.new(1,1,1),
	TextSize = 13,
	Font = Enum.Font.GothamBold
}, Content)

New("UICorner", {
	CornerRadius = UDim.new(0, 8)
}, AimTab)

local ESPTab = New("TextButton", {
	Size = UDim2.fromOffset(125, 32),
	Position = UDim2.fromOffset(135, 0),
	BackgroundColor3 = Color3.fromRGB(28,30,37),
	Text = "🌈 ESP",
	TextColor3 = Color3.new(1,1,1),
	TextSize = 13,
	Font = Enum.Font.GothamBold
}, Content)

New("UICorner", {
	CornerRadius = UDim.new(0, 8)
}, ESPTab)

local AimPage = New("Frame", {
	Size = UDim2.new(1,0,1,-40),
	Position = UDim2.fromOffset(0,40),
	BackgroundTransparency = 1
}, Content)

local ESPPage = New("Frame", {
	Size = UDim2.new(1,0,1,-40),
	Position = UDim2.fromOffset(0,40),
	BackgroundTransparency = 1,
	Visible = false
}, Content)

--==================================================
-- TOGGLE CREATOR
--==================================================

local function CreateToggle(parent, y, text, getter, setter)

	local Button = New("TextButton", {
		Size = UDim2.new(1,-4,0,38),
		Position = UDim2.fromOffset(2,y),
		BackgroundColor3 = Color3.fromRGB(29,31,39),
		Text = ""
	}, parent)

	New("UICorner", {
		CornerRadius = UDim.new(0,8)
	}, Button)

	New("TextLabel", {
		Size = UDim2.new(1,-65,1,0),
		Position = UDim2.fromOffset(12,0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.new(1,1,1),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Button)

	local State = New("TextLabel", {
		Size = UDim2.fromOffset(48,24),
		Position = UDim2.new(1,-56,0.5,-12),
		BackgroundColor3 = Color3.fromRGB(65,67,77),
		TextColor3 = Color3.new(1,1,1),
		TextSize = 10,
		Font = Enum.Font.GothamBold
	}, Button)

	New("UICorner", {
		CornerRadius = UDim.new(1,0)
	}, State)

	local function Refresh()
		if getter() then
			State.Text = "ON"
			State.BackgroundColor3 = Color3.fromRGB(65,150,100)
		else
			State.Text = "OFF"
			State.BackgroundColor3 = Color3.fromRGB(65,67,77)
		end
	end

	Refresh()

	Connect(Button.Activated:Connect(function()
		setter(not getter())
		Refresh()
	end))
end

--==================================================
-- AIM SETTINGS
--==================================================

CreateToggle(
	AimPage,
	2,
	"Aim Assist",
	function()
		return Config.Aim
	end,
	function(value)
		Config.Aim = value
	end
)

CreateToggle(
	AimPage,
	44,
	"Wall Check",
	function()
		return Config.WallCheck
	end,
	function(value)
		Config.WallCheck = value
	end
)

--==================================================
-- SLIDER
--==================================================

local function CreateSlider(parent, y, text, min, max, default, callback)

	local Holder = New("Frame", {
		Size = UDim2.new(1,-4,0,48),
		Position = UDim2.fromOffset(2,y),
		BackgroundTransparency = 1
	}, parent)

	New("TextLabel", {
		Size = UDim2.new(.7,0,0,20),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.new(1,1,1),
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Holder)

	local ValueLabel = New("TextLabel", {
		Size = UDim2.new(.3,0,0,20),
		Position = UDim2.new(.7,0,0,0),
		BackgroundTransparency = 1,
		Text = string.format("%.2f",default),
		TextColor3 = Color3.fromRGB(190,194,205),
		TextSize = 10,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right
	}, Holder)

	local Bar = New("Frame", {
		Size = UDim2.new(1,0,0,6),
		Position = UDim2.fromOffset(0,29),
		BackgroundColor3 = Color3.fromRGB(50,52,62),
		BorderSizePixel = 0
	}, Holder)

	New("UICorner", {
		CornerRadius = UDim.new(1,0)
	}, Bar)

	local Fill = New("Frame", {
		Size = UDim2.new((default-min)/(max-min),0,1,0),
		BackgroundColor3 = Color3.fromRGB(110,150,255),
		BorderSizePixel = 0
	}, Bar)

	New("UICorner", {
		CornerRadius = UDim.new(1,0)
	}, Fill)

	local Dragging = false

	local function Update(x)

		local percent = math.clamp(
			(x - Bar.AbsolutePosition.X) /
			Bar.AbsoluteSize.X,
			0,
			1
		)

		local value = min + (max-min) * percent

		callback(value)

		ValueLabel.Text = string.format("%.2f",value)

		Fill.Size = UDim2.new(percent,0,1,0)
	end

	Connect(Bar.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = true
			Update(input.Position.X)
		end
	end))

	Connect(UserInputService.InputChanged:Connect(function(input)

		if Dragging then

			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

				Update(input.Position.X)
			end
		end
	end))

	Connect(UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = false
		end
	end))
end

CreateSlider(
	AimPage,
	88,
	"FOV",
	60,
	400,
	Config.FOV,
	function(value)
		Config.FOV = value
	end
)

CreateSlider(
	AimPage,
	136,
	"Prediction",
	0,
	0.5,
	Config.Prediction,
	function(value)
		Config.Prediction = value
	end
)

New("TextLabel", {
	Size = UDim2.new(1,-4,0,28),
	Position = UDim2.fromOffset(2,188),
	BackgroundTransparency = 1,
	Text = "Targets the player nearest your crosshair.",
	TextColor3 = Color3.fromRGB(155,158,170),
	TextSize = 10,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, AimPage)

--==================================================
-- ESP
--==================================================

CreateToggle(
	ESPPage,
	2,
	"Rainbow Body ESP",
	function()
		return Config.ESP
	end,
	function(value)
		Config.ESP = value
	end
)

New("TextLabel", {
	Size = UDim2.new(1,-4,0,55),
	Position = UDim2.fromOffset(2,48),
	BackgroundTransparency = 1,
	Text = "Transparent hologram overlay.\nYour character remains visible underneath.",
	TextColor3 = Color3.fromRGB(155,158,170),
	TextSize = 10,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left
}, ESPPage)

--==================================================
-- FLOATING LOGO
--==================================================

local Logo = New("TextButton", {
	Name = "FloatingLogo",
	Size = UDim2.fromOffset(48,48),
	Position = UDim2.new(0,18,.5,-24),
	BackgroundColor3 = Color3.fromRGB(22,24,31),
	Text = "T",
	TextColor3 = Color3.new(1,1,1),
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	Visible = false
}, GUI)

New("UICorner", {
	CornerRadius = UDim.new(1,0)
}, Logo)

New("UIStroke", {
	Color = Color3.fromRGB(100,104,120),
	Thickness = 2
}, Logo)

--==================================================
-- DRAG SYSTEM
--==================================================

local function MakeDraggable(handle, object)

	local Dragging = false
	local StartInput
	local StartPosition

	Connect(handle.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = true
			StartInput = input.Position
			StartPosition = object.Position
		end
	end))

	Connect(UserInputService.InputChanged:Connect(function(input)

		if Dragging then

			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

				local Delta = input.Position - StartInput

				object.Position = UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset + Delta.X,
					StartPosition.Y.Scale,
					StartPosition.Y.Offset + Delta.Y
				)
			end
		end
	end))

	Connect(UserInputService.InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			Dragging = false
		end
	end))
end

MakeDraggable(Title,Main)
MakeDraggable(Logo,Logo)

--==================================================
-- TABS
--==================================================

Connect(AimTab.Activated:Connect(function()

	AimPage.Visible = true
	ESPPage.Visible = false

	AimTab.BackgroundColor3 = Color3.fromRGB(45,48,60)
	ESPTab.BackgroundColor3 = Color3.fromRGB(28,30,37)
end))

Connect(ESPTab.Activated:Connect(function()

	AimPage.Visible = false
	ESPPage.Visible = true

	AimTab.BackgroundColor3 = Color3.fromRGB(28,30,37)
	ESPTab.BackgroundColor3 = Color3.fromRGB(45,48,60)
end))

--==================================================
-- MINIMIZE
--==================================================

local Minimized = false

Connect(Minimize.Activated:Connect(function()

	Minimized = not Minimized

	Content.Visible = not Minimized

	if Minimized then
		Main.Size = UDim2.fromOffset(285,52)
	else
		Main.Size = UDim2.fromOffset(285,255)
	end
end))

--==================================================
-- CLOSE
--==================================================

Connect(Close.Activated:Connect(function()

	Main.Visible = false
	Logo.Visible = true
end))

--==================================================
-- REOPEN
--==================================================

Connect(Logo.Activated:Connect(function()

	if not Removed then
		Main.Visible = true
		Logo.Visible = false
	end
end))

--==================================================
-- REMOVE
--==================================================

Connect(Remove.Activated:Connect(function()

	Removed = true

	Config.Aim = false
	Config.ESP = false

	for _, highlight in pairs(Highlights) do
		if highlight then
			highlight:Destroy()
		end
	end

	table.clear(Highlights)

	for _, connection in ipairs(Connections) do
		connection:Disconnect()
	end

	GUI:Destroy()
end)

--==================================================
-- TARGET SYSTEM
--==================================================

local function IsAlive(character)

	local Humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return Humanoid and Humanoid.Health > 0
end

local function WallCheck(character, part)

	if not Config.WallCheck then
		return true
	end

	local Origin = Camera.CFrame.Position
	local Direction = part.Position - Origin

	local Params = RaycastParams.new()

	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {
		LP.Character
	}

	local Result = workspace:Raycast(
		Origin,
		Direction,
		Params
	)

	return Result
		and Result.Instance
		and Result.Instance:IsDescendantOf(character)
end

local function GetBestTarget()

	local BestPart
	local BestDistance = Config.FOV

	local Viewport = Camera.ViewportSize

	local Center = Vector2.new(
		Viewport.X/2,
		Viewport.Y/2
	)

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LP
		and Player.Character
		and IsAlive(Player.Character) then

			local Head =
				Player.Character:FindFirstChild("Head")

			local Root =
				Player.Character:FindFirstChild("HumanoidRootPart")

			local Part = Head or Root

			if Part then

				local ScreenPosition, OnScreen =
					Camera:WorldToViewportPoint(Part.Position)

				if OnScreen and ScreenPosition.Z > 0 then

					local Distance =
						(
							Vector2.new(
								ScreenPosition.X,
								ScreenPosition.Y
							) - Center
						).Magnitude

					if Distance < BestDistance
					and WallCheck(Player.Character,Part) then

						BestDistance = Distance
						BestPart = Part
					end
				end
			end
		end
	end

	return BestPart
end

--==================================================
-- AIM ASSIST
--==================================================

Connect(RunService.RenderStepped:Connect(function()

	if Removed or not Config.Aim then
		return
	end

	local Target = GetBestTarget()

	if Target then

		local Velocity =
			Target.AssemblyLinearVelocity

		local PredictedPosition =
			Target.Position +
			Velocity * Config.Prediction

		local Desired =
			CFrame.lookAt(
				Camera.CFrame.Position,
				PredictedPosition
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				Desired,
				0.18
			)
	end
end))

--==================================================
-- RAINBOW ESP
--==================================================

local function RemoveESP(Player)

	local Highlight = Highlights[Player]

	if Highlight then
		Highlight:Destroy()
		Highlights[Player] = nil
	end
end

local function UpdateESP()

	if Removed then
		return
	end

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LP
		and Player.Character
		and IsAlive(Player.Character)
		and Config.ESP then

			local Highlight = Highlights[Player]

			if not Highlight
			or Highlight.Parent ~= Player.Character then

				RemoveESP(Player)

				Highlight = Instance.new("Highlight")

				Highlight.Name = "RainbowBodyESP"

				-- Visible through walls
				Highlight.DepthMode =
					Enum.HighlightDepthMode.AlwaysOnTop

				Highlight.FillTransparency =
					Config.ESPTransparency

				Highlight.OutlineTransparency = 0.05

				Highlight.Parent =
					Player.Character

				Highlights[Player] = Highlight
			end

			local Hue =
				(os.clock() * Config.RainbowSpeed
				+ Player.UserId * 0.0001) % 1

			local Rainbow =
				Color3.fromHSV(
					Hue,
					1,
					1
				)

			Highlight.FillColor = Rainbow
			Highlight.OutlineColor = Rainbow

		else
			RemoveESP(Player)
		end
	end
end

Connect(RunService.RenderStepped:Connect(UpdateESP))

Connect(Players.PlayerRemoving:Connect(function(Player)
	RemoveESP(Player)
end))

print("🔥 Tactical FPS Panel loaded!")