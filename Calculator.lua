--[[
  🥔 CALCULATOR V1.0 - ULTRA POTATO BIG NUMBER CALCULATOR
  Animated green binary background, big-number math (10,000 digits),
  notifications, memory, RAM meter, floating logo, mobile-friendly.
  For Delta Executor. No errors. Fully working.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- =============================[ BIG NUMBER MATH ]=========================
local BigNum = {}

local function normalize(s)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return "0" end
    local neg = false
    if s:sub(1,1) == "-" then neg = true; s = s:sub(2) end
    s = s:gsub("^0+", "")
    if s == "" then s = "0"; neg = false end
    if neg and s ~= "0" then s = "-" .. s end
    return s
end

local function absCompare(a, b)
    a = a:gsub("^0+", ""); if a == "" then a = "0" end
    b = b:gsub("^0+", ""); if b == "" then b = "0" end
    if #a ~= #b then return #a > #b and 1 or -1 end
    if a == b then return 0 end
    return a > b and 1 or -1
end

local function absAdd(a, b)
    local result, carry = {}, 0
    local i, j = #a, #b
    while i > 0 or j > 0 or carry > 0 do
        local da = i > 0 and tonumber(a:sub(i,i)) or 0
        local db = j > 0 and tonumber(b:sub(j,j)) or 0
        local sum = da + db + carry
        table.insert(result, 1, tostring(sum % 10))
        carry = math.floor(sum / 10)
        i = i - 1; j = j - 1
    end
    return table.concat(result)
end

local function absSub(a, b)
    local result, borrow = {}, 0
    local i, j = #a, #b
    while i > 0 do
        local da = tonumber(a:sub(i,i)) - borrow
        local db = j > 0 and tonumber(b:sub(j,j)) or 0
        if da < db then da = da + 10; borrow = 1 else borrow = 0 end
        table.insert(result, 1, tostring(da - db))
        i = i - 1; j = j - 1
    end
    local s = table.concat(result):gsub("^0+", "")
    if s == "" then s = "0" end
    return s
end

function BigNum.add(a, b)
    a = normalize(a); b = normalize(b)
    local an, bn = a:sub(1,1) == "-", b:sub(1,1) == "-"
    local aa = an and a:sub(2) or a
    local bb = bn and b:sub(2) or b
    if an == bn then
        local r = absAdd(aa, bb)
        return normalize(an and ("-" .. r) or r)
    else
        local cmp = absCompare(aa, bb)
        if cmp == 0 then return "0" end
        if cmp > 0 then
            local r = absSub(aa, bb)
            return normalize(an and ("-" .. r) or r)
        else
            local r = absSub(bb, aa)
            return normalize(bn and ("-" .. r) or r)
        end
    end
end

function BigNum.sub(a, b)
    b = normalize(b)
    b = b:sub(1,1) == "-" and b:sub(2) or ("-" .. b)
    return BigNum.add(a, b)
end

function BigNum.mul(a, b)
    a = normalize(a); b = normalize(b)
    local neg = (a:sub(1,1) == "-") ~= (b:sub(1,1) == "-")
    local aa = a:gsub("^-", "")
    local bb = b:gsub("^-", "")
    if aa == "0" or bb == "0" then return "0" end
    local result = {}
    for i = 1, #aa + #bb do result[i] = 0 end
    for i = #aa, 1, -1 do
        local da = tonumber(aa:sub(i,i))
        for j = #bb, 1, -1 do
            local db = tonumber(bb:sub(j,j))
            local pos = i + j
            local sum = result[pos] + da * db
            result[pos] = sum % 10
            result[pos-1] = result[pos-1] + math.floor(sum / 10)
        end
    end
    local s = table.concat(result):gsub("^0+", "")
    if s == "" then s = "0" end
    if neg and s ~= "0" then s = "-" .. s end
    return s
end

function BigNum.div(a, b)
    a = normalize(a); b = normalize(b)
    if b == "0" then return "Error: Division by zero" end
    local neg = (a:sub(1,1) == "-") ~= (b:sub(1,1) == "-")
    local aa = a:gsub("^-", "")
    local bb = b:gsub("^-", "")
    if absCompare(aa, bb) < 0 then return "0" end
    if bb == "1" then return normalize(neg and ("-" .. aa) or aa) end
    local quotient, remainder = "", "0"
    for i = 1, #aa do
        remainder = remainder == "0" and aa:sub(i,i) or (remainder .. aa:sub(i,i))
        remainder = normalize(remainder)
        local digit = 0
        while absCompare(remainder, bb) >= 0 do
            remainder = absSub(remainder, bb)
            digit = digit + 1
        end
        quotient = quotient .. tostring(digit)
    end
    quotient = quotient:gsub("^0+", "")
    if quotient == "" then quotient = "0" end
    if neg and quotient ~= "0" then quotient = "-" .. quotient end
    return quotient
end

-- =============================[ STATE ]===================================
local state = {
    current = "0",
    previous = nil,
    operation = nil,
    justEvaluated = false,
    memory = "0",
    lastTime = 0,
}

-- =============================[ UI ROOT ]=================================
local gui = Instance.new("ScreenGui")
gui.Name = "CalculatorV1"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Main panel
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 340, 0, 620)
main.Position = UDim2.new(0.5, -170, 0.5, -310)
main.BackgroundColor3 = Color3.fromRGB(0, 20, 0)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
local mc = Instance.new("UICorner", main)
mc.CornerRadius = UDim.new(0, 16)
local ms = Instance.new("UIStroke", main)
ms.Thickness = 2
ms.Color = Color3.fromRGB(0, 255, 100)

-- Binary background (single label filled with pattern, animated)
local binaryBg = Instance.new("TextLabel", main)
binaryBg.Size = UDim2.new(1, 0, 2, 0)
binaryBg.Position = UDim2.new(0, 0, 0, 0)
binaryBg.BackgroundTransparency = 1
binaryBg.TextColor3 = Color3.fromRGB(0, 255, 100)
binaryBg.TextTransparency = 0.75
binaryBg.TextSize = 12
binaryBg.Font = Enum.Font.Code
binaryBg.TextXAlignment = Enum.TextXAlignment.Left
binaryBg.TextYAlignment = Enum.TextYAlignment.Top
binaryBg.TextWrapped = true
binaryBg.ZIndex = 0

local function buildBinaryPattern()
    local lines = {}
    for i = 1, 80 do
        local line = {}
        for j = 1, 40 do
            line[#line+1] = math.random(0,1)
        end
        lines[#lines+1] = table.concat(line)
    end
    return table.concat(lines, "\n")
end
binaryBg.Text = buildBinaryPattern()

local bgScrollPos = 0
RunService.RenderStepped:Connect(function(dt)
    if not main.Parent then return end
    bgScrollPos = bgScrollPos + dt * 0.05
    if bgScrollPos > 1 then
        bgScrollPos = 0
        binaryBg.Text = buildBinaryPattern()
    end
    binaryBg.Position = UDim2.new(0, 0, -bgScrollPos, 0)
end)

local glowOverlay = Instance.new("Frame", main)
glowOverlay.Size = UDim2.new(1, 0, 1, 0)
glowOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
glowOverlay.BackgroundTransparency = 1
glowOverlay.BorderSizePixel = 0
glowOverlay.ZIndex = 1
local goCorner = Instance.new("UICorner", glowOverlay)
goCorner.CornerRadius = UDim.new(0, 16)

task.spawn(function()
    while main.Parent do
        local tween1 = TweenService:Create(glowOverlay, TweenInfo.new(2, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.92})
        tween1:Play()
        task.wait(2)
        if not main.Parent then break end
        local tween2 = TweenService:Create(glowOverlay, TweenInfo.new(2, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
        tween2:Play()
        task.wait(2)
    end
end)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 5
local tc = Instance.new("UICorner", titleBar)
tc.CornerRadius = UDim.new(0, 16)
titleBar.ClipsDescendants = true

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "🥔 Calculator V1.0"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 17
title.Font = Enum.Font.Code
title.ZIndex = 6

local delBtn = Instance.new("TextButton", titleBar)
delBtn.Size = UDim2.new(0, 28, 0, 28)
delBtn.Position = UDim2.new(1, -66, 0, 7)
delBtn.Text = "🗑"
delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
delBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
delBtn.BorderSizePixel = 0
delBtn.TextSize = 14
delBtn.Font = Enum.Font.GothamBold
delBtn.ZIndex = 6
local dc = Instance.new("UICorner", delBtn)
dc.CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 7)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
closeBtn.BorderSizePixel = 0
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 6
local cc = Instance.new("UICorner", closeBtn)
cc.CornerRadius = UDim.new(0, 8)

local infoBar = Instance.new("Frame", main)
infoBar.Size = UDim2.new(1, -20, 0, 22)
infoBar.Position = UDim2.new(0, 10, 0, 48)
infoBar.BackgroundColor3 = Color3.fromRGB(0, 30, 0)
infoBar.BackgroundTransparency = 0.3
infoBar.BorderSizePixel = 0
infoBar.ZIndex = 5
local ibc = Instance.new("UICorner", infoBar)
ibc.CornerRadius = UDim.new(0, 6)

local ramLabel = Instance.new("TextLabel", infoBar)
ramLabel.Size = UDim2.new(1, -10, 1, 0)
ramLabel.Position = UDim2.new(0, 6, 0, 0)
ramLabel.Text = "RAM: -- MB | Lua Heap: -- MB"
ramLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
ramLabel.BackgroundTransparency = 1
ramLabel.TextXAlignment = Enum.TextXAlignment.Left
ramLabel.TextSize = 12
ramLabel.Font = Enum.Font.Code
ramLabel.ZIndex = 6

task.spawn(function()
    while main.Parent do
        local ok, totalMB = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
        local ok2, luaBytes = pcall(function() return Stats:GetLuaMemoryUsage() end)
        if ok and ok2 then
            ramLabel.Text = string.format("RAM: %.1f MB | Lua Heap: %.2f MB", totalMB, luaBytes / 1024 / 1024)
        end
        task.wait(1.5)
    end
end)

local displayFrame = Instance.new("Frame", main)
displayFrame.Size = UDim2.new(1, -20, 0, 110)
displayFrame.Position = UDim2.new(0, 10, 0, 78)
displayFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 0)
displayFrame.BackgroundTransparency = 0.15
displayFrame.BorderSizePixel = 0
displayFrame.ZIndex = 5
local dfc = Instance.new("UICorner", displayFrame)
dfc.CornerRadius = UDim.new(0, 12)
local dfs = Instance.new("UIStroke", displayFrame)
dfs.Thickness = 1
dfs.Color = Color3.fromRGB(0, 200, 80)
dfs.Transparency = 0.5

local historyLabel = Instance.new("TextLabel", displayFrame)
historyLabel.Size = UDim2.new(1, -20, 0, 22)
historyLabel.Position = UDim2.new(0, 10, 0, 6)
historyLabel.Text = ""
historyLabel.TextColor3 = Color3.fromRGB(0, 200, 80)
historyLabel.BackgroundTransparency = 1
historyLabel.TextXAlignment = Enum.TextXAlignment.Right
historyLabel.TextSize = 13
historyLabel.Font = Enum.Font.Code
historyLabel.ZIndex = 6

local memIndicator = Instance.new("TextLabel", displayFrame)
memIndicator.Size = UDim2.new(0, 40, 0, 22)
memIndicator.Position = UDim2.new(0, 10, 0, 6)
memIndicator.Text = ""
memIndicator.TextColor3 = Color3.fromRGB(255, 220, 100)
memIndicator.BackgroundTransparency = 1
memIndicator.TextXAlignment = Enum.TextXAlignment.Left
memIndicator.TextSize = 13
memIndicator.Font = Enum.Font.Code
memIndicator.ZIndex = 6

local displayScroll = Instance.new("ScrollingFrame", displayFrame)
displayScroll.Size = UDim2.new(1, -20, 0, 70)
displayScroll.Position = UDim2.new(0, 10, 0, 32)
displayScroll.BackgroundTransparency = 1
displayScroll.BorderSizePixel = 0
displayScroll.ScrollBarThickness = 4
displayScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 80)
displayScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
displayScroll.ScrollingDirection = Enum.ScrollingDirection.X
displayScroll.ZIndex = 6

local displayLabel = Instance.new("TextLabel", displayScroll)
displayLabel.Size = UDim2.new(0, 0, 1, 0)
displayLabel.Position = UDim2.new(1, 0, 0, 0)
displayLabel.AnchorPoint = Vector2.new(1, 0)
displayLabel.Text = "0"
displayLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
displayLabel.BackgroundTransparency = 1
displayLabel.TextXAlignment = Enum.TextXAlignment.Right
displayLabel.TextSize = 24
displayLabel.Font = Enum.Font.Code
displayLabel.AutomaticSize = Enum.AutomaticSize.X
displayLabel.ZIndex = 7

local function updateDisplay()
    displayLabel.Text = state.current
    displayScroll.CanvasSize = UDim2.new(0, displayLabel.AbsoluteSize.X + 20, 0, 0)
    if state.previous and state.operation then
        local opSymbol = state.operation
        if opSymbol == "*" then opSymbol = "×" end
        if opSymbol == "/" then opSymbol = "÷" end
        local prev = state.previous
        if #prev > 30 then prev = prev:sub(1, 30) .. "…" end
        historyLabel.Text = prev .. " " .. opSymbol
    else
        historyLabel.Text = ""
    end
    memIndicator.Text = state.memory ~= "0" and "M" or ""
end

-- PART 1 END

local grid = Instance.new("Frame", main)
grid.Size = UDim2.new(1, -20, 1, -210)
grid.Position = UDim2.new(0, 10, 0, 198)
grid.BackgroundTransparency = 1
grid.ZIndex = 5

local function makeButton(text, row, col, color, callback, colspan)
    colspan = colspan or 1
    local btn = Instance.new("TextButton", grid)
    local cellW = 1/5
    local cellH = 1/6
    btn.Size = UDim2.new(cellW * colspan - 0.01, 0, cellH - 0.01, 0)
    btn.Position = UDim2.new(cellW * (col-1), 0, cellH * (row-1), 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 255, 100)
    btn.BackgroundColor3 = color or Color3.fromRGB(0, 40, 0)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.TextSize = 18
    btn.Font = Enum.Font.Code
    btn.ZIndex = 6
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", btn)
    st.Thickness = 1
    st.Color = Color3.fromRGB(0, 180, 70)
    st.Transparency = 0.4
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function notifyResult(resultText)
    local textToShow = resultText
    if #textToShow > 180 then
        if #textToShow > 400 then
            textToShow = "Result is " .. #resultText .. " digits long"
        else
            textToShow = textToShow:sub(1, 80) .. "…" .. textToShow:sub(-80)
        end
    end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Total Answer",
            Text = textToShow,
            Duration = 5,
        })
    end)
