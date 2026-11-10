-- FE R15 SMART 4-LIMB CLIMB (PART 2A OF 3)
local S = getgenv().DHC
assert(S, "Run Part 1 first!")

local R, W, TS = game:GetService("RunService"), game:GetService("Workspace"), game:GetService("TweenService")
local cam, char, hum, root = W.CurrentCamera, S.char, S.hum, S.root

if S.tool and S.tool.Parent == char then S.equipped, S.ui.Enabled = true, true end

S.rp = RaycastParams.new()
S.rp.FilterDescendantsInstances, S.rp.FilterType = {char, S.padFolder}, Enum.RaycastFilterType.Exclude

S.airBtn.MouseButton1Click:Connect(function()
	S.airGrab = not S.airGrab
	S.airBtn.Text = S.airGrab and "🪂 CATCHING..." or "🪂 AIR GRAB"
end)

S.leapBtn.MouseButton1Click:Connect(function()
	if not S.lockedOnWall then return end
	local vel = (S.anchorPart and S.anchorPart.Parent) and S.anchorPart.AssemblyLinearVelocity or Vector3.zero
	S.fullReset()
	root.AssemblyLinearVelocity = vel + cam.CFrame.LookVector * 50 + Vector3.new(0, 36, 0)
	S.airGrab, S.airBtn.Text = true, "🪂 CATCHING..."
end)

S.vault = function(top)
	if S.vaulting then return end
	S.vaulting, S.statusLbl.Text = true, "🧗 VAULTING ONTO LEDGE..."
	S.fullReset()
	root.Anchored = true
	S.tracks.vault:Play(0.12, 1, 0.85)
	local fwd = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local upCF = CFrame.new(root.Position.X, top.Y + 3.1, root.Position.Z) * root.CFrame.Rotation
	for _, cf in ipairs({upCF, upCF + fwd * 3.1}) do
		local t = TS:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = cf})
		t:Play() t.Completed:Wait()
	end
	S.tracks.vault:Stop(0.2)
	root.Anchored, hum.PlatformStand, S.vaulting = false, false, false
end

S.isPole = function(part)
	if not part then return false end
	local minH = math.min(part.Size.X, part.Size.Z)
	return (part:IsA("Part") and part.Shape == Enum.PartType.Cylinder and part.Size.X > 3.5) or (minH <= 3.6 and part.Size.Y >= 4)
end

-- Set unified exterior surface anchor so limbs NEVER drift apart or clip inside windows/rooms
S.setAnchor = function(hit)
	S.anchorPart = hit.Instance
	S.anchorPos = hit.Position
	S.anchorNorm = hit.Normal
	S.localAnchorPos = hit.Instance.CFrame:PointToObjectSpace(hit.Position)
	S.localAnchorNorm = hit.Instance.CFrame:VectorToObjectSpace(hit.Normal)
end

-- Smart AI Surface Scanner: Probes outer wall geometry & rejects thin window glass / interior back-walls
S.smartMoveAnchor = function(ix, iy, dt)
	local p, n, part = S.anchorPos, S.anchorNorm, S.anchorPart
	if not part or not part.Parent then return false end

	if S.isPole(part) then
		local lp = part.CFrame:PointToObjectSpace(p)
		local ny = math.clamp(lp.Y + iy * 5.2 * dt, -part.Size.Y * 0.48, part.Size.Y * 0.48)
		local rad = Vector3.new(lp.X, 0, lp.Z)
		rad = (rad.Magnitude > 0.01 and rad.Unit or Vector3.new(0, 0, 1))
		local rot = (CFrame.Angles(0, -ix * 2.6 * dt, 0) * rad).Unit
		local wh = W:Raycast(part.CFrame:PointToWorldSpace(Vector3.new(0, ny, 0) + rot * 2.2), part.CFrame:VectorToWorldSpace(-rot * 2.6), S.rp)
		if wh and wh.Instance == part then S.setAnchor(wh) return true end
		return false
	end

	local wR = Vector3.yAxis:Cross(n)
	wR = (wR.Magnitude < 0.1 and root.CFrame.RightVector or wR).Unit
	local wU = n:Cross(wR).Unit
	-- Slower, realistic human climbing speed (4.6 studs/sec)
	local step = (wR * ix * 4.6 * dt) + (wU * iy * 5.2 * dt)
	if step.Magnitude < 0.001 then return true end

	-- 1. Check if stepping onto a perpendicular outer wall (concave corner)
	local cornerIn = W:Raycast(p + n * 0.6, step.Unit * (step.Magnitude + 0.65), S.rp)
	if cornerIn and cornerIn.Instance.CanCollide and cornerIn.Instance.Transparency < 0.85 and cornerIn.Normal:Dot(n) > -0.25 then
		S.setAnchor(cornerIn) return true
	end

	-- 2. Scan outer wall face (short 0.85-stud depth guarantees it NEVER hits interior room walls!)
	local outerHit = W:Raycast(p + step + n * 0.45, -n * 0.85, S.rp)
	if outerHit and outerHit.Instance.CanCollide and outerHit.Instance.Transparency < 0.85 and outerHit.Normal:Dot(n) > 0.45 then
		S.setAnchor(outerHit) return true
	end

	-- 3. Convex 90-degree outer corner wrap (wrapping around outside corner of a building)
	local wrapHit = W:Raycast(p + n * 0.45 + step.Unit * 0.65, (-n * 0.85 - step.Unit * 0.85).Unit * 1.45, S.rp)
	if wrapHit and wrapHit.Instance.CanCollide and wrapHit.Instance.Transparency < 0.85 and wrapHit.Normal:Dot(n) > -0.25 then
		S.setAnchor(wrapHit) return true
	end

	return false
end
print("Part 2A Loaded! Smart AI Surface Scanner ready.")
