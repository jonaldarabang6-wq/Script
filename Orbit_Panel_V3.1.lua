--[[
    🌌 ORBIT PANEL V3.1
    UI + Main Feature Framework
    Designed for use in your own Roblox experience.

    V3.1:
    • Left feature selector + right content panel
    • Players
    • Orbit: Speed / Radius / Start / Stop
    • Combat: Auto Punch
    • ESP + Health Display
    • Target Lock
    • Misc + Show Chat state
    • Settings / Information / Credits
    • Draggable, resizable, mobile/touch friendly
    • Minimize / Close / draggable 🌌 reopen button
    • No Orbit Presets / Roles / Nurse
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local State = {
    Feature = "Main", Orbit = false, OrbitTarget = nil, OrbitSpeed = 5, OrbitRadius = 8, OrbitAngle = 0,
    AutoPunch = false, PunchInterval = .25, ESP = false, HealthESP = false,
    TargetLock = false, LockedTarget = nil, ShowChat = false,
    Transparency = .08, Outline = true,
    Accent = Color3.fromRGB(150,90,255), OutlineColor = Color3.fromRGB(185,130,255)
}

local function New(class, props, parent)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end
local function Corner(x,r) New("UICorner",{CornerRadius=UDim.new(0,r or 8)},x) end
local function Stroke(x,c,t,tr) return New("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0},x) end
local function Tween(x,d,p) local t=TweenService:Create(x,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p);t:Play();return t end
local function Char(p) return p and p.Character end
local function Root(p) local c=Char(p);return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum(p) local c=Char(p);return c and c:FindFirstChildOfClass("Humanoid") end
local function Alive(p) local h=Hum(p);return h and h.Health>0 end
local function Dist(p) local a,b=Root(LocalPlayer),Root(p);return a and b and (a.Position-b.Position).Magnitude or math.huge end
local function Nearest()
    local best,bd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and Alive(p) then local d=Dist(p);if d<bd then best,bd=p,d end end end
    return best
end
local function EquippedTool()
    local c=Char(LocalPlayer);if not c then return end
    for _,v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return v end end
end

local Gui=New("ScreenGui",{Name="OrbitPanelV31",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PlayerGui)
local Main=New("Frame",{Name="MainWindow",Size=UDim2.fromOffset(760,470),Position=UDim2.new(.5,-380,.5,-235),BackgroundColor3=Color3.fromRGB(16,12,27),BackgroundTransparency=State.Transparency,BorderSizePixel=0,ClipsDescendants=true},Gui)
Corner(Main,14);local MainStroke=Stroke(Main,State.OutlineColor,1.5)
for i=1,80 do local s=math.random(1,3);local star=New("Frame",{Size=UDim2.fromOffset(s,s),Position=UDim2.new(math.random(),0,math.random(),0),BackgroundColor3=Color3.fromRGB(220,210,255),BackgroundTransparency=math.random(35,80)/100,BorderSizePixel=0,ZIndex=0},Main);Corner(star,s) end
local Top=New("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=Color3.fromRGB(25,19,40),BorderSizePixel=0,ZIndex=5},Main)
New("TextLabel",{Size=UDim2.new(1,-110,1,0),Position=UDim2.fromOffset(16,0),BackgroundTransparency=1,Text="🌌 ORBIT PANEL V3.1",TextColor3=Color3.fromRGB(245,240,255),TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},Top)
local Min=New("TextButton",{Size=UDim2.fromOffset(42,32),Position=UDim2.new(1,-92,0,8),BackgroundColor3=Color3.fromRGB(45,35,65),Text="—",TextColor3=Color3.new(1,1,1),TextSize=18,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=7},Top);Corner(Min,8)
local Close=New("TextButton",{Size=UDim2.fromOffset(42,32),Position=UDim2.new(1,-46,0,8),BackgroundColor3=Color3.fromRGB(65,35,65),Text="×",TextColor3=Color3.new(1,1,1),TextSize=20,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=7},Top);Corner(Close,8)
local Side=New("Frame",{Size=UDim2.new(0,190,1,-60),Position=UDim2.fromOffset(10,55),BackgroundColor3=Color3.fromRGB(22,17,36),BackgroundTransparency=.08,BorderSizePixel=0,ZIndex=3},Main);Corner(Side,10)
New("TextLabel",{Size=UDim2.new(1,-20,0,32),Position=UDim2.fromOffset(10,4),BackgroundTransparency=1,Text="FEATURES",TextColor3=State.Accent,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},Side)
local FeatureScroll=New("ScrollingFrame",{Size=UDim2.new(1,-10,1,-42),Position=UDim2.fromOffset(5,38),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=4},Side)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},FeatureScroll)
local Content=New("Frame",{Size=UDim2.new(1,-220,1,-70),Position=UDim2.fromOffset(210,58),BackgroundColor3=Color3.fromRGB(20,15,33),BackgroundTransparency=.08,BorderSizePixel=0,ZIndex=3},Main);Corner(Content,10)
local ContentTitle=New("TextLabel",{Size=UDim2.new(1,-30,0,45),Position=UDim2.fromOffset(15,8),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=22,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},Content)
local Scroll=New("ScrollingFrame",{Size=UDim2.new(1,-20,1,-65),Position=UDim2.fromOffset(10,58),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=4},Content)
New("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)
local function Clear() for _,v in ipairs(Scroll:GetChildren()) do if not v:IsA("UIListLayout") then v:Destroy() end end end
local function Label(text,h) return New("TextLabel",{Size=UDim2.new(1,-10,0,h or 38),BackgroundTransparency=1,Text=text,TextColor3=Color3.fromRGB(205,195,225),TextSize=13,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=5},Scroll) end
local function Button(text,fn) local b=New("TextButton",{Size=UDim2.new(1,-10,0,42),BackgroundColor3=Color3.fromRGB(38,29,58),BorderSizePixel=0,Text=text,TextColor3=Color3.fromRGB(240,235,250),TextSize=14,Font=Enum.Font.GothamBold,ZIndex=6},Scroll);Corner(b,9);Stroke(b,State.OutlineColor,1,.55);b.MouseButton1Click:Connect(fn);return b end
local function Toggle(text,on,fn) local b;local e=on;local function refresh() b.Text=text..(e and "  [ON]" or "  [OFF]") end;b=Button("",function() e=not e;refresh();fn(e) end);refresh();return b end
local function Number(value,fn) local b=New("TextBox",{Size=UDim2.new(1,-10,0,40),BackgroundColor3=Color3.fromRGB(31,24,47),BorderSizePixel=0,Text=tostring(value),TextColor3=Color3.new(1,1,1),TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=6},Scroll);Corner(b,8);b.FocusLost:Connect(function() local n=tonumber(b.Text);if n then fn(n) end end);return b end

-- ESP
local ESPObjects={}
local function RemoveESP(p) local d=ESPObjects[p];if d then if d.H then d.H:Destroy() end;if d.B then d.B:Destroy() end;ESPObjects[p]=nil end end
local function UpdateESP(p)
    if p==LocalPlayer then return end
    if not State.ESP and not State.HealthESP then RemoveESP(p);return end
    local c,r,h=Char(p),Root(p),Hum(p);if not c or not r or not h then return end
    local d=ESPObjects[p] or {}
    if State.ESP then
        if not d.H then d.H=New("Highlight",{Name="OrbitESP",FillTransparency=.82,OutlineTransparency=.15,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},c) end
        d.H.Adornee=c;d.H.FillColor=State.Accent;d.H.OutlineColor=State.OutlineColor
    elseif d.H then d.H:Destroy();d.H=nil end
    if State.HealthESP then
        if not d.B then d.B=New("BillboardGui",{Name="OrbitHealthESP",Size=UDim2.fromOffset(190,42),StudsOffset=Vector3.new(0,3.8,0),AlwaysOnTop=true,Adornee=r},r);d.T=New("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.35,TextSize=13,Font=Enum.Font.GothamBold,TextWrapped=true},d.B) end
        d.T.Text=string.format("❤️ %s\nHP: %d / %d",p.DisplayName,math.floor(h.Health+.5),math.floor(h.MaxHealth+.5))
    elseif d.B then d.B:Destroy();d.B=nil;d.T=nil end
    ESPObjects[p]=d
end
local function RefreshESP() for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then UpdateESP(p) end end end
Players.PlayerRemoving:Connect(RemoveESP)
Players.PlayerAdded:Connect(function(p)p.CharacterAdded:Connect(function()task.wait(.4);UpdateESP(p)end)end)

-- Feature rendering
local FeatureButtons={}
local Names={"📌 Main","👥 Players","🌀 Orbit","👊 Combat","👁️ ESP","🎯 Target Lock","🧰 Misc","⚙️ Settings","ℹ️ Information","💳 Credits"}
local Render
local function MainPage()
    ContentTitle.Text="📌 Main";Clear();Label("🌌 Orbit Panel V3.1\nSpace-themed testing/admin UI for your own Roblox experience.",55);Label("Current target: "..(State.OrbitTarget and State.OrbitTarget.DisplayName or "None"),35);Label("Select a category on the left to manage its controls.",42);Button("🎯 Select Nearest Player",function()State.OrbitTarget=Nearest();State.LockedTarget=State.OrbitTarget;MainPage()end);Button("🛑 Stop Orbit",function()State.Orbit=false end)
end
local function PlayersPage()
    ContentTitle.Text="👥 Players";Clear();Label("Choose a player. DisplayName and @Username are shown together.",45)
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then local q=p;Button(q.DisplayName.."  (@"..q.Name..")"..(q==State.OrbitTarget and "  ✓" or ""),function()State.OrbitTarget=q;State.LockedTarget=q;PlayersPage()end)end end
end
local function OrbitPage()
    ContentTitle.Text="🌀 Orbit";Clear();Label("Orbit around the selected player. Speed and Radius are direct controls.",45);Label("Orbit Speed",28);Number(State.OrbitSpeed,function(v)State.OrbitSpeed=math.clamp(v,.1,30)end);Label("Change how quickly you orbit around a player.",30);Label("Orbit Radius",28);Number(State.OrbitRadius,function(v)State.OrbitRadius=math.clamp(v,1,100)end);Label("Change how far away you orbit around a player.",30);Toggle("🌀 Orbit",State.Orbit,function(v)State.Orbit=v;if v and not State.OrbitTarget then State.OrbitTarget=Nearest()end end);Button("🎯 Select Nearest Target",function()State.OrbitTarget=Nearest();OrbitPage()end);Label("Target: "..(State.OrbitTarget and State.OrbitTarget.DisplayName or "None"),35);Label("Auto-stop: orbit stops when WalkSpeed reaches 22+.",42)
end
local function CombatPage()
    ContentTitle.Text="👊 Combat";Clear();Label("Combat controls for testing your own fighting-game mechanics.",45);Toggle("👊 Auto Punch",State.AutoPunch,function(v)State.AutoPunch=v end);Label("Attack interval",28);Number(State.PunchInterval,function(v)State.PunchInterval=math.clamp(v,.05,5)end);Label("Uses the Tool currently equipped by your character and checks a 15-stud nearest-player range.",50)
end
local function ESPPage()
    ContentTitle.Text="👁️ ESP";Clear();Label("Visual player information. Health display is separate from the regular highlight.",45);Toggle("👁️ Player ESP",State.ESP,function(v)State.ESP=v;RefreshESP()end);Label("Highlights other players.",28);Toggle("❤️ Show Health",State.HealthESP,function(v)State.HealthESP=v;RefreshESP()end);Label("Shows current HP / Max HP above players and updates as health changes.",45)
end
local function TargetPage()
    ContentTitle.Text="🎯 Target Lock";Clear();Label("Maintain a selected target for your own experience's targeting logic.",45);Toggle("🎯 Target Lock",State.TargetLock,function(v)State.TargetLock=v;if v and not State.LockedTarget then State.LockedTarget=State.OrbitTarget or Nearest()end end);Label("Target: "..(State.LockedTarget and State.LockedTarget.DisplayName or "None"),35);Button("🎯 Lock Nearest Player",function()State.LockedTarget=Nearest();TargetPage()end);Button("❌ Clear Target",function()State.LockedTarget=nil;TargetPage()end)
end
local function MiscPage()
    ContentTitle.Text="🧰 Misc";Clear();Label("Extra utilities and visual testing options.",40);Toggle("💬 Show Chat",State.ShowChat,function(v)State.ShowChat=v;pcall(function()StarterGui:SetCore("SendNotification",{Title="🌌 Orbit Panel",Text="Show Chat state: "..tostring(v)..". Chat visibility/filtering remains controlled by your experience.",Duration=3})end)end);Label("Chat visibility/filtering is controlled by the Roblox chat system and your experience; this toggle stores the panel's testing state.",55);Button("🔄 Rejoin",function()pcall(function()game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)end)end);Button("📋 Copy Job ID",function()if setclipboard then pcall(setclipboard,game.JobId)end end);Button("📋 Copy Game ID",function()if setclipboard then pcall(setclipboard,tostring(game.GameId))end end);Button("🔃 Refresh ESP",function()RefreshESP();MiscPage()end)
end
local function SettingsPage()
    ContentTitle.Text="⚙️ Settings";Clear();Label("Customize the UI live without reopening it.",42);Label("UI Transparency",28);Number(State.Transparency,function(v)State.Transparency=math.clamp(v,0,.8);Main.BackgroundTransparency=State.Transparency end);Label("0 = solid, 0.8 = very transparent.",30);Toggle("◈ Outline",State.Outline, function(v)State.Outline=v;MainStroke.Transparency=v and 0 or 1 end);Button("🌌 Reset UI Settings",function()State.Transparency=.08;State.Outline=true;Main.BackgroundTransparency=.08;MainStroke.Transparency=0;SettingsPage()end)
end
local function InfoPage()
    ContentTitle.Text="ℹ️ Information";Clear();Label("🌌 ORBIT PANEL V3.1",42);Label("Left-side feature navigation with a right-side content/settings panel.",48);Label("New V3.1 additions: Players, Combat organization, ESP Health Display, and Misc Show Chat state.",55);Label("Orbit Presets, Roles, and Nurse were removed from V3.1.",45)
end
local function CreditsPage()
    ContentTitle.Text="💳 Credits";Clear();Label("🌌 Orbit Panel V3.1",40);Label("Created & Developed by Franz 🔥",40);Label("UI Design\nDesigned by Franz",45);Label("Scripting & Development\nBuilt with Roblox Lua",48);Label("Special Thanks\nThanks to everyone who tested Orbit Panel and gave feedback 🤝",58);Label("Version\nOrbit Panel V3.1\nBuilt from an idea into reality.",60)
end
local Pages={Main=MainPage,Players=PlayersPage,Orbit=OrbitPage,Combat=CombatPage,ESP=ESPPage,Target=TargetPage,Misc=MiscPage,Settings=SettingsPage,Info=InfoPage,Credits=CreditsPage}
local Map={ ["📌 Main"]="Main",["👥 Players"]="Players",["🌀 Orbit"]="Orbit",["👊 Combat"]="Combat",["👁️ ESP"]="ESP",["🎯 Target Lock"]="Target",["🧰 Misc"]="Misc",["⚙️ Settings"]="Settings",["ℹ️ Information"]="Info",["💳 Credits"]="Credits" }
local function Select(name)
    State.Feature=name
    for n,b in pairs(FeatureButtons) do b.BackgroundColor3=(n==name and State.Accent or Color3.fromRGB(35,27,53)) end
    Pages[Map[name]]()
end
for i,name in ipairs(Names) do local b=New("TextButton",{Size=UDim2.new(1,-8,0,40),BackgroundColor3=Color3.fromRGB(35,27,53),BorderSizePixel=0,Text=name,TextColor3=Color3.fromRGB(235,230,245),TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=i,ZIndex=5},FeatureScroll);Corner(b,8);New("UIPadding",{PaddingLeft=UDim.new(0,10)},b);Stroke(b,State.OutlineColor,1,.65);b.MouseButton1Click:Connect(function()Select(name)end);FeatureButtons[name]=b end

-- Dragging
local function Draggable(handle,obj)
    local drag=false,start,pos
    handle.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;start=i.Position;pos=obj.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then drag=false end end)end end)
    UserInputService.InputChanged:Connect(function(i)if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-start;obj.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)end end)
end
Draggable(Top,Main)
local Resize=New("TextButton",{Size=UDim2.fromOffset(25,25),Position=UDim2.new(1,-27,1,-27),BackgroundTransparency=1,Text="↘",TextColor3=Color3.fromRGB(180,160,210),TextSize=16,ZIndex=20},Main)
local resizing=false,rstart,rsize
Resize.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then resizing=true;rstart=i.Position;rsize=Main.AbsoluteSize end end)
UserInputService.InputChanged:Connect(function(i)if resizing and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-rstart;Main.Size=UDim2.fromOffset(math.clamp(rsize.X+d.X,560,1000),math.clamp(rsize.Y+d.Y,360,720))end end)
UserInputService.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then resizing=false end end)

