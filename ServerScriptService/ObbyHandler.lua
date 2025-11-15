local map = game.Workspace:WaitForChild("Map")
local reward1 = map:WaitForChild("Reward")
local reward2 = map:WaitForChild("Reward2")

local obbyCooldown = {}
local obbyTick = {}
local plrDeb = {}
local rewardDeb = {}

function reward(hit, reward)
	if hit.Parent:FindFirstChild("HumanoidRootPart") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)

		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if rewardDeb[player.UserId] == true then return end
			
			if obbyCooldown[player.UserId] == false then
				player.Character.HumanoidRootPart.CFrame = game.Workspace.ObbyTP.CFrame
				rewardDeb[player.UserId] = true
				plrDeb[player.UserId] = false
				obbyCooldown[player.UserId] = true
				
				if tick() - obbyTick[player.UserId] < 3 then
					player:Kick("An error occured rewarding obby boost. Error: A3")
				end
				
				if player then
					game.ReplicatedStorage.Remotes.ObbyCooldown:FireClient(player)
					task.wait(1)
					rewardDeb[player.UserId] = false
					player.gStats.Boosts:FindFirstChild("2").Value += reward
					task.wait(599)
					obbyCooldown[player.UserId] = false
				end
			else
				player:Kick("An error occured awarding boost. Error: A2")
			end
		end
	end
end

game.Workspace.Lava.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		if player then
			plrDeb[player.UserId] = false
		end
	end
end)

map.CooldownGate.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		if player then
			if plrDeb[player.UserId] == true then return end
			plrDeb[player.UserId] = true
			obbyTick[player.UserId] = tick()
		end
	end
end)

reward1.Touched:Connect(function(hit)
	reward(hit, reward1:GetAttribute("2"))
end)

reward2.Touched:Connect(function(hit)
	reward(hit, reward2:GetAttribute("2"))
end)

game.Players.PlayerAdded:Connect(function(player)
	obbyCooldown[player.UserId] = false
	obbyTick[player.UserId] = 0
	plrDeb[player.UserId] = false
	rewardDeb[player.UserId] = false
end)

game.Players.PlayerRemoving:Connect(function(player)
	obbyCooldown[player.UserId] = nil
	obbyTick[player.UserId] = nil
	plrDeb[player.UserId] = nil
	rewardDeb[player.UserId] = nil
end)