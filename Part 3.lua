-- FE R15 SMART 4-LIMB CLIMB (PART 2B OF 3)
local S = getgenv().DHC
assert(S and S.smartMoveAnchor, "Run Part 1 and Part 2A first!")

local R, W, Debris = game:GetService("RunService"), game:GetService("Workspace"), game:GetService("Debris")
local cam, char, hum, root = W.CurrentCamera, S.char, S.hum, S.root
local uTorso, lTorso = S.upperTorso, S.lowerTorso
local tracks, rp = S.tracks, S.rp
local phase, nextTwitch, twitchEnd, twitchVec, bangOff = 0, tick() + 2, 0, Vector3.zero, 0

S.bangBtn.MouseButton1Click:Connect(function()
	if not S.equipped or not S.lockedOnWall or S.banging or S.vaulting then return end
	S.banging, S.statusLbl.Text = true, "💀 SLAMMING HEAD ON WALL..."
	task.spawn(function()
		for i = 1, 3 do
			if not S.lockedOnWall or hum.Health <= 0 then break end
			for f = 1, 8 do
				R.Heartbeat:Wait()
				bangOff = -0.45 * (f / 8)
				S.waist.Transform, S.neck.Transform = CFrame.Angles(math.rad(-38), 0, 0), CFrame.Angles(math.rad(40), 0, 0)
			end
			local thud = Instance.new("Sound", root)
			thud.SoundId, thud.Volume = "rbxassetid://152206206", 1.4
			thud:Play() Debris:AddItem(thud, 2)
			for f = 1, 5 do
				R.Heartbeat:Wait()
				bangOff = 0.35 * (f / 5)
				S.waist.Transform, S.neck.Transform = CFrame.Angles(math.rad(14), 0, 0), CFrame.Angles(math.rad(-25), 0, 0)
			end
			task.wait(0.12)
		end
		bangOff = 0 S.banging = false
	end)
end)

-- Natural Human 2-Bone Limb IK (Hands & Feet touch exact surface points without stretching)
local function solveLimbIK(isFoot, side, targetPos)
	if not isFoot then
		local sh = (side == -1) and S.lShoulder or S.rShoulder
		local el = (side == -1) and S.lElbow or S.rElbow
		local sock = (uTorso.CFrame * sh.C0).Position
		local toT = targetPos - sock
		local dist = math.clamp(toT.Magnitude, 0.35, 2.55)
		local lDir = uTorso.CFrame:VectorToObjectSpace(toT.Unit)
		local bend = math.clamp((2.6 - dist) * 52, 24, 118)
		sh.Transform = sh.Transform:Lerp(CFrame.Angles(math.asin(math.clamp(lDir.Y, -1, 1)) + math.rad(92 - bend * 0.35), math.atan2(-lDir.X, -lDir.Z), math.rad(side * 14)), 0.38)
		el.Transform = el.Transform:Lerp(CFrame.Angles(math.rad(bend), 0, 0), 0.38)
	else
		local hip = (side == -1) and S.lHip or S.rHip
		local knee = (side == -1) and S.lKnee or S.rKnee
		local sock = (lTorso.CFrame * hip.C0).Position
		local toT = targetPos - sock
		local dist = math.clamp(toT.Magnitude, 0.45, 2.75)
		local lDir = lTorso.CFrame:VectorToObjectSpace(toT.Unit)
		local bend = math.clamp((2.8 - dist) * 48, 32, 115)
		hip.Transform = hip.Transform:Lerp(CFrame.Angles(math.asin(math.clamp(lDir.Y, -1, 1)) + math.rad(90 + bend * 0.48), math.atan2(-lDir.X, -lDir.Z), math.rad(side * 9)), 0.38)
		knee.Transform = knee.Transform:Lerp(CFrame.Angles(math.rad(-bend), 0, 0), 0.38)
	end
end

