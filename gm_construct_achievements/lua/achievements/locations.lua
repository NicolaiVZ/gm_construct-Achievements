-- This script checks if a player reaches a specific location.

if SERVER then
	-- SECRET ROOM
	RegisterAchievement("secret_room", "Secret Zone", "Enter the secret room.", function(ply)
		local pos = ply:GetPos()
		if pos:WithinAABox(Vector(-3100, -1390, -160), Vector(-2900, -1050, -30)) then
			UnlockAchievement(ply, "secret_room")
		end
	end)

	-- DARK ROOM
	RegisterAchievement("dark_room", "Don´t Turn Back", "Enter the dark room.", function(ply)
		local pos = ply:GetPos()
		if pos:WithinAABox(Vector(-5200, -2550, -170), Vector(-3300, -1050, 80)) then
			UnlockAchievement(ply, "dark_room")
		end
	end)

	-- LIGHT ROOM
	RegisterAchievement("light_room", "I can´t see", "Enter the light room.", function(ply)
		local pos = ply:GetPos()
		if pos:WithinAABox(Vector(-800, -4550, -320), Vector(-3280, -2650, 80)) then
			UnlockAchievement(ply, "light_room")
		end
	end)

	-- TOUCH WATER
	RegisterAchievement("lake_dive", "Refreshing!", "Touch the lake water.", function(ply)
		if ply:WaterLevel() >= 1 then
			UnlockAchievement(ply, "lake_dive")
		end
	end)

	-- LOOK AT THE MIRROR
	RegisterAchievement("mirror_self", "The coolest guy of the map", "Look at yourself in the mirror room.", function(ply)
		local pos = ply:GetPos()
		local eyeAng = ply:EyeAngles()
		local pitch = eyeAng.x  -- X (up/down)
		local yaw = eyeAng.y    -- Y (left/right)
		local pitchMin, pitchMax = -15, 30
		local yawMin, yawMax = -110, -70
		
		if not pos:WithinAABox(Vector(-2680, -2052, -445), Vector(-1450, -1800, -180)) then return end
		
		if pitch < pitchMin or pitch > pitchMax then return end

		-- Check if yaw is in range (handle crossing -180/180 if needed)
		if yawMin < yawMax then
			if yaw < yawMin or yaw > yawMax then return end
		else
			-- For inverted ranges (e.g., yawMin = 170, yawMax = -170)
			if yaw > yawMax and yaw < yawMin then return end
		end

		UnlockAchievement(ply, "mirror_self")
	end)

	-- TOWER TOP
	RegisterAchievement("tower_top", "Climbing Up", "Reach the top of the highest tower", function(ply)
		local pos = ply:GetPos()
		if pos:WithinAABox(Vector(-1650, -2300, 2830), Vector(-2960, -3280, 3100)) then
			UnlockAchievement(ply, "tower_top")
		end
	end)
end