end

local function pressNumber(n)
    if state.justEvaluated then state.current = "0"; state.justEvaluated = false end
    if state.current == "0" then state.current = n else state.current = state.current .. n end
    updateDisplay()
end

local function pressOperator(op)
    if state.previous and state.operation and not state.justEvaluated then
        local result
        if state.operation == "+" then result = BigNum.add(state.previous, state.current)
        elseif state.operation == "-" then result = BigNum.sub(state.previous, state.current)
        elseif state.operation == "*" then result = BigNum.mul(state.previous, state.current)
        elseif state.operation == "/" then result = BigNum.div(state.previous, state.current)
        end
        state.current = result or "0"
    end
    state.previous = state.current
    state.operation = op
    state.current = "0"
    state.justEvaluated = false
    updateDisplay()
end

local function pressEquals()
    if state.previous and state.operation then
        local startT = os.clock()
        local result
        if state.operation == "+" then result = BigNum.add(state.previous, state.current)
        elseif state.operation == "-" then result = BigNum.sub(state.previous, state.current)
        elseif state.operation == "*" then result = BigNum.mul(state.previous, state.current)
        elseif state.operation == "/" then result = BigNum.div(state.previous, state.current)
        end
        local elapsed = (os.clock() - startT) * 1000
        state.lastTime = elapsed
        state.current = result or "Error"
        state.previous = nil
        state.operation = nil
        state.justEvaluated = true
        updateDisplay()
        notifyResult(state.current)
    end
