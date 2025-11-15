local ProfileTemplate = {
	Money = 0,
	Rebirths = 0,
	Ascensions = 0,
	TimeTokens = 0,
	Boosts = {},
	TimeUpgrades = {
		MoneyMultiplier = 0,
		Conveyor1 = 0,
		Conveyor2 = 0,
		Conveyor3 = 0,
		Conveyor4 = 0,
	},
	Tycoon = {
		["1"] = nil,
		["2"] = nil,
		["3"] = nil,
		["4"] = nil,
		["5"] = nil,
		["6"] = nil,
		["7"] = nil,
		["8"] = nil,
		Owned = {
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false,
			["7"] = false,
			["8"] = false,
		}
	},
}
----- Loaded Modules -----

local ProfileService = require(game.ServerScriptService.ProfileService)
local MarketplaceService = game:GetService("MarketplaceService")

----- Private Variables -----

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Physics = game:GetService("PhysicsService")

local GPs = {1081758798, 1081013553, 1081335439} --Double Money, Double Tokens, Double Rebirth
local debugMode = true

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData_Debug1",
	ProfileTemplate
)

local Profiles = {} -- [player] = profile

----- Private Functions -----

local function saveData(player)
	if debugMode and game:GetService("RunService"):IsStudio() then warn("Active in debug mode, not saving...") return end
	local profile = Profiles[player]
	
	if profile ~= nil then
		if player.leaderstats.Money.Value ~= nil or player.leaderstats.Money.Value ~= 0 then
			profile.Data.Money = player.leaderstats.Money.Value
		end
		
		if player.leaderstats.Rebirths.Value ~= nil or player.leaderstats.Rebirths.Value ~= 0 then
			profile.Data.Money = player.leaderstats.Rebirths.Value
		end
		
		if player.leaderstats.Ascensions.Value ~= nil or player.leaderstats.Ascensions.Value ~= 0 then
			profile.Data.Money = player.leaderstats.Ascensions.Value
		end
		
		if player.gStats.RebirthTokens.Value ~= nil or player.gStats.RebirthTokens.Value ~= 0 then
			profile.Data.RebirthTokens = player.gStats.RebirthTokens.Value
		end
		
		if player.gStats.TimeTokens.Value ~= nil or player.gStats.TimeTokens.Value ~= 0 then
			profile.Data.TimeTokens = player.gStats.TimeTokens.Value
		end
		
		profile.Data.Time = player.gStats.Time.Value
		
		for _, boost in player.gStats.Boosts:GetChildren() do
			if boost.Value > 0 then
				profile.Data.Boosts[boost.Name] = boost.Value
			end
		end
		
		for _, upg in player.gStats.TimeUpgrades:GetChildren() do
			if upg.Value ~= nil or upg.Value ~= 0 then
				profile.Data.TimeUpgrades[upg.Name] = upg.Value
			end
		end
		
		if player.gStats.OwnedTycoon.Value ~= nil then
			for i=1, #player.gStats.OwnedTycoon.Value:FindFirstChild("Bases"):GetChildren() do
				warn("Saving " .. i)

				local base = player.gStats.OwnedTycoon.Value.Bases:FindFirstChild(i)

				if base then
					warn("Found " .. i)
					
					if base:GetAttribute("Owned") ~= nil or base:GetAttribute("Owned") ~= false then
						profile.Data.Tycoon.Owned[tostring(i)] = base:GetAttribute("Owned")
					end

					if base:GetAttribute("Reference") ~= "" and base:GetAttribute("Reference") ~= nil then
						profile.Data.Tycoon[tostring(i)] = base:GetAttribute("Reference")
					end
				end
			end
		end
	else
		warn("Failed to find profile.")
	end
end

