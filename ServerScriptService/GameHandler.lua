local debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local Collision = game:GetService("PhysicsService")
local MarketplaceService = game:GetService("MarketplaceService")
local httpService = game:GetService("HttpService")

local webhook = ""
local emojiId = "<:robux:1344694061667450953>"
local baseRebirthCost = 1000000
local rebirthIncrease = 0.5

local parts = game.Workspace:GetDescendants()

local suffixes = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
	"Ud",
	"Dd"
}

function abbreviate(number)
	local abbreviationFactor = math.floor(math.floor(math.log10(number)) / 3)
	local abbreviation = ""
	if abbreviationFactor > 0 then
		abbreviation = string.format("%.2f", number / 10 ^ (abbreviationFactor * 3)) .. suffixes[abbreviationFactor + 1]
	else
		abbreviation = tostring(number)
	end

	return abbreviation
end

function updateConveyors()
	for _, part in pairs(parts) do
		if part.Name == "Conveyor" and part:IsA("BasePart") then
			part.AssemblyLinearVelocity = part.CFrame.LookVector * part:GetAttribute("Speed")
		end
	end
end

function updateDroppers()
	
end

function dropPart(dropper: Model?, userFolder: Folder, player: Player)
	if player == nil then warn("Cancelling drop, player nil.") return end
	if dropper == nil then return end
	for _, drop in dropper:GetDescendants() do
		if drop:IsA("BasePart") and drop.Name == "Drop" then
			local deb = false
			local upgDeb = false
			local clone = ServerStorage.DropPart:Clone()
			clone.CFrame = drop.CFrame
			clone:SetAttribute("Price", dropper:GetAttribute("DropPrice"))
			clone.Parent = userFolder.Drops
			clone.CollisionGroup = "Drop"
			clone:SetNetworkOwner(player)
			debris:AddItem(clone, 30)

			clone.Touched:Connect(function(hit)
				if hit.Name == "Upgrader" and hit.Parent then
					if upgDeb == true then return end
					upgDeb = true

					if hit.Parent:GetAttribute("UpgradeType") == "Add" then
						local add = clone:GetAttribute("Price") + hit.Parent:GetAttribute("Upgrade")
						clone:SetAttribute("Price", add)
					elseif hit.Parent:GetAttribute("UpgradeType") == "Multiply" then
						local add = clone:GetAttribute("Price") * hit.Parent:GetAttribute("Upgrade")
						clone:SetAttribute("Price", add)
					end

					task.wait(0.05)
					upgDeb = false
				end

				if hit.Name == "Furnace" and hit.Parent == userFolder and deb == false then
					deb = true
					hit.Attachment.Particle:Emit(math.random(7, 14))
					clone:Destroy()
					local owner = userFolder:GetAttribute("OwnerId")

					if owner ~= 0 then
						local plr = game.Players:GetPlayerByUserId(owner)

						if plr and plr:FindFirstChild("leaderstats") and plr:FindFirstChild("leaderstats"):FindFirstChild("Money") then
							plr.leaderstats.Money.Value += (clone:GetAttribute("Price")*plr.gStats.TotalMultiplier.Value)
						end
					end
				end
			end)
		end
	end
end

function buyTimeUpgrade(plr: Player, upgradeName: string)
	if plr:FindFirstChild("gStats") then
		if plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName) then
			if upgradeName == "UpgraderLimit" then
				if plr:FindFirstChild("gStats").TimeTokens.Value >= (plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value+1)*3 then
					plr:FindFirstChild("gStats").TimeTokens.Value -= (plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value+1)*3
					plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value += 1
					plr.gStats.UpgraderLimit.Value = 2+plr.gStats.TimeUpgrades:FindFirstChild(upgradeName).Value
				end
			else
				if plr:FindFirstChild("gStats").TimeTokens.Value >= (plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value+1) then
					plr:FindFirstChild("gStats").TimeTokens.Value -= (plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value+1)
					plr:FindFirstChild("gStats").TimeUpgrades:FindFirstChild(upgradeName).Value += 1

					if plr.gStats:FindFirstChild("OwnedTycoon").Value then
						for _, model in plr.gStats:FindFirstChild("OwnedTycoon").Value.Conveyors:GetChildren() do
							local conveyor = model:FindFirstChild("Conveyor")

							if conveyor then
								conveyor:SetAttribute("Speed", (5+plr.gStats.TimeUpgrades:FindFirstChild(model.Name).Value))
							end
						end
					end
				end
			end
		end
	end