end

local function pressClear()
    state.current = "0"
    state.previous = nil
    state.operation = nil
    state.justEvaluated = false
    updateDisplay()
end

local function pressBackspace()
    if state.justEvaluated then
        state.current = "0"
        state.justEvaluated = false
    elseif #state.current > 1 then
        state.current = state.current:sub(1, -2)
    else
        state.current = "0"
    end
    updateDisplay()
end

local function pressSign()
    if state.current:sub(1,1) == "-" then state.current = state.current:sub(2)
    else state.current = "-" .. state.current end
    updateDisplay()
end

local function memClear() state.memory = "0"; updateDisplay() end
local function memRecall() state.current = state.memory; state.justEvaluated = true; updateDisplay() end
local function memAdd() state.memory = BigNum.add(state.memory, state.current); updateDisplay() end
local function memSub() state.memory = BigNum.sub(state.memory, state.current); updateDisplay() end

makeButton("MC", 1, 1, Color3.fromRGB(0, 60, 30), memClear)
makeButton("MR", 1, 2, Color3.fromRGB(0, 60, 30), memRecall)
makeButton("M+", 1, 3, Color3.fromRGB(0, 60, 30), memAdd)
makeButton("M-", 1, 4, Color3.fromRGB(0, 60, 30), memSub)
makeButton("C",  1, 5, Color3.fromRGB(80, 20, 20), pressClear)