local function tycoonClaimed(player)
	local profile = Profiles[player]

	if profile ~= nil then
		if debugMode == false and game:GetService("RunService"):IsStudio() then
			for _, conveyor in player.gStats.OwnedTycoon.Value:FindFirstChild("Conveyors"):GetChildren() do
				conveyor.Conveyor:SetAttribute("Speed", 5+player.gStats.TimeUpgrades:FindFirstChild(conveyor.Name).Value)
			end

			for i=1, #player.gStats.OwnedTycoon.Value:FindFirstChild("Bases"):GetChildren() do
				if profile.Data.Tycoon.Owned[tostring(i)] == true then
					local base = player.gStats.OwnedTycoon.Value.Bases:FindFirstChild(i)

					if base then
						base:SetAttribute("Owned", true)

						if profile.Data.Tycoon[tostring(i)] ~= nil then
							local model = game.ReplicatedStorage.Items:FindFirstChild(profile.Data.Tycoon[tostring(i)])

							if model then
								if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name) then player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):Destroy() end

								local clone = model:Clone()
								if clone:GetAttribute("Type") == "Upgrader" then player.gStats.Upgraders.Value += 1 end
								clone:PivotTo(base.CFrame)
								clone.Parent = player.gStats.OwnedTycoon.Value.Items
								base.Transparency = 1
								clone.Name = base.Name
								base:SetAttribute("Reference", model.Name)
							end
						end
					end
				end
			end
		elseif game:GetService("RunService"):IsStudio() == false then
			for _, conveyor in player.gStats.OwnedTycoon.Value:FindFirstChild("Conveyors"):GetChildren() do
				conveyor.Conveyor:SetAttribute("Speed", 5+player.gStats.TimeUpgrades:FindFirstChild(conveyor.Name).Value)
			end

			for i=1, #player.gStats.OwnedTycoon.Value:FindFirstChild("Bases"):GetChildren() do
				if profile.Data.Tycoon.Owned[tostring(i)] == true then
					local base = player.gStats.OwnedTycoon.Value.Bases:FindFirstChild(i)

					if base then
						base:SetAttribute("Owned", true)

						if profile.Data.Tycoon[tostring(i)] ~= nil then
							local model = game.ReplicatedStorage.Items:FindFirstChild(profile.Data.Tycoon[tostring(i)])

							if model then
								if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name) then player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):Destroy() end

								local clone = model:Clone()
								if clone:GetAttribute("Type") == "Upgrader" then player.gStats.Upgraders.Value += 1 end
								clone:PivotTo(base.CFrame)
								clone.Parent = player.gStats.OwnedTycoon.Value.Items
								base.Transparency = 1
								clone.Name = base.Name
								base:SetAttribute("Reference", model.Name)
							end
						end
					end
				end
			end
		end
	else
		player:Kick("Failed to load tycoon data! Code 4")
	end
end

local function CharacterAdded(character)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Player"
		end
	end
	
	--[[if profile ~= nil then
		
	else
		player:Kick("Failed to find save data on player load! Code 3")
	end]]--
end