local conn
conn = R.Heartbeat:Connect(function(dt)
	if hum.Health <= 0 then
		root.Anchored = false S.setDefaultThumbstick(true)
		if S.padFolder then S.padFolder:Destroy() end
		conn:Disconnect() return
	end
	if not S.equipped or S.vaulting then return end

	if S.anchorPart and S.anchorPart.Parent then
		S.anchorPos = S.anchorPart.CFrame:PointToWorldSpace(S.localAnchorPos)
		S.anchorNorm = S.anchorPart.CFrame:VectorToWorldSpace(S.localAnchorNorm).Unit
	elseif S.anchorPart then
		S.fullReset()
	end

	local holding = (S.anchorPart ~= nil)
	local wallHit = W:Raycast(root.Position, root.CFrame.LookVector * 3.8, rp) or W:Raycast(root.Position + Vector3.new(0, 1.5, 0), root.CFrame.LookVector * 3.8, rp) or W:Raycast(root.Position, Vector3.yAxis * 4.5, rp)
	local roofDrop = (hum.FloorMaterial ~= Enum.Material.Air) and not W:Raycast(root.Position + root.CFrame.LookVector * 2.8, Vector3.new(0, -6.5, 0), rp)
	local show = (wallHit ~= nil) or roofDrop or S.airGrab or holding or S.stickActive

	S.touchZone.Visible = show
	if show then S.setDefaultThumbstick(false) else S.setDefaultThumbstick(true) if S.stickActive then S.hideStick() end end

	if (S.manualShift or show) and not holding then
		hum.AutoRotate, hum.CameraOffset = false, hum.CameraOffset:Lerp(Vector3.new(1.5, 0.2, 0), 0.25)
		local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if look.Magnitude > 0.01 then root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, root.Position + look), 0.4) end
	elseif not holding then
		hum.AutoRotate, hum.CameraOffset = true, hum.CameraOffset:Lerp(Vector3.zero, 0.25)
	end

	if not holding and hum.FloorMaterial ~= Enum.Material.Air and hum.MoveDirection.Magnitude > 0.05 then
		if not tracks.eerie.IsPlaying then tracks.eerie:Play(0.2, 1, 1.1) end
	elseif tracks.eerie.IsPlaying then tracks.eerie:Stop(0.15) end

	if not holding then
		if roofDrop and S.stickActive and S.stickInput.Y < -0.35 then
			local bw = W:Raycast(root.Position + root.CFrame.LookVector * 2.4 - Vector3.new(0, 2.5, 0), -root.CFrame.LookVector * 4.2, rp)
			if bw and bw.Instance.CanCollide and bw.Instance.Transparency < 0.85 then S.setAnchor(bw) holding = true end
		elseif wallHit and wallHit.Instance.CanCollide and wallHit.Instance.Transparency < 0.85 and ((S.stickActive and S.stickInput.Magnitude > 0.15) or S.airGrab) then
			S.setAnchor(wallHit) holding = true
			if S.airGrab then S.airGrab, S.airBtn.Text = false, "🪂 AIR GRAB" end
		end
	end

	local moveMag = S.stickActive and S.stickInput.Magnitude or 0
	local moving = moveMag > 0.1
	local onPole = holding and S.isPole(S.anchorPart)

	if not S.banging then
		S.statusLbl.Text = not show and "🕷️ WALK TO WALL, POLE OR ROOF" or (holding and "🦎 SMART SURFACE LOCKED" or "🎯 PUSH LEFT STICK TO LATCH")
	end

	if holding then
		-- Disable default Animate script while on wall so NO silly built-in animations interfere!
		local animScript = char:FindFirstChild("Animate")
		if animScript and not animScript.Disabled then animScript.Disabled = true end
		for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
			if tr ~= tracks.vault then tr:Stop(0.1) end
		end

		S.lockedOnWall, root.Anchored, hum.PlatformStand = true, true, true
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero

		-- Slow, realistic joystick-driven step cadence
		if moving then
			S.smartMoveAnchor(S.stickInput.X, S.stickInput.Y, dt)
			phase += dt * (moveMag * 6.8)
		end

		local norm = S.anchorNorm
		local wR = Vector3.yAxis:Cross(norm)
		wR = (wR.Magnitude < 0.1 and root.CFrame.RightVector or wR).Unit
		local wU = norm:Cross(wR).Unit

		-- Smart Anatomical Pad Placement (Keeps hands & feet realistically spaced on the outer wall)
		local reachX = moving and (S.stickInput.X * 0.25) or 0
		local reachY = moving and (S.stickInput.Y * 0.3) or 0
		local padOffsets = {
			hL = (wR * (-0.72 + reachX)) + (wU * (1.05 + reachY + (moving and math.sin(phase) * 0.45 or 0))),
			hR = (wR * (0.72 + reachX)) + (wU * (1.05 + reachY + (moving and -math.sin(phase) * 0.45 or 0))),
			fL = (wR * (-0.58 + reachX * 0.7)) + (wU * (-1.45 + reachY * 0.7 + (moving and -math.sin(phase) * 0.42 or 0))),
			fR = (wR * (0.58 + reachX * 0.7)) + (wU * (-1.45 + reachY * 0.7 + (moving and math.sin(phase) * 0.42 or 0)))
		}

		for k, off in pairs(padOffsets) do
			local pad = S.pads[k]
			local snap = W:Raycast(S.anchorPos + off + norm * 0.5, -norm * 0.9, S.rp)
			local targetP = (snap and snap.Instance.CanCollide and snap.Instance.Transparency < 0.85) and snap.Position or (S.anchorPos + off)
			pad.part.Position, pad.part.Transparency = targetP, 0.55
			pad.part.Color = pad.isFoot and Color3.fromRGB(140, 195, 255) or Color3.fromRGB(60, 235, 110)
			solveLimbIK(pad.isFoot, pad.side, targetP)
		end

		-- Subtle Natural Hunch + Random Twitch
		local now = tick()
		if S.twitchMode and not S.banging and now >= nextTwitch then
			twitchEnd, nextTwitch = now + 0.14, now + 1.8 + math.random() * 2.8
			twitchVec = Vector3.new(math.rad(math.random(-15, 15)), math.rad(math.random(-35, 35)), math.rad(math.random(-25, 25)))
		end
		local tw = (now < twitchEnd) and twitchVec or Vector3.zero
		if not S.banging then
			local hipSway = moving and (math.sin(phase) * 0.1) or 0
			S.waist.Transform = S.waist.Transform:Lerp(CFrame.Angles(math.rad(-16) + tw.X * 0.4, hipSway, hipSway * 0.5 + tw.Z * 0.4), 0.3)
			S.neck.Transform = S.neck.Transform:Lerp(CFrame.Angles(math.rad(24) + tw.X, -hipSway + tw.Y, tw.Z), 0.4)
		end

		if S.autoVault and not onPole and S.stickInput.Y > 0.75 then
			local ch = W:Raycast(root.Position + Vector3.new(0, 1.5, 0), root.CFrame.LookVector * 3.8, rp)
			if ch and not W:Raycast(root.Position + Vector3.new(0, 3.6, 0), root.CFrame.LookVector * 4, rp) then
				local top = W:Raycast(ch.Position + root.CFrame.LookVector * 0.6 + Vector3.new(0, 3, 0), Vector3.new(0, -4, 0), rp)
				if top then S.vault(top.Position) return end
			end
		end

		-- Solid Outer-Wall Hull Enforcement (1.35 studs outside wall = NEVER clips inside rooms!)
		local isCeil = norm.Y < -0.6
		local look = isCeil and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(-norm.X, 0, -norm.Z)
		look = look.Magnitude > 0.01 and look.Unit or root.CFrame.LookVector
		local dist = (isCeil and 2.15 or (onPole and 1.25 or 1.35)) - bangOff
		local safe = isCeil and (S.anchorPos - Vector3.new(0, dist, 0)) or (S.anchorPos + norm * dist - Vector3.new(0, 0.25, 0))

		local flr = W:Raycast(safe + Vector3.new(0, 1.5, 0), Vector3.new(0, -5, 0), rp)
		if flr and flr.Instance.CanCollide and safe.Y < flr.Position.Y + 3.05 then
			safe = Vector3.new(safe.X, flr.Position.Y + 3.05, safe.Z)
		end

		local onMoving = S.anchorPart and not S.anchorPart.Anchored
		root.CFrame = root.CFrame:Lerp(CFrame.lookAt(safe, safe + look), (onMoving or S.banging) and 0.95 or 0.45)
	elseif S.lockedOnWall and not S.vaulting then
		S.fullReset()
	end
end)
print("Part 2B Loaded! Smart 4-Limb Climbing Active.")