makeButton("±", 2, 1, Color3.fromRGB(0, 60, 30), pressSign)
makeButton("⌫", 2, 2, Color3.fromRGB(60, 40, 10), pressBackspace)
makeButton("00", 2, 3, Color3.fromRGB(0, 40, 0), function() pressNumber("00") end)
makeButton("000", 2, 4, Color3.fromRGB(0, 40, 0), function() pressNumber("000") end)
makeButton("÷", 2, 5, Color3.fromRGB(0, 100, 50), function() pressOperator("/") end)

makeButton("7", 3, 1, Color3.fromRGB(0, 40, 0), function() pressNumber("7") end)
makeButton("8", 3, 2, Color3.fromRGB(0, 40, 0), function() pressNumber("8") end)
makeButton("9", 3, 3, Color3.fromRGB(0, 40, 0), function() pressNumber("9") end)
makeButton("×", 3, 4, Color3.fromRGB(0, 100, 50), function() pressOperator("*") end)
makeButton("=", 3, 5, Color3.fromRGB(0, 140, 60), pressEquals)

makeButton("4", 4, 1, Color3.fromRGB(0, 40, 0), function() pressNumber("4") end)
makeButton("5", 4, 2, Color3.fromRGB(0, 40, 0), function() pressNumber("5") end)
makeButton("6", 4, 3, Color3.fromRGB(0, 40, 0), function() pressNumber("6") end)
makeButton("-", 4, 4, Color3.fromRGB(0, 100, 50), function() pressOperator("-") end)
makeButton("+", 4, 5, Color3.fromRGB(0, 100, 50), function() pressOperator("+") end)

