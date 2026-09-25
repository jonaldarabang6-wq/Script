--[[
 DOMINATOR FINAL - SINGLE LUA FILE
 For a Roblox experience you control.
 Place as a LocalScript in StarterPlayerScripts.

 Features:
 - Silent-aim-style target selection and prediction
 - Murderer/role ESP
 - Auto-gun pickup for your own game's prompts/click detectors
 - Speed controller
 - Debug hitbox expander
 - Mobile + mouse input
 - Draggable/minimizable UI
 - Per-target velocity tracking
 - Optimized update intervals
 - Respawn handling and cleanup

 IMPORTANT: this is for YOUR OWN EXPERIENCE. It does not hook another
 game's remotes. For authoritative multiplayer damage, your own server
 weapon code should validate shots.
]]

local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer
local PlayerGui=LocalPlayer:WaitForChild("PlayerGui")

local C={
 Silent={Enabled=true,Range=180,FOV=90,Prediction=.12,MaxPrediction=.30,FireDelay=.25,Part="HumanoidRootPart",TeamCheck=true},
 ESP={Enabled=true,Interval=.4,Distance=500},
 Gun={Enabled=false,Range=200,Interval=.5},
 Speed={Enabled=false,Value=32},
 Hitbox={Enabled=false,Multiplier=2,MaxSize=12,Transparency=.65},
}
local S={Char=nil,Hum=nil,Root=nil,Target=nil,Murderer=nil,LastFire=0,LastESP=0,LastGun=0,LastHitbox=0,Velocity={},Original={},ESP={},Connections={}}
local function con(x,f)local c=x:Connect(f);table.insert(S.Connections,c);return c end
local function root(ch)return ch and ch:FindFirstChild("HumanoidRootPart")end
local function alive(ch)local h=ch and ch:FindFirstChildOfClass("Humanoid");return h and h.Health>0 end
local function enemy(p)
 if p==LocalPlayer then return false end
 if not C.Silent.TeamCheck then return true end
 return not(LocalPlayer.Team and p.Team and LocalPlayer.Team==p.Team)
end
local function setChar(ch)S.Char=ch;S.Hum=ch and ch:FindFirstChildOfClass("Humanoid");S.Root=root(ch);S.Target=nil;S.Velocity={}end

-- ROLE / MURDERER DETECTION
local function isMurderer(ch)
 if not ch then return false end
 if ch:GetAttribute("Role")=="Murderer" or ch:GetAttribute("IsMurderer")==true then return true end
 for _,o in ipairs(ch:GetChildren()) do
  if o:IsA("Tool") then local n=o.Name:lower();if n:find("knife") or n:find("blade") or n:find("murder") then return true end end
 end
 return false
end
local function findMurderer()
 for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and alive(p.Character) and isMurderer(p.Character) then S.Murderer=p;return p end end
 S.Murderer=nil;return nil
end

-- PER-TARGET PREDICTION
local function velocity(p,r)
 local h=S.Velocity[p]
 if not h then h={v={}};S.Velocity[p]=h end
 table.insert(h.v,r.AssemblyLinearVelocity)
 if #h.v>4 then table.remove(h.v,1) end
 local sum=Vector3.zero
 for _,v in ipairs(h.v) do sum+=v end
 return sum/#h.v
end
local function predicted(p)
 local ch=p and p.Character;local r=ch and ch:FindFirstChild(C.Silent.Part) or root(ch)
 if not r then return nil end
 local t=math.clamp(C.Silent.Prediction,0,C.Silent.MaxPrediction)
 return r.Position+velocity(p,r)*t
end

-- TARGET ENGINE
local function bestTarget()
 local cam=Workspace.CurrentCamera;if not cam or not alive(S.Char) or not S.Root then return nil end
 local best,score=nil,math.huge
 local center=cam.ViewportSize/2
 local maxFov=math.tan(math.rad(C.Silent.FOV/2))*cam.ViewportSize.Y
 for _,p in ipairs(Players:GetPlayers()) do
  if enemy(p) and alive(p.Character) then
   local r=root(p.Character);if r then
    local d=(r.Position-S.Root.Position).Magnitude
    if d<=C.Silent.Range then
     local pt,on=cam:WorldToViewportPoint(r.Position)
     if on and pt.Z>0 then
      local off=Vector2.new(pt.X,pt.Y)-center
      if off.Magnitude<=maxFov then
       local sc=off.Magnitude+d*.15
       if sc<score then score=sc;best=p end
      end
     end
    end
   end
  end
 end
 return best
end

-- OWN-GAME SHOT REQUEST HOOK
local function requestShot()
 if not C.Silent.Enabled then return end
 local now=os.clock();if now-S.LastFire<C.Silent.FireDelay then return end
 S.LastFire=now;local p=bestTarget();if not p then return end
 S.Target=p;local pos=predicted(p);if not pos then return end
 -- Your own weapon can listen to this BindableEvent.
 local ev=Workspace:FindFirstChild("DominatorShotRequest")
 if ev and ev:IsA("BindableEvent") then ev:Fire(p.Character,pos) end