end

function startDropper(dropper: Model?, userFolder: Folder?, player: Player)
	if player == nil then warn("Cancelling loop, player nil.") return end
	task.spawn(function()
		while dropper ~= nil do
			task.wait(dropper:GetAttribute("SpawnRate"))
			dropPart(dropper, userFolder, player)
		end
		warn("Loop ended unexpectedly. Dropper changed?")
	end)
end

function giveAllTokens()
	for _, player in game.Players:GetPlayers() do
		if player:FindFirstChild("gStats") then
			task.wait()
			player.gStats.TimeTokens.Value += 1
		end
	end
	
	game.ReplicatedStorage.Remotes.SendClientNotifications:FireAllClients("You were given <b>ONE</b> time token!", Color3.fromRGB(255, 173, 57), 5)
end

function ProcessReceipt(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local retry = 0
	local sentWH = false
	
	print(MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product))
	if player then
		print("Got player! Sending webhook...")
		
		local success, err = pcall(function()
			httpService:PostAsync(webhook,
				httpService:JSONEncode({
					content = "@" .. player.Name .. " (" .. tostring(receiptInfo.PlayerId) .. ") bought '" .. tostring(MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product).Name) .. "' for " .. emojiId .. tostring(MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product).PriceInRobux) .. "! Purchase ID: " .. tostring(receiptInfo.PurchaseId)
				})
			)
		end)
		
		while not success do
			retry += 1
			warn("Webhook send failed. Trying in 1s.")
			task.wait(1)
			local success, err = pcall(function()
				httpService:PostAsync(webhook,
					httpService:JSONEncode({
						content = "@" .. player.Name .. " (" .. tostring(receiptInfo.PlayerId) .. ") bought '" .. tostring(MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product).Name) .. "' for " .. emojiId .. tostring(MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product).PriceInRobux) .. "! Purchase ID: " .. tostring(receiptInfo.PurchaseId)
					})
				)
			end)

			if success then sentWH = true break end
			if retry >= 3 then sentWH = false break end
		end

		if success then
			sentWH = true
			print("Sent webhook. Checking product info now!")
		else
			sentWH = false
			print("Failed to log purchase. Continuing anyway...")
		end
		
		if receiptInfo.ProductId == 3226520704 then
			player.gStats.Boosts["2"].Value += 7200
			player.gStats.Boosts["3"].Value += 3600
			player.gStats.Boosts["5"].Value += 900
			player.leaderstats.Money.Value += 10000
			warn("Successfully added player data!")
			game.ServerStorage.SaveUserdata:Fire(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Product " .. receiptInfo.ProductId .. " was not found in the list.")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	else
		warn("Player was not found. Product purchase could not complete.")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

for _, folder in game.Workspace.Tycoons:GetChildren() do
	local player = nil
	local droppers = folder:FindFirstChild("Items")
	local gate = folder:FindFirstChild("Gate"):FindFirstChild("Touch")
	
	gate.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") == nil then return end
		player = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		if folder:GetAttribute("OwnerId") == 0 and player and player.gStats.OwnedTycoon.Value == nil then
			folder:SetAttribute("OwnerId", player.UserId)
			player.gStats.OwnedTycoon.Value = folder
			gate.Transparency = 1
		end
	end)
	
	task.spawn(function()
		repeat wait() until player ~= nil

		if droppers then
			for _, dropper in droppers:GetChildren() do
				if dropper:IsA("Model") and dropper:GetAttribute("SpawnRate") and dropper:GetAttribute("DropPrice") then
					startDropper(dropper, folder, player)
				end
			end

			droppers.ChildAdded:Connect(function(child)
				if child:IsA("Model") and child:GetAttribute("SpawnRate") and child:GetAttribute("DropPrice") then
					startDropper(child, folder, player)
				end
			end)
		end
	end)
end

game.Players.PlayerAdded:Connect(function(player)
	local folder = player:WaitForChild("gStats")
	
	player.CharacterAdded:Connect(function()
		for _, part in player.Character:GetDescendants() do
			if part:IsA("BasePart") then
				print(part.Name, "added!")
				part.CollisionGroup = "Player"
			end
		end
	end)
end)

task.spawn(function()
	while task.wait(1) do
		updateConveyors()
	end
end)