local function PlayerAdded(player) 
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick("Failed to load save data! Code 1")
		end)
		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile

			local stats = script.leaderstats:Clone()
			stats.Parent = player
			
			local gStats = script.gStats:Clone()
			gStats.Parent = player
			
			if game:GetService("RunService"):IsStudio() == false then
				stats.Money.Value = profile.Data.Money or 0
				stats.Rebirths.Value = profile.Data.Rebirths or 0
				stats.Ascensions.Value = profile.Data.Ascensions or 0

				gStats.RebirthTokens.Value = profile.Data.RebirthTokens or 0
				gStats.TimeTokens.Value = profile.Data.TimeTokens or 0
				player.gStats.Time.Value = profile.Data.Time or 0
				
				if profile.Data.TimeUpgrades.UpgraderLimit then
					gStats.UpgraderLimit.Value = 2+profile.Data.TimeUpgrades.UpgraderLimit
				else
					gStats.UpgraderLimit.Value = 2
				end
				
				for _, upg in player.gStats.TimeUpgrades:GetChildren() do
					upg.Value = profile.Data.TimeUpgrades[upg.Name] or 0
				end
				
				for _, boost in gStats.Boosts:GetChildren() do
					boost.Value = profile.Data.Boosts[boost.Name] or 0
				end
			elseif debugMode == false then
				stats.Money.Value = profile.Data.Money or 0
				stats.Rebirths.Value = profile.Data.Rebirths or 0
				stats.Ascensions.Value = profile.Data.Ascensions or 0

				gStats.RebirthTokens.Value = profile.Data.RebirthTokens or 0
				gStats.TimeTokens.Value = profile.Data.TimeTokens or 0
				
				if profile.Data.TimeUpgrades.UpgraderLimit then
					gStats.UpgraderLimit.Value = 2+profile.Data.TimeUpgrades.UpgraderLimit
				else
					gStats.UpgraderLimit.Value = 2
				end

				for _, upg in player.gStats.TimeUpgrades:GetChildren() do
					upg.Value = profile.Data.TimeUpgrades[upg.Name] or 0
				end

				for _, boost in gStats.Boosts:GetChildren() do
					boost.Value = profile.Data.Boosts[boost.Name] or 0
				end
			end
			
			if player.UserId ~= 107778329 then
				gStats.DoubleMoney.Value = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GPs[1])
				gStats.DoubleTokens.Value = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GPs[2])
				gStats.DoubleRebirth.Value = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GPs[3])
			else
				gStats.DoubleMoney.Value = false
				gStats.DoubleTokens.Value = false
				gStats.DoubleRebirth.Value = false
			end
			
			gStats.OwnedTycoon.Changed:Connect(function()
				if gStats.OwnedTycoon.Value ~= nil then
					tycoonClaimed(player)
				end
			end)
			
			for _, boost in gStats.Boosts:GetChildren() do
				boost.Changed:Connect(function()
					if boost.Value > 0 and boost:GetAttribute("Counting") == false then
						boost:SetAttribute("Counting", true)
						task.spawn(function()
							while boost.Value > 0 do
								boost.Value -= 1
								task.wait(1)
							end
							print(boost.Name .. "x boost expired!")
							boost:SetAttribute("Counting", false)
						end)
					end

					local multi = 1

					for _, b in gStats.Boosts:GetChildren() do
						if b.Value > 0 then
							multi *= tonumber(b.Name)
						end
					end

					if gStats.DoubleMoney.Value == true then
						multi *= 2
					end
					
					if gStats.TimeUpgrades.MoneyMultiplier.Value > 0 then
						multi += (0.1*gStats.TimeUpgrades.MoneyMultiplier.Value)
					end
					
					if player.leaderstats.Rebirths.Value > 0 then
						multi *= 1+(player.leaderstats.Rebirths.Value*0.5)
					end

					gStats.TotalMultiplier.Value = (multi)
				end)

				player.leaderstats.Rebirths.Changed:Connect(function()
					local multi = 1

					for _, b in gStats.Boosts:GetChildren() do
						if b.Value > 0 then
							multi *= tonumber(b.Name)
						end
					end

					if gStats.DoubleMoney.Value == true then
						multi *= 2
					end
					
					if gStats.TimeUpgrades.MoneyMultiplier.Value > 0 then
						multi += (0.1*gStats.TimeUpgrades.MoneyMultiplier.Value)
					end
					
					if player.leaderstats.Rebirths.Value > 0 then
						multi *= 1+(player.leaderstats.Rebirths.Value*0.5)
					end

					gStats.TotalMultiplier.Value = multi
				end)

				gStats.DoubleMoney.Changed:Connect(function()
					local multi = 1

					for _, b in gStats.Boosts:GetChildren() do
						if b.Value > 0 then
							multi *= tonumber(b.Name)
						end
					end

					if gStats.DoubleMoney.Value == true then
						multi *= 2
					end
					
					if gStats.TimeUpgrades.MoneyMultiplier.Value > 0 then
						multi += (0.1*gStats.TimeUpgrades.MoneyMultiplier.Value)
					end
					
					if player.leaderstats.Rebirths.Value > 0 then
						multi *= 1+(player.leaderstats.Rebirths.Value*0.5)
					end

					gStats.TotalMultiplier.Value = multi
				end)
				
				gStats.TimeUpgrades.MoneyMultiplier.Changed:Connect(function()
					for _, boost in gStats.Boosts:GetChildren() do
						boost.Value = profile.Data.Boosts[boost.Name] or 0
					end

					local multi = 1

					for _, b in gStats.Boosts:GetChildren() do
						if b.Value > 0 then
							multi *= tonumber(b.Name)
						end
					end
					
					if gStats.DoubleMoney.Value == true then
						multi *= 2
					end

					if gStats.TimeUpgrades.MoneyMultiplier.Value > 0 then
						multi += (0.1*gStats.TimeUpgrades.MoneyMultiplier.Value)
					end
					
					if player.leaderstats.Rebirths.Value > 0 then
						multi *= 1+(player.leaderstats.Rebirths.Value*0.5)
					end

					gStats.TotalMultiplier.Value = multi

					if boost.Value > 0 and boost:GetAttribute("Counting") == false then
						boost:SetAttribute("Counting", true)
						task.spawn(function()
							while boost.Value > 0 do
								boost.Value -= 1
								task.wait(1)
							end
							print(boost.Name .. "x boost expired!")
							boost:SetAttribute("Counting", false)
						end)
					end
				end)

				local multi = 1

				for _, b in gStats.Boosts:GetChildren() do
					if b.Value > 0 then
						multi *= tonumber(b.Name)
					end
				end

				if gStats.DoubleMoney.Value == true then
					multi *= 2
				end
				
				if gStats.TimeUpgrades.MoneyMultiplier.Value > 0 then
					multi += (0.1*gStats.TimeUpgrades.MoneyMultiplier.Value)
				end
				
				if player.leaderstats.Rebirths.Value > 0 then
					multi *= 1+(player.leaderstats.Rebirths.Value*0.5)
				end

				gStats.TotalMultiplier.Value = multi
				
				if boost.Value > 0 and boost:GetAttribute("Counting") == false then
					boost:SetAttribute("Counting", true)
					task.spawn(function()
						while boost.Value > 0 do
							boost.Value -= 1
							task.wait(1)
						end
						print(boost.Name .. "x boost expired!")
						boost:SetAttribute("Counting", false)
					end)
				end
			end
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		-- Roblox servers trying to load this profile at the same time:
		player:Kick("Failed to read save data! Code 2")
	end
	player.CharacterAdded:Connect(CharacterAdded)
end

----- Initialize -----

-- In case Players have joined the server earlier than this script ran:
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

----- Connections -----

game.ServerStorage.SaveUserdata.Event:Connect(saveData)

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile then
		task.wait(0.5)
		profile:Release()
	end
end)

task.spawn(function()
	while task.wait(60) do
		for _, player in pairs(Players:GetPlayers()) do
			task.wait()
			saveData(player)
		end
	end
	
	game.ReplicatedStorage.Remotes.SendClientNotifications:FireAllClients("Successfully Saved Data!", Color3.fromRGB(73, 239, 58), 3)
end)

if game:GetService("RunService"):IsStudio() == false then
	game:BindToClose(function()
		task.wait(2)
	end)
end