end

-- ESP
local function removeESP(p)
 local d=S.ESP[p];if not d then return end
 if d.h then d.h:Destroy() end;if d.b then d.b:Destroy() end;S.ESP[p]=nil
end
local function updateESP()
 if not C.ESP.Enabled then for p in pairs(S.ESP) do removeESP(p) end return end
 findMurderer()
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LocalPlayer and alive(p.Character) then
   local r=root(p.Character);local d=S.ESP[p]
   if r and not d then
    d={};d.h=Instance.new("Highlight");d.h.Name="DominatorESP";d.h.FillTransparency=.72;d.h.OutlineTransparency=0;d.h.Adornee=p.Character;d.h.Parent=p.Character
    d.b=Instance.new("BillboardGui");d.b.Size=UDim2.fromOffset(190,42);d.b.StudsOffset=Vector3.new(0,3.5,0);d.b.AlwaysOnTop=true;d.b.Adornee=r;d.b.Parent=r
    d.l=Instance.new("TextLabel");d.l.Size=UDim2.fromScale(1,1);d.l.BackgroundTransparency=1;d.l.TextScaled=true;d.l.Font=Enum.Font.GothamBold;d.l.TextStrokeTransparency=0;d.l.Parent=d.b
    S.ESP[p]=d
   end
   d=S.ESP[p]
   if d and r then
    local murderer=p==S.Murderer;d.h.Enabled=murderer;d.h.FillColor=Color3.fromRGB(255,60,60);d.h.OutlineColor=Color3.fromRGB(255,0,0);d.b.Enabled=murderer
    if murderer then local dist=(r.Position-S.Root.Position).Magnitude;d.l.Text="MURDERER: "..p.DisplayName.." ["..math.floor(dist).."m]" end
   end
  else removeESP(p) end
 end
end

-- AUTO GUN PICKUP (OWN-GAME INTERACTION)
local function gun(t)
 if not t:IsA("Tool") then return false end
 local n=t.Name:lower();return n:find("gun") or n:find("pistol") or n:find("revolver")
end
local function gunPos(t)local h=t:FindFirstChild("Handle");return h and h:IsA("BasePart") and h.Position end
local function autoGun()
 if not C.Gun.Enabled or not S.Root then return end
 local closest,dist=nil,C.Gun.Range
 for _,o in ipairs(Workspace:GetDescendants()) do
  if o:IsA("Tool") and gun(o) then local pos=gunPos(o);if pos then local d=(pos-S.Root.Position).Magnitude;if d<dist then dist=d;closest=o end end end
 end
 if closest then
  local prompt=closest:FindFirstChildWhichIsA("ProximityPrompt",true)
  if prompt and prompt.Enabled then pcall(function() prompt:InputHoldBegin();task.wait(math.min(prompt.HoldDuration,.25));prompt:InputHoldEnd() end) end
 end
end

-- SPEED
local function speed()if S.Hum and C.Speed.Enabled then S.Hum.WalkSpeed=C.Speed.Value end end

-- HITBOX DEBUGGING
local function restore(part)
 local o=S.Original[part];if not o then return end
 if part and part.Parent then part.Size=o.Size;part.Transparency=o.Transparency;part.CanCollide=o.CanCollide;part.CanTouch=o.CanTouch;part.CanQuery=o.CanQuery end
 S.Original[part]=nil
end
local function hitboxes()
 if not C.Hitbox.Enabled then for p in pairs(S.Original) do restore(p) end return end
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LocalPlayer and enemy(p) and alive(p.Character) then
   local r=root(p.Character)
   if r then
    if not S.Original[r] then S.Original[r]={Size=r.Size,Transparency=r.Transparency,CanCollide=r.CanCollide,CanTouch=r.CanTouch,CanQuery=r.CanQuery} end
    local z=S.Original[r].Size*C.Hitbox.Multiplier
    r.Size=Vector3.new(math.min(z.X,C.Hitbox.MaxSize),math.min(z.Y,C.Hitbox.MaxSize),math.min(z.Z,C.Hitbox.MaxSize));r.Transparency=C.Hitbox.Transparency;r.CanCollide=false
   end
  end
 end
end