game.ReplicatedStorage.Remotes.BuyBase.OnServerEvent:Connect(function(player: Player, base: BasePart)
	if player and base then
		local folder = base.Parent.Parent
		
		if folder:GetAttribute("OwnerId") == player.UserId then
			if player.leaderstats.Money.Value >= base:GetAttribute("Cost") then
				player.leaderstats.Money.Value -= base:GetAttribute("Cost")
				base:SetAttribute("Owned", true)
			else
				game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "You need $" .. abbreviate(math.round(base:GetAttribute("Cost") - player.leaderstats.Money.Value)) .. " more to buy this.", Color3.fromRGB(246, 75, 58), 3)
				return
			end
		end
	end
end)

game.ReplicatedStorage.Remotes.ChangeItem.OnServerEvent:Connect(function(player: Player, dropper: string, base: BasePart)
	if dropper ~= nil and base ~= nil and base:GetAttribute("Owned") == true then
		local model = game.ReplicatedStorage.Items:FindFirstChild(dropper)
		
		if model then
			if model:GetAttribute("Type") == "Upgrader" then
				if player.gStats.Upgraders.Value < player.gStats.UpgraderLimit.Value then
					local cost = model:GetAttribute("Cost")
					
					if player.leaderstats.Money.Value < cost then 
						if game:GetService("RunService"):IsStudio() == false then
							game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "You need $" .. abbreviate(math.round(model:GetAttribute("Cost") - player.leaderstats.Money.Value)) .. " more to buy this.", Color3.fromRGB(246, 75, 58), 3)
							return
						end
					end

					if model.Name == base:GetAttribute("Reference") then
						game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "This spot already has " .. model:GetAttribute('DisplayName') .. ".", Color3.fromRGB(246, 75, 58), 3)
						return
					end

					if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name) then if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):GetAttribute("Type") == "Upgrader" then if model:GetAttribute("Type") == "Upgrader" then player.gStats.Upgraders.Value -= 1 end end player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):Destroy() end
					player.leaderstats.Money.Value -= cost
					player.gStats.Upgraders.Value += 1
					local clone = model:Clone()
					clone:PivotTo(base.CFrame)
					clone.Parent = player.gStats.OwnedTycoon.Value.Items
					base.Transparency = 1
					clone.Name = base.Name
					base:SetAttribute("Reference", model.Name)
				elseif player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):GetAttribute("Type") == "Upgrader" then
					local cost = model:GetAttribute("Cost")
					
					if player.leaderstats.Money.Value < cost then 
						if game:GetService("RunService"):IsStudio() == false then
							game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "You need $" .. abbreviate(math.round(model:GetAttribute("Cost") - player.leaderstats.Money.Value)) .. " more to buy this.", Color3.fromRGB(246, 75, 58), 3)
							return
						end
					end

					if model.Name == base:GetAttribute("Reference") then
						game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "This spot already has " .. model:GetAttribute('DisplayName') .. ".", Color3.fromRGB(246, 75, 58), 3)
						return
					end
					
					if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name) then player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):Destroy() end
					
					player.leaderstats.Money.Value -= cost
					local clone = model:Clone()
					clone:PivotTo(base.CFrame)
					clone.Parent = player.gStats.OwnedTycoon.Value.Items
					base.Transparency = 1
					clone.Name = base.Name
					base:SetAttribute("Reference", model.Name)
				else
					game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "You reached your max upgraders of " .. player.gStats.UpgraderLimit.Value .. ".", Color3.fromRGB(246, 75, 58), 3)
				end
			elseif model:GetAttribute("Type") == "Dropper" then
				local cost = model:GetAttribute("Cost")
				if player.leaderstats.Money.Value < cost then 
					if game:GetService("RunService"):IsStudio() == false then
						game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "You need $" .. abbreviate(math.round(model:GetAttribute("Cost") - player.leaderstats.Money.Value)) .. " more to buy this.", Color3.fromRGB(246, 75, 58), 3)
						return
					end
				end
				
				if model.Name == base:GetAttribute("Reference") then
					game.ReplicatedStorage.Remotes.SendClientNotifications:FireClient(player, "This spot already has " .. model:GetAttribute('DisplayName') .. ".", Color3.fromRGB(246, 75, 58), 3)
					return
				end

				if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name) then if player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):GetAttribute("Type") == "Upgrader" then if model:GetAttribute("Type") ~= "Upgrader" then player.gStats.Upgraders.Value -= 1 end end player.gStats.OwnedTycoon.Value.Items:FindFirstChild(base.Name):Destroy() end
				player.leaderstats.Money.Value -= cost
				local clone = model:Clone()
				clone:PivotTo(base.CFrame)
				clone.Parent = player.gStats.OwnedTycoon.Value.Items
				base.Transparency = 1
				clone.Name = base.Name
				base:SetAttribute("Reference", model.Name)
			end
		end
	end
