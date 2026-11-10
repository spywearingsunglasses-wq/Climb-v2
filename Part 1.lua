-- FE R15 SMART 4-LIMB CLIMB (PART 1 OF 3)
local P, W, U = game:GetService("Players"), game:GetService("Workspace"), game:GetService("UserInputService")
local L = P.LocalPlayer
local char = L.Character or L.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

assert(hum.RigType == Enum.HumanoidRigType.R15, "R15 Avatar Required!")

for _, v in pairs(L:WaitForChild("Backpack"):GetChildren()) do
	if v.Name == "🧗 Dual-Hand Climb" then v:Destroy() end
end
for _, v in pairs(char:GetChildren()) do
	if v.Name == "🧗 Dual-Hand Climb" then v:Destroy() end
end
if L.PlayerGui:FindFirstChild("DHClimbUI") then L.PlayerGui.DHClimbUI:Destroy() end
if W:FindFirstChild("ClimbPads4") then W.ClimbPads4:Destroy() end

local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
local function loadTrack(id, prio, loop)
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. tostring(id)
	local t = animator:LoadAnimation(a)
	t.Priority = prio or Enum.AnimationPriority.Action
	if loop ~= nil then t.Looped = loop end
	return t
end

-- Only load Eerie Walk & Vault (no silly flailing climb loops!)
local tracks = {
	eerie = loadTrack(616163682, Enum.AnimationPriority.Movement, true),
	vault = loadTrack(656117878, Enum.AnimationPriority.Action4, false)
}

local padFolder = Instance.new("Folder", W)
padFolder.Name = "ClimbPads4"
local function makePad(name, sz)
	local p = Instance.new("Part", padFolder)
	p.Name, p.Shape, p.Size = name, Enum.PartType.Ball, Vector3.new(sz, sz, sz)
	p.Material, p.Color, p.Transparency = Enum.Material.Neon, Color3.fromRGB(185, 190, 205), 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	return p
end

local upperTorso = char:WaitForChild("UpperTorso")
local lowerTorso = char:WaitForChild("LowerTorso")
getgenv().DHC = {
	equipped = false, autoVault = true, airGrab = false, vaulting = false,
	manualShift = false, lockedOnWall = false, twitchMode = false, banging = false,
	stickInput = Vector2.zero, stickActive = false,
	anchorPos = Vector3.zero, anchorNorm = Vector3.zAxis, anchorPart = nil,
	localAnchorPos = Vector3.zero, localAnchorNorm = Vector3.zAxis,
	char = char, hum = hum, root = root, upperTorso = upperTorso, lowerTorso = lowerTorso,
	waist = upperTorso:WaitForChild("Waist"), neck = char:WaitForChild("Head"):WaitForChild("Neck"),
	lShoulder = char:WaitForChild("LeftUpperArm"):WaitForChild("LeftShoulder"),
	lElbow = char:WaitForChild("LeftLowerArm"):WaitForChild("LeftElbow"),
	rShoulder = char:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder"),
	rElbow = char:WaitForChild("RightLowerArm"):WaitForChild("RightElbow"),
	lHip = char:WaitForChild("LeftUpperLeg"):WaitForChild("LeftHip"),
	lKnee = char:WaitForChild("LeftLowerLeg"):WaitForChild("LeftKnee"),
	rHip = char:WaitForChild("RightUpperLeg"):WaitForChild("RightHip"),
	rKnee = char:WaitForChild("RightLowerLeg"):WaitForChild("RightKnee"),
	tracks = tracks, padFolder = padFolder,
	pads = {
		hL = {part = makePad("HandL", 0.34), pos = Vector3.zero, side = -1, isFoot = false},
		hR = {part = makePad("HandR", 0.34), pos = Vector3.zero, side = 1, isFoot = false},
		fL = {part = makePad("FootL", 0.30), pos = Vector3.zero, side = -1, isFoot = true},
		fR = {part = makePad("FootR", 0.30), pos = Vector3.zero, side = 1, isFoot = true}
	}
}
local S = getgenv().DHC

local ui = Instance.new("ScreenGui", L:WaitForChild("PlayerGui"))
ui.Name, ui.ResetOnSpawn, ui.Enabled = "DHClimbUI", false, false
S.ui = ui

local darkGray, borderGray = Color3.fromRGB(20, 20, 24), Color3.fromRGB(145, 145, 155)
local pill = Instance.new("TextLabel", ui)
pill.Size, pill.Position = UDim2.new(0, 280, 0, 24), UDim2.new(0.5, -140, 0, 6)
pill.BackgroundColor3, pill.BackgroundTransparency = darkGray, 0.35
pill.TextColor3, pill.Font, pill.TextSize = Color3.fromRGB(220, 220, 230), Enum.Font.GothamBold, 11
pill.Text = "🕷️ SMART CLIMB: READY"
Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
local ps = Instance.new("UIStroke", pill)
ps.Color, ps.Thickness, ps.Transparency = borderGray, 1.2, 0.3
S.statusLbl = pill

local function topBtn(pos, sz, tx)
	local b = Instance.new("TextButton", ui)
	b.Size, b.Position = sz, pos
	b.BackgroundColor3, b.BackgroundTransparency = darkGray, 0.35
	b.TextColor3, b.Font, b.TextSize, b.Text = Color3.fromRGB(230, 230, 235), Enum.Font.GothamBold, 10, tx
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
	local s = Instance.new("UIStroke", b)
	s.Color, s.Thickness, s.Transparency = borderGray, 1.2, 0.3
	return b
end

