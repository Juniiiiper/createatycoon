repeat wait() until script.Parent:FindFirstChild("HumanoidRootPart")

if script:FindFirstChild("Trail") then
	repeat wait() until game.Players.LocalPlayer:FindFirstChild("gStats")
	local attachment = Instance.new("Attachment")
	local trail = script.Trail
	attachment.Parent = script.Parent.HumanoidRootPart
	attachment.Name = "BeamAttatch"
	trail.Parent = script.Parent.HumanoidRootPart
	
	if game.Players.LocalPlayer.gStats.OwnedTycoon.Value == nil then
		for _, folder in game.Workspace.Tycoons:GetChildren() do
			if folder:IsA("Folder") then
				if folder:GetAttribute("OwnerId") == 0 then
					if folder:FindFirstChild("Gate") then
						if folder.Gate:FindFirstChild("Touch") then
							local att = Instance.new("Attachment")
							att.Parent = folder.Gate.Touch
							trail.Attachment0 = attachment
							trail.Attachment1 = att
							break
						end
					end
				end
			end
		end
		
		game.Players.LocalPlayer:FindFirstChild("gStats").OwnedTycoon.Changed:Connect(function()
			if game.Players.LocalPlayer:FindFirstChild("gStats").OwnedTycoon.Value ~= nil then
				local att = Instance.new("Attachment")
				att.Parent = game.Players.LocalPlayer:FindFirstChild("gStats").OwnedTycoon.Value.Bases["1"]
				trail.Attachment1 = att
				game.Players.LocalPlayer:FindFirstChild("gStats").OwnedTycoon.Value.Bases["1"].Prompt.Triggered:Connect(function()
					trail.Enabled = false
				end)
			end
		end)
	end
end