-- UI
local gui=Instance.new("ScreenGui");gui.Name="DominatorUI";gui.ResetOnSpawn=false;gui.Parent=PlayerGui
local main=Instance.new("Frame");main.Size=UDim2.fromOffset(370,330);main.Position=UDim2.fromScale(.5,.5);main.AnchorPoint=Vector2.new(.5,.5);main.BackgroundColor3=Color3.fromRGB(18,18,23);main.BorderSizePixel=0;main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-90,0,45);title.Position=UDim2.fromOffset(15,3);title.BackgroundTransparency=1;title.Text="DOMINATOR";title.TextSize=21;title.Font=Enum.Font.GothamBlack;title.TextXAlignment=Enum.TextXAlignment.Left;title.TextColor3=Color3.new(1,1,1);title.Parent=main
local sub=Instance.new("TextLabel");sub.Size=UDim2.new(1,-30,0,20);sub.Position=UDim2.fromOffset(15,40);sub.BackgroundTransparency=1;sub.Text="FINAL CONTROL PANEL";sub.TextSize=10;sub.Font=Enum.Font.GothamBold;sub.TextXAlignment=Enum.TextXAlignment.Left;sub.TextColor3=Color3.fromRGB(150,150,160);sub.Parent=main
local min=Instance.new("TextButton");min.Size=UDim2.fromOffset(30,28);min.Position=UDim2.new(1,-78,0,10);min.Text="—";min.Parent=main
local close=Instance.new("TextButton");close.Size=UDim2.fromOffset(30,28);close.Position=UDim2.new(1,-42,0,10);close.Text="×";close.Parent=main
for _,b in ipairs({min,close}) do b.BackgroundColor3=Color3.fromRGB(30,30,38);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;Instance.new("UICorner",b).CornerRadius=UDim.new(0,7) end
local content=Instance.new("Frame");content.Size=UDim2.new(1,-28,1,-78);content.Position=UDim2.fromOffset(14,70);content.BackgroundTransparency=1;content.Parent=main
local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,7);list.Parent=content
local function toggle(name,get,set)
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,39);b.BackgroundColor3=Color3.fromRGB(28,28,36);b.BorderSizePixel=0;b.Font=Enum.Font.GothamBold;b.TextSize=13;b.TextXAlignment=Enum.TextXAlignment.Left;b.Parent=content;Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
 local function refresh()local on=get();b.Text="   "..name.."   ["..(on and "ON" or "OFF").."]";b.TextColor3=on and Color3.fromRGB(120,255,150) or Color3.fromRGB(180,180,190)end
 con(b.Activated,function()set(not get());refresh()end);refresh()
end
toggle("Silent Aim",function()return C.Silent.Enabled end,function(v)C.Silent.Enabled=v end)
toggle("Murderer ESP",function()return C.ESP.Enabled end,function(v)C.ESP.Enabled=v end)
toggle("Auto Get Gun",function()return C.Gun.Enabled end,function(v)C.Gun.Enabled=v end)
toggle("Speed",function()return C.Speed.Enabled end,function(v)C.Speed.Enabled=v end)
toggle("Hitbox Expander",function()return C.Hitbox.Enabled end,function(v)C.Hitbox.Enabled=v end)
local float=Instance.new("TextButton");float.Size=UDim2.fromOffset(54,54);float.Position=UDim2.fromScale(.08,.5);float.Text="D";float.TextSize=22;float.Font=Enum.Font.GothamBlack;float.TextColor3=Color3.new(1,1,1);float.BackgroundColor3=Color3.fromRGB(25,25,32);float.Visible=false;float.Parent=gui;Instance.new("UICorner",float).CornerRadius=UDim.new(1,0)
local function drag(handle,target)
 local moving=false;local start;local pos
 con(handle.InputBegan,function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then moving=true;start=i.Position;pos=target.Position end end)
 con(UIS.InputChanged,function(i)if moving and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-start;target.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y) end end)
 con(UIS.InputEnded,function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then moving=false end end)
end
drag(main,main);drag(float,float)
con(min.Activated,function()main.Visible=false;float.Visible=true end)
con(close.Activated,function()main.Visible=false;float.Visible=true end)
con(float.Activated,function()main.Visible=true;float.Visible=false end)

-- INPUT
con(UIS.InputBegan,function(i,processed)
 if processed then return end
 if i.UserInputType==Enum.UserInputType.MouseButton1 then requestShot() end
 if i.KeyCode==Enum.KeyCode.F then main.Visible=not main.Visible;float.Visible=not main.Visible end
end)

-- LIFECYCLE
con(LocalPlayer.CharacterAdded,function(ch)setChar(ch);task.defer(function()S.Hum=ch:WaitForChild("Humanoid",5);S.Root=ch:WaitForChild("HumanoidRootPart",5)end)end)
if LocalPlayer.Character then setChar(LocalPlayer.Character) end
con(Players.PlayerRemoving,function(p)S.Velocity[p]=nil;removeESP(p)end)

-- OPTIMIZED LOOP
local acc=0
con(RunService.Heartbeat,function(dt)
 acc+=dt;if acc<.05 then return end;acc=0
 if C.Silent.Enabled then S.Target=bestTarget() else S.Target=nil end
 if os.clock()-S.LastESP>=C.ESP.Interval then S.LastESP=os.clock();updateESP() end
 if os.clock()-S.LastGun>=C.Gun.Interval then S.LastGun=os.clock();autoGun() end
 if os.clock()-S.LastHitbox>=.5 then S.LastHitbox=os.clock();hitboxes() end
 speed()
end)

-- CLEANUP
con(script.Destroying,function()
 for _,c in ipairs(S.Connections) do pcall(function()c:Disconnect()end) end
 for p in pairs(S.ESP) do removeESP(p) end
 for part in pairs(S.Original) do restore(part) end
 if gui then gui:Destroy() end
end)

print("[DOMINATOR FINAL] Loaded - all assigned features initialized.")
