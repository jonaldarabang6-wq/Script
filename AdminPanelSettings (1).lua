-- LocalScript inside StarterPlayerScripts
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====================================================================
-- CONFIGURATION PANEL (Tweak your settings here!)
-- ====================================================================
local Settings = {
	-- Aimbot Settings
	AimbotEnabled = true,
	AimbotKey = Enum.KeyCode.E,        -- Press 'E' to toggle aimbot lock
	AimbotRadius = 50,                 -- 1 to 100 (percentage of screen size)
	WallCheck = true,                  -- Set to false to lock onto players through walls
	TeamCheck = true,                  -- Set to false to target your own teammates
	
	-- ESP Settings
	EspEnabled = true,
	EspColor = Color3.fromRGB(255, 0, 0), -- Pure Red (Change to any RGB color)
	EspTransparency = 0.5,             -- 0 is fully solid, 1 is invisible
	OutlineTransparency = 0.1,          -- 0 is solid outline, 1 is invisible outline
}

-- Global toggle states
local isAiming = false
local espFolders = {}

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

-- Check if a target is visible (not blocked by parts/walls)
local function isPlayerVisible(targetCharacter, targetPart)
	if not Settings.WallCheck then return true end
	
	local origin = Camera.CFrame.Position
	local destination = targetPart.Position
	local direction = destination - origin
	
	local raycastParams = RaycastParams.new()
	-- Ignore yourself and the target character while checking for obstructions
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = Workspace:Raycast(origin, direction, raycastParams)
	
	-- If result is nil, nothing blocked the ray path
	return result == nil
end

-- Get the closest enemy player to the center of your screen
local function getClosestPlayerToCenter()
	local closestPlayer = nil
	local shortestDistance = math.huge
	
	-- Calculate the allowed radius in screen pixels
	local viewportSize = Camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	-- Max radius is half the smallest screen dimension, scaled by the radius percentage
	local maxRadiusPixels = (math.min(viewportSize.X, viewportSize.Y) / 2) * (Settings.AimbotRadius / 100)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			-- Team Check logic
			local isEnemy = not Settings.TeamCheck or (player.Team ~= LocalPlayer.Team)
			
			if isEnemy and player.Character and player.Character:FindFirstChild("Head") then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				
				if humanoid and humanoid.Health > 0 then
					local head = player.Character.Head
					
					-- Project the 3D head position onto your 2D screen
					local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
					
					if onScreen then
						local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
						local distanceToCenter = (playerScreenPos - screenCenter).Magnitude
						
						-- Verify they are inside the FOV circle and closest to center
						if distanceToCenter < shortestDistance and distanceToCenter <= maxRadiusPixels then
							if isPlayerVisible(player.Character, head) then
								shortestDistance = distanceToCenter
								closestPlayer = head
							end
						end
					end
				end
			end
		end
	end
	
	return closestPlayer
end

-- ====================================================================
-- ESP SYSTEM (Uses Roblox native Highlights)
-- ====================================================================
local function applyESP(player)
	if player == LocalPlayer then return end
	
	local function onCharacterAdded(character)
		if not Settings.EspEnabled then return end
		
		-- Avoid creating multiple highlights on the same character
		local existingHighlight = character:FindFirstChild("AdminPanelESP")
		if existingHighlight then existingHighlight:Destroy() end
		
		local highlight = Instance.new("Highlight")
		highlight.Name = "AdminPanelESP"
		highlight.FillColor = Settings.EspColor
		highlight.FillTransparency = Settings.EspTransparency
		highlight.OutlineTransparency = Settings.OutlineTransparency
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- See through walls!
		highlight.Parent = character
	end
	
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Monitor joining and existing players for ESP activation
Players.PlayerAdded:Connect(applyESP)
for _, player in ipairs(Players:GetPlayers()) do
	applyESP(player)
end

-- Clean up ESP highlights if the feature is dynamically turned off
local function updateESPVisibility()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local highlight = player.Character:FindFirstChild("AdminPanelESP")
			if highlight then
				if Settings.EspEnabled then
					highlight.FillColor = Settings.EspColor
					highlight.FillTransparency = Settings.EspTransparency
				else
					highlight.FillTransparency = 1
					highlight.OutlineTransparency = 1
				end
			elseif Settings.EspEnabled then
				applyESP(player)
			end
		end
	end
end

-- ====================================================================
-- CORE RUN LOOPS
-- ====================================================================

-- Handle keyboard toggles
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore when user is typing in chat
	
	if input.KeyCode == Settings.AimbotKey then
		isAiming = not isAiming
		print("Aimbot state changed: " .. tostring(isAiming))
	end
end)

-- Frame-locked camera loop (Zero delay setup)
RunService.RenderStepped:Connect(function()
	if not isAiming or not Settings.AimbotEnabled then return end
	
	local targetHead = getClosestPlayerToCenter()
	if targetHead then
		-- Instantly snap the camera rotation to look at the target's head
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
	end
end)