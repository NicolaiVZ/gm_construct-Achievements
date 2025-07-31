-- Core achievements script with icon support and network strings
local achievements = {}

if SERVER then
    util.AddNetworkString("SendAchievementsData")
    util.AddNetworkString("UnlockAchievement")
    util.AddNetworkString("ResetAchievements") 
	util.AddNetworkString("ResetStarAchievements") 

    AddCSLuaFile("autorun/client/achievements_tab.lua")
	
	-- Track if a player ever toggled noclip this session
	hook.Add("PlayerNoClip", "Achievements_CheckNoClip", function(ply, desired)
		if desired then
			ply._NoClipUsed = true
		end
	end)

    
    -- Function to save player achievements to a file
    local function SavePlayerAchievements(ply)
        local sid = ply:SteamID()
        local data = {}
        -- Go through each achievement and if it is unlocked for the player, save it
        for id, ach in pairs(achievements) do
            if ach.unlocked[sid] then
                table.insert(data, id)
            end
        end
        -- Create the directory if necessary
        if not file.IsDir("achievements", "DATA") then
            file.CreateDir("achievements")
        end
        local fileName = "achievements/" .. string.Replace(sid, ":", "_") .. ".txt"
        file.Write(fileName, util.TableToJSON(data, true))  -- Save in JSON format
    end

    -- Function to load player achievements from file
    local function LoadPlayerAchievements(ply)
        local sid = ply:SteamID()
        local fileName = "achievements/" .. string.Replace(sid, ":", "_") .. ".txt"
        if file.Exists(fileName, "DATA") then
            local json = file.Read(fileName, "DATA")
            local data = util.JSONToTable(json)
            if data then
                for _, id in ipairs(data) do
                    if achievements[id] then
                        achievements[id].unlocked[sid] = true
                    end
                end
            end
        end
    end

    -- Load the player's achievements upon entering the game
	hook.Add("PlayerInitialSpawn", "LoadPlayerAchievements", function(ply)
		timer.Simple(1, function()
			if IsValid(ply) then
				LoadPlayerAchievements(ply)
				
				-- Scroll through each achievement to create a list of unlocked achievements for this player.
				local sid = ply:SteamID()
				local unlockedList = {}
				for id, ach in pairs(achievements) do
					if ach.unlocked[sid] then
						table.insert(unlockedList, id)
					end
				end
				
				-- Send the list via the net message "SendAchievementsData"
				net.Start("SendAchievementsData")
					net.WriteTable(unlockedList)
				net.Send(ply)
			end
		end)
	end)

    --- Registra un logro. (Función no cambia respecto a tu implementación original)
    function RegisterAchievement(id, name, description, icon, callback)
        if type(icon) == "function" then
            callback = icon
            icon = nil
        end

        achievements[id] = {
            name = name,
            description = description,
            icon = icon,
            callback = callback,
            unlocked = {} -- Table of players who have unlocked this achievement
        }
    end

    -- We modified UnlockAchievement to save the achievement after unlocking it.
	function UnlockAchievement(ply, id)
		local sid = ply:SteamID()
		if achievements[id] and not achievements[id].unlocked[sid] then
			achievements[id].unlocked[sid] = true

			-- Create a session-only table on the player if it doesn't exist and mark this achievement.
			ply._sessionAchievements = ply._sessionAchievements or {}
			ply._sessionAchievements[id] = true

			net.Start("UnlockAchievement")
				net.WriteString(id)
			net.Send(ply)
			
			ply:ChatPrint("[Achievements] " .. ply:Nick() .. " unlocked: " .. achievements[id].name)
			
			SavePlayerAchievements(ply)
		end
	end

    -- Handler to reset achievements (this message is triggered by pressing the button in the UI)
    net.Receive("ResetAchievements", function(len, ply)
        local sid = ply:SteamID()
        for id, ach in pairs(achievements) do
            if ach.unlocked[sid] and not ach.secret then
                ach.unlocked[sid] = nil
            end
        end

        -- Reset any custom flags or variables
        ply.__spawned_npc = false
        ply.__mapStartTime = nil
		ply._NoClipUsed = false
		
		if _G.playersDrivingAirboatInWater then
			_G.playersDrivingAirboatInWater[sid] = nil
		end
		
		if _G.vehiclesParked then
			_G.vehiclesParked[sid] = nil
		end
		
		if _G.playersAchievedSpeed then
			_G.playersAchievedSpeed[sid] = nil
		end
		
		if _G.AreaLightsCount then
			_G.AreaLightsCount[sid] = nil
		end
		
		-- Clear session achievements for normal (non-secret) achievements.
		if ply._sessionAchievements then
			for id, ach in pairs(achievements) do
				if not ach.secret then
					ply._sessionAchievements[id] = nil
				end
			end
		end

        net.Start("ResetAchievements")
        net.Send(ply)
        
        SavePlayerAchievements(ply)
    end)
	
	net.Receive("ResetStarAchievements", function(len, ply)
		local sid = ply:SteamID()
		for id, ach in pairs(achievements) do
			if ach.unlocked[sid] and ach.secret then
				ach.unlocked[sid] = nil
			end
		end
		
		ply._sessionAchievements = {}
		
		net.Start("ResetStarAchievements")
		net.Send(ply)
		
		SavePlayerAchievements(ply)
	end)
	
	-- Track noclip usage:
	hook.Add("PlayerNoClip", "Achievements_CheckNoClip", function(ply, desired)
		if desired then ply._NoClipUsed = true end
	end)

	-- Secret “TRUE Completionist” achievement:
	RegisterAchievement(
	  "secret_master",
	  "TRUE Completionist",
	  "Unlock all achievements in one run without using noclip.",
	  "icon16/award_star_gold_3.png",
	  function(ply)
		-- Use the session table, and don't count if noclip was used.
		if ply._NoClipUsed then return end
		
		ply._sessionAchievements = ply._sessionAchievements or {}
		for id, ach in pairs(achievements) do
		  -- Skip the secret achievement itself.
		  if id ~= "secret_master" then
			if not ply._sessionAchievements[id] then
			  return
			end
		  end
		end
		
		UnlockAchievement(ply, "secret_master")
	  end
	)

	-- Mark it secret so client UI can skip it in the bar
	achievements["secret_master"].secret = true
	
end

-- Shared functions (client and server)
function CheckAchievements(ply)
    for id, ach in pairs(achievements) do
        ach.callback(ply)
    end
end

local allHooks = hook.GetTable()

if allHooks.Think and allHooks.Think["AchievementThink"] then
    return
end

hook.Add("Think", "AchievementThink", function()
    for _, ply in ipairs(player.GetAll()) do
        CheckAchievements(ply)
    end
end)

_G.RegisterAchievement = RegisterAchievement
_G.UnlockAchievement = UnlockAchievement