S.shiftBtn  = topBtn(UDim2.new(0.5, -195, 0, 34), UDim2.new(0, 92, 0, 26), "🔒 SHIFT: AUTO")
S.vaultBtn  = topBtn(UDim2.new(0.5, -97, 0, 34), UDim2.new(0, 92, 0, 26), "⚡ VAULT: ON")
S.airBtn    = topBtn(UDim2.new(0.5, 1, 0, 34), UDim2.new(0, 92, 0, 26), "🪂 AIR GRAB")
S.leapBtn   = topBtn(UDim2.new(0.5, 99, 0, 34), UDim2.new(0, 96, 0, 26), "🚀 WALL LEAP")
S.twitchBtn = topBtn(UDim2.new(0.5, -102, 0, 64), UDim2.new(0, 98, 0, 26), "👁️ TWITCH: OFF")
S.bangBtn   = topBtn(UDim2.new(0.5, 4, 0, 64), UDim2.new(0, 98, 0, 26), "💀 BANG HEAD")

S.shiftBtn.MouseButton1Click:Connect(function() S.manualShift = not S.manualShift S.shiftBtn.Text = S.manualShift and "🔒 SHIFT: ON" or "🔒 SHIFT: AUTO" end)
S.vaultBtn.MouseButton1Click:Connect(function() S.autoVault = not S.autoVault S.vaultBtn.Text = S.autoVault and "⚡ VAULT: ON" or "⚡ VAULT: OFF" end)
S.twitchBtn.MouseButton1Click:Connect(function() S.twitchMode = not S.twitchMode S.twitchBtn.Text = S.twitchMode and "👁️ TWITCH: ON" or "👁️ TWITCH: OFF" end)

local stickBase = Instance.new("Frame", ui)
stickBase.Size, stickBase.Position = UDim2.new(0, 134, 0, 134), UDim2.new(0, 35, 1, -210)
stickBase.BackgroundColor3, stickBase.BackgroundTransparency = darkGray, 0.38
stickBase.Active, stickBase.Visible = true, false
Instance.new("UICorner", stickBase).CornerRadius = UDim.new(1, 0)
local bs = Instance.new("UIStroke", stickBase)
bs.Color, bs.Thickness, bs.Transparency = borderGray, 2, 0.25
S.touchZone = stickBase

local stickKnob = Instance.new("Frame", stickBase)
stickKnob.Size, stickKnob.Position = UDim2.new(0, 54, 0, 54), UDim2.new(0.5, -27, 0.5, -27)
stickKnob.BackgroundColor3, stickKnob.BackgroundTransparency = Color3.fromRGB(205, 210, 220), 0.2
Instance.new("UICorner", stickKnob).CornerRadius = UDim.new(1, 0)

local activeTouch = nil
local function resetStick()
	activeTouch, S.stickActive, S.stickInput = nil, false, Vector2.zero
	stickKnob.Position, bs.Color = UDim2.new(0.5, -27, 0.5, -27), borderGray
end
S.hideStick = resetStick

local function updateStick(pos)
	local center = stickBase.AbsolutePosition + (stickBase.AbsoluteSize * 0.5)
	local delta = Vector2.new(pos.X, pos.Y) - center
	local rad = stickBase.AbsoluteSize.X * 0.5
	local clamped = delta.Magnitude > rad and delta.Unit * rad or delta
	stickKnob.Position = UDim2.new(0.5, clamped.X - 27, 0.5, clamped.Y - 27)
	S.stickInput, S.stickActive, bs.Color = Vector2.new(clamped.X / rad, -clamped.Y / rad), true, Color3.fromRGB(60, 235, 110)
end

stickBase.InputBegan:Connect(function(inp)
	if S.equipped and stickBase.Visible and not activeTouch and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1) then
		activeTouch = inp updateStick(inp.Position)
	end
end)
U.InputChanged:Connect(function(inp) if inp == activeTouch then updateStick(inp.Position) end end)
U.InputEnded:Connect(function(inp) if inp == activeTouch then resetStick() end end)

S.setDefaultThumbstick = function(en)
	pcall(function()
		local tg = L.PlayerGui:FindFirstChild("TouchGui")
		if tg and tg:FindFirstChild("TouchControlFrame") then
			for _, f in ipairs(tg.TouchControlFrame:GetChildren()) do
				if f.Name:find("Thumbstick") then f.Visible = en end
			end
		end
	end)
end

S.fullReset = function()
	resetStick()
	S.anchorPart, S.lockedOnWall = nil, false
	for _, pad in pairs(S.pads) do pad.part.Transparency = 1 end
	root.Anchored, hum.PlatformStand = false, false
	local animScript = char:FindFirstChild("Animate")
	if animScript then animScript.Disabled = false end
	for _, j in ipairs({S.waist, S.neck, S.lShoulder, S.lElbow, S.rShoulder, S.rElbow, S.lHip, S.rHip, S.lKnee, S.rKnee}) do
		j.Transform = CFrame.identity
	end
	S.setDefaultThumbstick(true)
end

local tool = Instance.new("Tool")
tool.Name, tool.RequiresHandle, tool.CanBeDropped = "🧗 Dual-Hand Climb", false, false
tool.Parent = L:WaitForChild("Backpack")
S.tool = tool

tool.Equipped:Connect(function() S.equipped, ui.Enabled = true, true end)
tool.Unequipped:Connect(function()
	S.equipped, S.airGrab, S.manualShift, S.twitchMode = false, false, false, false
	ui.Enabled, stickBase.Visible = false, false
	S.airBtn.Text, S.shiftBtn.Text, S.twitchBtn.Text = "🪂 AIR GRAB", "🔒 SHIFT: AUTO", "👁️ TWITCH: OFF"
	S.fullReset()
	hum.AutoRotate, hum.CameraOffset = true, Vector3.zero
	tracks.eerie:Stop(0.15)
end)
print("Part 1 Loaded! Run Part 2A next.")