local Galaxy=New("TextButton",{Name="GalaxyReopen",Size=UDim2.fromOffset(58,58),Position=UDim2.new(0,25,.5,-29),BackgroundColor3=Color3.fromRGB(28,20,45),Text="🌌",TextSize=29,BorderSizePixel=0,Visible=false,ZIndex=100},Gui);Corner(Galaxy,29);Stroke(Galaxy,State.OutlineColor,1.5);Draggable(Galaxy,Galaxy)
Galaxy.MouseButton1Click:Connect(function()Galaxy.Visible=false;Main.Visible=true;Main.Size=UDim2.fromOffset(300,180);Tween(Main,.3,{Size=UDim2.fromOffset(760,470)})end)
Min.MouseButton1Click:Connect(function()Main.Visible=false;Galaxy.Visible=true end)
Close.MouseButton1Click:Connect(function()for p in pairs(ESPObjects) do RemoveESP(p) end;Gui:Destroy()end)

-- Orbit
RunService.RenderStepped:Connect(function(dt)
    local h=Hum(LocalPlayer)
    if h and h.WalkSpeed>=22 then State.Orbit=false end
    if State.Orbit then
        local t=State.OrbitTarget;if not t or not Alive(t) then t=Nearest();State.OrbitTarget=t end
        local tr,mr=Root(t),Root(LocalPlayer)
        if tr and mr then State.OrbitAngle+=State.OrbitSpeed*dt;local o=Vector3.new(math.cos(State.OrbitAngle)*State.OrbitRadius,0,math.sin(State.OrbitAngle)*State.OrbitRadius);mr.CFrame=CFrame.lookAt(tr.Position+o,tr.Position) end
    end
end)

-- Auto Punch: uses the equipped Tool in the user's own experience.
task.spawn(function()while Gui.Parent do if State.AutoPunch then local tool,target=EquippedTool(),Nearest();if tool and target and Dist(target)<=15 then pcall(function()tool:Activate()end)end;task.wait(State.PunchInterval)else task.wait(.1)end end end)
-- Health labels refresh.
task.spawn(function()while Gui.Parent do if State.ESP or State.HealthESP then RefreshESP() end;task.wait(.25)end end)

Main.Size=UDim2.fromOffset(300,180);Main.BackgroundTransparency=1;task.wait(.15);Tween(Main,.45,{Size=UDim2.fromOffset(760,470),BackgroundTransparency=State.Transparency});Select("📌 Main")
