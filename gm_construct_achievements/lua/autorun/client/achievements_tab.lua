surface.CreateFont("AchievementNameFont", {
    font = "Trebuchet24",
    size = 22,
    weight = 800
})

surface.CreateFont("AchievementDescFont", {
    font = "Tahoma",
    size = 17,
    weight = 800
})

if CLIENT then

    -- Here you define the list of achievements, their description, icon and if it is secret
    local ACHIEVEMENTS = {
        { id = "secret_room",     name = "Secret Zone",            description = "Enter the secret room.",              icon = "icon16/door_open.png" },
        { id = "dark_room",       name = "Don´t Turn Back",        description = "Enter the dark room.",                icon = "icon16/eye.png" },
        { id = "light_room",      name = "I can´t see",            description = "Enter the light room.",               icon = "icon16/lightbulb.png" },
        { id = "lake_dive",       name = "Refreshing!",            description = "Touch the lake water.",               icon = "icon16/water.png" },
        { id = "mirror_self",     name = "The coolest guy",        description = "Look at yourself in the mirror.",     icon = "icon16/user.png" },
        { id = "tower_top",       name = "Climbing Up",            description = "Reach the top of the highest tower.", icon = "icon16/arrow_up.png" },
        { id = "spawn_npc",       name = "My Baby",                description = "Spawn your first NPC.",               icon = "icon16/group.png" },
        { id = "dark_room_enemy", name = "Unleash the Darkness",   description = "Spawn an enemy in the dark room.",    icon = "icon16/exclamation.png" },
        { id = "airboat_water",   name = "Ahoy!",                  description = "Drive the airboat on the water.",     icon = "icon16/anchor.png" },
        { id = "garage_parking",  name = "Perfect Parking",        description = "Park a vehicle inside the garage.",   icon = "icon16/car.png" },
		{ id = "speed_demon",     name = "Speed Demon",            description = "Achieve over 200 MPH in a vehicle.",  icon = "icon16/fire.png" },
		{ id = "area_lights",     name = "Defeating the Darkness", description = "Create at least 5 lights in the dark room.",  icon = "icon16/lightbulb_add.png" },
		{ id = "secret_master",   name = "TRUE Completionist",     description = "Unlock all achievements in one run without using noclip.", icon = "icon16/award_star_gold_3.png", secret = true},
    }

    -- Table of unlocked achievements
    local unlocked = {}

    -- References to widgets to be able to refresh them
    local mainPanel, bar, lbl, scroll, trophy

    -- Function that (re)fills the UI according to `unlocked`
	local function RefreshAchievementsUI()
		if not IsValid(scroll) then return end

		-- Calculate progress
		local total, got = 0, 0

		for _, ach in ipairs(ACHIEVEMENTS) do
			if not ach.secret then
				total = total + 1
				if unlocked[ach.id] then
					got = got + 1
				end
			end
		end

		bar:SetFraction(got / total)
		lbl:SetText(string.format("Progress: %d / %d", got, total))

		-- Change the trophy icon to black and white if not all of them have been unlocked.
		if IsValid(trophy) then
			if got < total then
				trophy:SetImageColor(Color(100, 100, 100, 100))
			else
				trophy:SetImageColor(Color(255, 255, 255, 255))
			end
		end

		-- Clear the children of the scroll
		scroll:Clear()

		-- Reconstruct each entry
		for _, ach in ipairs(ACHIEVEMENTS) do
			local pnl = vgui.Create("DPanel", scroll)
			pnl:Dock(TOP)
			pnl:SetTall(64)
			pnl:DockMargin(5,5,5,0)
			pnl:DockPadding(8,8,8,8)
			function pnl:Paint(w, h)
				derma.SkinHook("Paint", "Panel", self, w, h)
				surface.SetDrawColor(241, 241, 241, 255)
				surface.DrawRect(0, 0, w, h)
				if unlocked[ach.id] then
					surface.SetDrawColor(255, 215, 0, 255)
					surface.DrawOutlinedRect(0, 0, w, h)
				end
			end

			local icon = vgui.Create("DImage", pnl)
			icon:Dock(LEFT)
			icon:SetSize(48,48)
			icon:SetImage(ach.icon)
			if not unlocked[ach.id] then
				icon:SetAlpha(100)
				icon:SetImageColor(Color(100, 100, 100))
			else
				icon:SetImageColor(Color(255, 255, 255))
			end

			local title = vgui.Create("DLabel", pnl)
			title:Dock(TOP)
			title:DockMargin(8,0,0,0)
			title:SetFont("AchievementNameFont")
			title:SetText(ach.name)
			title:SetTextColor(Color(102, 102, 102, 255))

			local desc = vgui.Create("DLabel", pnl)
			desc:Dock(BOTTOM)
			desc:DockMargin(8,0,0,0)
			desc:SetFont("AchievementDescFont")
			desc:SetText(ach.description)
		end
	end


    -- Build the panel once, saving references
	local function BuildAchievementsPanel()
		mainPanel = vgui.Create("DPanel")
		mainPanel:Dock(FILL)
		mainPanel:SetPaintBackgroundEnabled(false)
		mainPanel.Paint = function(self, w, h)
			surface.SetDrawColor(156, 159, 164, 255)
			surface.DrawRect(0, 0, w, h)
		end

		-- Progress container: trophy, progress bar, and progress label in one panel.
		local progressContainer = vgui.Create("DPanel", mainPanel)
		progressContainer:Dock(TOP)
		progressContainer:SetTall(68)  -- tall enough for trophy, bar, and label
		progressContainer:DockMargin(10,10,10,5)
		progressContainer.Paint = function() end  -- no background

		-- Trophy icon
		trophy = vgui.Create("DImage", progressContainer)
		trophy:SetImage("icon16/award_star_gold_2.png")
		trophy:SetSize(64,64)
		trophy:Dock(LEFT)
		trophy:DockMargin(0,2,8,2)

		-- Progress bar
		bar = vgui.Create("DProgress", progressContainer)
		bar:Dock(TOP)
		bar:SetTall(40)
		bar:DockMargin(0,0,0,5)
		bar.Paint = function(self, w, h)
			surface.SetDrawColor(240,240,240,255)
			surface.DrawRect(0,0,w,h)
			local fillW = self:GetFraction() * w
			surface.SetDrawColor(180,250,180,255)
			surface.DrawRect(0,0,fillW,h)
			surface.SetDrawColor(59,59,59,255)
			surface.DrawOutlinedRect(0,0,w,h)
		end

		-- Progress label placed immediately below the progress bar
		lbl = vgui.Create("DLabel", progressContainer)
		lbl:Dock(TOP)
		lbl:DockMargin(0,0,0,0)
		lbl:SetContentAlignment(4)  -- center aligned
		-- The text will be updated in RefreshAchievementsUI

		-- Create a horizontal container for the two reset buttons:
		local buttonContainer = vgui.Create("DPanel", mainPanel)
		buttonContainer:Dock(TOP)
		buttonContainer:SetTall(35)
		buttonContainer:DockMargin(10,0,10,10)
		buttonContainer.Paint = function(self, w, h) end  -- transparent

		-- Reset Normal Achievements button (left side)
		local resetButton = vgui.Create("DButton", buttonContainer)
		resetButton:Dock(LEFT)
		resetButton:SetWide(200)
		resetButton:SetText("Reset Normal Achievements")
		resetButton.DoClick = function()
			net.Start("ResetAchievements")
			net.SendToServer()
		end

		-- Reset Secret Achievements button (to the right of the first)
		local resetSecretButton = vgui.Create("DButton", buttonContainer)
		resetSecretButton:Dock(LEFT)
		resetSecretButton:SetWide(200)
		resetSecretButton:SetText("Reset Secret Achievements")
		resetSecretButton.DoClick = function()
			net.Start("ResetStarAchievements")
			net.SendToServer()
		end

		-- Scroll panel for achievement entries
		scroll = vgui.Create("DScrollPanel", mainPanel)
		scroll:Dock(FILL)

		RefreshAchievementsUI()
		return mainPanel
	end

    -- Upon receiving the message, mark and refresh
    net.Receive("UnlockAchievement", function()
        local id = net.ReadString()
        unlocked[id] = true

        if IsValid(mainPanel) then
            RefreshAchievementsUI()
        end
    end)
	
	-- Receive information about unlocked achievements when you log in
	net.Receive("SendAchievementsData", function()
		local data = net.ReadTable() -- data is a table with the IDs of unlocked achievements
		for _, id in ipairs(data) do
			unlocked[id] = true
		end
		RefreshAchievementsUI()
	end)
	
	-- Receiver for normal achievements:
	net.Receive("ResetAchievements", function()
		for k, v in pairs(unlocked) do
			-- Find the achievement in the local ACHIEVEMENTS table.
			local isSecret = false
			for _, ach in ipairs(ACHIEVEMENTS) do
				if ach.id == k then
					isSecret = ach.secret or false
					break
				end
			end
			if not isSecret then
				unlocked[k] = nil
			end
		end
		RefreshAchievementsUI()
	end)

	-- Receiver for secret achievements:
	net.Receive("ResetStarAchievements", function()
		for k, v in pairs(unlocked) do
			local isSecret = false
			for _, ach in ipairs(ACHIEVEMENTS) do
				if ach.id == k then
					isSecret = ach.secret or false
					break
				end
			end
			if isSecret then
				unlocked[k] = nil
			end
		end
		RefreshAchievementsUI()
	end)

    -- Regist the tab
	hook.Add("PopulateToolMenu", "MyAchievementsSpawnmenuTab", function()
		spawnmenu.AddCreationTab("Achievements", BuildAchievementsPanel, "icon16/award_star_gold_1.png", 0)
	end)
end
