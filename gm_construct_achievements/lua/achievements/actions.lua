if SERVER then

	-- SPAWN FIRST NPC
	
	RegisterAchievement("spawn_npc", "My baby", "Spawn your first NPC.", function(ply)
		if ply.__spawned_npc then
			UnlockAchievement(ply, "spawn_npc")
		end
	end)

	hook.Add("PlayerSpawnedNPC", "TrackFirstNPC", function(ply, npc)
		ply.__spawned_npc = true
	end)

	-- ENEMY SPAWN IN DARK ROOM
	hook.Add("PlayerSpawnedNPC", "Achievement_DarkRoomEnemySpawn", function(ply, ent)
		if not IsValid(ply) or not IsValid(ent) then return end

		local spawnPos = ent:GetPos()

		-- Only count NPCs hostile to players and detect if the spawn position is in the dark room
		if ent:IsNPC() and ent:Disposition(ply) == D_HT and spawnPos:WithinAABox(Vector(-5200, -2550, -170), Vector(-3300, -1050, 80)) then
			UnlockAchievement(ply, "dark_room_enemy")
		end
	end)

	-- Register the achievement
	RegisterAchievement("dark_room_enemy", "Unleash the Darkness", "Spawn an enemy in the dark room.", function(ply)
	-- This is triggered externally via the PlayerSpawnedNPC hook
	end)

	-- AIRBOAT ON THE LAKE
	
	local playersDrivingAirboatInWater = {}
	
	_G.playersDrivingAirboatInWater = playersDrivingAirboatInWater

	hook.Add("Think", "CheckAirboatOnWater", function()
		for _, vehicle in ipairs(ents.FindByClass("prop_vehicle_airboat")) do
			if IsValid(vehicle) and vehicle:GetDriver() ~= NULL then
				local driver = vehicle:GetDriver()
				if not IsValid(driver) then return end

				-- Check if the bottom of the airboat is in water
				local pos = vehicle:GetPos()
				local isInWater = bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER

				if isInWater then
					local id = driver:SteamID()
					if not playersDrivingAirboatInWater[id] then
						playersDrivingAirboatInWater[id] = true
						UnlockAchievement(driver, "airboat_water")
					end
				end
			end
		end
	end)

	RegisterAchievement("airboat_water", "Ahoy!", "Drive the airboat on the water.", function(ply)
	end)

	-- PARK VEHICLE IN GARAGE

	-- Approximate coordinates of the garage in gm_construct
	local garageMin = Vector(-1100, -1900, -160)
	local garageMax = Vector(-2800, -1100, 100)

	local vehiclesParked = {}
	
	_G.vehiclesParked = vehiclesParked

	-- List of vehicle classes to be detected
	local vehicleClasses = {
		"prop_vehicle_jeep_old",
		"prop_vehicle_airboat"
	}

	hook.Add("Think", "CheckVehicleInGarage", function()
		for _, class in ipairs(vehicleClasses) do
			for _, vehicle in ipairs(ents.FindByClass(class)) do
				if IsValid(vehicle) and vehicle:GetDriver() ~= NULL then
					local driver = vehicle:GetDriver()
					if not IsValid(driver) then return end

					-- Check if the vehicle is in garage
					local pos = vehicle:GetPos()
					if pos:WithinAABox(garageMin, garageMax) then
						local id = driver:SteamID()
						if not vehiclesParked[id] then
							vehiclesParked[id] = true
							UnlockAchievement(driver, "garage_parking")
						end
					end
				end
			end
		end
	end)

	RegisterAchievement("garage_parking", "Perfect Parking", "Park a vehicle inside the garage.", function(ply)
	end)
	
	-- VEHICLE SPEED MORE THAN 200 MPH
	
    -- Table to prevent the achievement from being unlocked multiple times in a single session.
    local playersAchievedSpeed = {}
    _G.playersAchievedSpeed = playersAchievedSpeed  -- It is exposed globally to be reset in core.lua

    hook.Add("Think", "CheckVehicleSpeed", function()
        for _, ply in ipairs(player.GetAll()) do
            local veh = ply:GetVehicle()
            if IsValid(veh) then
                local speed = veh:GetSpeed()  -- Velocity in Miles Per Hour
                if speed >= 200 then
                    local sid = ply:SteamID()
                    if not playersAchievedSpeed[sid] then
                        playersAchievedSpeed[sid] = true
                        UnlockAchievement(ply, "speed_demon")
                    end
                end
            end
        end
    end)

    RegisterAchievement("speed_demon", "Speed Demon", "Achieve over 200 MPH in a vehicle.", function(ply)
    end)
	
	-- SPAWN 5 LIGHTS IN THE DARK ROOM
	
    -- Make sure to use the global table to count the lights in the area
    _G.AreaLightsCount = _G.AreaLightsCount or {}

    RegisterAchievement("area_lights", "Defeating the Darkness", "Create at least 5 lights in the dark room.", function(ply)
    end)

    -- Hook to detect when a light is created (using the hook we activated when overriding MakeLight)
    hook.Add("LightCreated", "Achievement_LightsInArea", function(light)
        if IsValid(light) then
            local pos = light:GetPos()
            -- Check if the light was created within the defined area
            if pos:WithinAABox(Vector(-5260, -2570, -170), Vector(-3240, -1050, 180)) then
                local ply = light:GetPlayer()  -- The light was assigned to the player in MakeLight
                if IsValid(ply) then
                    local sid = ply:SteamID()
                    _G.AreaLightsCount[sid] = (_G.AreaLightsCount[sid] or 0) + 1
                    print("[Achievement] " .. ply:Nick() .. " ha creado " .. _G.AreaLightsCount[sid] .. " luces en el área.")
                    if _G.AreaLightsCount[sid] >= 5 then
                        UnlockAchievement(ply, "area_lights")
                    end
                end
            end
        end
    end)
end

	-- THIS ADDS A HUD TO DISPLAY VEHICLE SPEED
	
if CLIENT then
    -- Create or use a custom font (you may adjust it as needed)
    surface.CreateFont("SpeedometerFont", {
        font = "Trebuchet24",
        size = 30,
        weight = 800,
        antialias = true,
    })

	hook.Add("HUDPaint", "DrawVehicleSpeedHUD", function()
		-- Check if "Draw HUD" is enabled; if not, exit the function
		if GetConVar("cl_drawhud"):GetInt() == 0 then return end

		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local veh = ply:GetVehicle()
		if IsValid(veh) then
			-- Get speed in Hammer units per second and convert to MPH
			local speedUnits = veh:GetVelocity():Length()  -- Speed in units per second
			local mph = speedUnits * 0.05635              -- Convert to MPH (approximate)

			-- Draw the speed text on the screen
			draw.SimpleText(
				string.format("Speed: %.1f MPH", mph),
				"SpeedometerFont",
				ScrW() * 0.5,           -- X position (centered horizontally)
				ScrH() * 0.9,           -- Y position (near the bottom)
				Color(255, 255, 255, 255), -- White color
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	end)
end