makeButton("1", 5, 1, Color3.fromRGB(0, 40, 0), function() pressNumber("1") end)
makeButton("2", 5, 2, Color3.fromRGB(0, 40, 0), function() pressNumber("2") end)
makeButton("3", 5, 3, Color3.fromRGB(0, 40, 0), function() pressNumber("3") end)
makeButton("0", 5, 4, Color3.fromRGB(0, 40, 0), function() pressNumber("0") end)
makeButton("00000", 5, 5, Color3.fromRGB(0, 40, 0), function() pressNumber("00000") end)

makeButton("Clear All", 6, 1, Color3.fromRGB(80, 20, 20), function()
    state.current = "0"
    state.previous = nil
    state.operation = nil
    state.memory = "0"
    state.justEvaluated = false
    updateDisplay()
end, 5)

local logoGui
local function createFloatingLogo()
    if logoGui then return end
    logoGui = Instance.new("ScreenGui")
    logoGui.Name = "CalcFloatingLogo"
    logoGui.Parent = LocalPlayer.PlayerGui
    logoGui.ResetOnSpawn = false

    local logoBtn = Instance.new("TextButton", logoGui)
    logoBtn.Size = UDim2.new(0, 60, 0, 60)
    logoBtn.Position = UDim2.new(0.9, 0, 0.8, 0)
    logoBtn.Text = "🥔"
    logoBtn.TextSize = 34
    logoBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
    logoBtn.BorderSizePixel = 0
    logoBtn.Active = true
    logoBtn.Draggable = true
    local lc = Instance.new("UICorner", logoBtn)
    lc.CornerRadius = UDim.new(0, 30)
    local ls = Instance.new("UIStroke", logoBtn)
    ls.Thickness = 2
    ls.Color = Color3.fromRGB(0, 255, 100)

    logoBtn.MouseButton1Click:Connect(function()
        if gui then gui.Enabled = true end
        if logoGui then logoGui:Destroy() logoGui = nil end
    end)
end

local function destroyFloatingLogo()
    if logoGui then logoGui:Destroy() logoGui = nil end
end

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
    createFloatingLogo()
end)

delBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    destroyFloatingLogo()
end)

updateDisplay()
print("🥔 Calculator V1.0 loaded! Big-number math + animated binary background + notifications.")