end)

game.ReplicatedStorage.Remotes.BuyItem.OnServerEvent:Connect(function(player, id)
	MarketplaceService:PromptProductPurchase(player, id)
end)

game.ReplicatedStorage.Remotes.BuyGamepass.OnServerEvent:Connect(function(player, id)
	MarketplaceService:PromptGamePassPurchase(player, id)
end)

game.ReplicatedStorage.Remotes.Rebirth.OnServerEvent:Connect(function(player)
	local index = 0
	local rebirths = 0
	while task.wait() do
		index += 1
		if player.leaderstats.Money.Value >= baseRebirthCost*((rebirthIncrease)*1.75^(player.leaderstats.Rebirths.Value+index)) then
			for _, item in player.gStats.OwnedTycoon.Value.Items:GetChildren() do
				item:Destroy()
			end

			for _, base in player.gStats.OwnedTycoon.Value.Bases:GetChildren() do
				base.Transparency = 0.5
				base:SetAttribute("Reference", "")
				base:SetAttribute("Owned", false)
			end

			for _, drop in player.gStats.OwnedTycoon.Value.Drops:GetChildren() do
				if drop then
					drop:Destroy()
				end
			end

			if player.gStats.DoubleRebirth.Value == true then
				player.leaderstats.Rebirths.Value += 1
			end
			
			player.leaderstats.Rebirths.Value += 1
			player.gStats.Upgraders.Value = 0
			rebirths += 1
		else
			break
		end
	end
	
	if rebirths > 0 then
		player.leaderstats.Money.Value = 0
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, id: number, wasPurchased: boolean)
	if wasPurchased == nil or wasPurchased == false then return end
	local retry = 0
	local sentWH = false
	
	if id == 1081758798 then
		player.gStats.DoubleMoney.Value = true
	elseif id == 1081335439 then
		player.gStats.DoubleRebirth.Value = true
	elseif id == 1081013553 then
		player.gStats.DoubleTokens.Value = true
	else
		warn("idk this gamepass dawg " .. id)
	end
	
	print("Got player! Sending webhook...")

	local success, err = pcall(function()
		httpService:PostAsync(webhook,
			httpService:JSONEncode({
				content = "@" .. player.Name .. " (" .. tostring(player.UserId) .. ") bought '" .. tostring(MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass).Name) .. "' for " .. emojiId .. " " .. tostring(MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass).PriceInRobux) .. "! (NO PURCHASE ID)"
			})
		)
	end)

	while not success do
		retry += 1
		warn("Webhook send failed. Trying in 1s.")
		task.wait(1)
		local success, err = pcall(function()
			httpService:PostAsync(webhook,
				httpService:JSONEncode({
					content = "@" .. player.Name .. " (" .. tostring(player.UserId) .. ") bought '" .. tostring(MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass).Name) .. "' for " .. emojiId .. " " .. tostring(MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass).PriceInRobux) .. "! (NO PURCHASE ID)"
				})
			)
		end)

		if success then sentWH = true break end
		if retry >= 3 then sentWH = false break end
	end

	if success then
		sentWH = true
		print("Sent webhook. Checking product info now!")
	else
		sentWH = false
		print("Failed to log purchase. Continuing anyway...")
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	for _, tycoon in game.Workspace.Tycoons:GetChildren() do
		if tycoon:GetAttribute("OwnerId") == player.UserId then
			task.wait(0.5)
			local gate = tycoon.Gate.Touch
			gate.Transparency = 0.25
			tycoon:SetAttribute("OwnerId", 0)

			for _, item in tycoon.Items:GetChildren() do
				item:Destroy()
			end

			for _, base in tycoon.Bases:GetChildren() do
				base.Transparency = 0.5
				base:SetAttribute("Reference", "")
				base:SetAttribute("Owned", false)
			end

			for _, drop in tycoon.Drops:GetChildren() do
				if drop then
					drop:Destroy()
				end
			end
		end
	end
end)

task.spawn(function()
	while task.wait(300) do
		giveAllTokens()
	end
end)

game.ReplicatedStorage.Remotes.BuyTimeUpgrade.OnServerEvent:Connect(buyTimeUpgrade)

MarketplaceService.ProcessReceipt = ProcessReceipt