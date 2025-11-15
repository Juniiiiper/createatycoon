repeat wait() until game.Players.LocalPlayer:FindFirstChild("gStats")

local Tween = game:GetService("TweenService")
local camera = game.Workspace.CurrentCamera
local mouseOver = require(game.ReplicatedStorage:WaitForChild("MouseOverModule"))

local tweenDeb = false
local deb = false
local tycoon = game.Players.LocalPlayer.gStats.OwnedTycoon
local menu = script.Parent.TycoonMenu.BG

local tweenSpeed = 0.7
local selectedBase = nil
local selectedFilter = "Dropper"

repeat camera.FieldOfView = 80 task.wait() until camera.FieldOfView == 80
repeat task.wait(0.1) until tycoon.Value ~= nil

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

function roundDecimal(num)
	if num == nil then return 0 end
	num *= 100
	num = math.floor(num)
	num /= 100
	return num
end

for _, base in tycoon.Value:WaitForChild("Bases"):GetChildren() do
	if base:IsA("BasePart") then
		base.Prompt.Enabled = true
		
		if base:GetAttribute("Owned") == false then
			base.Prompt.ObjectText = "$" .. abbreviate(base:GetAttribute("Cost"))
			base.Prompt.ActionText = "Buy Spot"
		else
			base.Prompt.ObjectText = "Spot " .. base.Name
			base.Prompt.ActionText = "Select"
		end
		
		base.AttributeChanged:Connect(function()
			if base:GetAttribute("Owned") == false then
				base.Prompt.ObjectText = "$" .. abbreviate(base:GetAttribute("Cost"))
				base.Prompt.ActionText = "Buy Spot"
			else
				base.Prompt.ObjectText = "Spot " .. base.Name
				base.Prompt.ActionText = "Select"
			end
		end)
		
		base.Prompt.Triggered:Connect(function()
			if base:GetAttribute("Owned") == true then
				selectedBase = base
				if menu.Position == UDim2.new(menu.Position.X.Scale, menu.Position.X.Offset, 1.5, menu.Position.Y.Offset) and tweenDeb == false then
					tweenDeb = true
					Tween:Create(menu, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					menu.Visible = true
					task.wait(0.75)
					tweenDeb = false
				end
			else
				selectedBase = base
				if tweenDeb == false and menu.Parent.Base.Position == UDim2.new(menu.Parent.Base.Position.X.Scale, menu.Parent.Base.Position.X.Offset, 1.5, menu.Parent.Base.Position.Y.Offset) then
					menu.Parent.Base.Description.Text = "Are you sure you'd like to buy this spot for $" .. abbreviate(base:GetAttribute("Cost")) .. "?"
					tweenDeb = true
					menu.Visible = true
					Tween:Create(menu.Parent.Base, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					task.wait(0.75)
					tweenDeb = false
				end
			end
		end)
	end
end

for _, item in game.ReplicatedStorage:WaitForChild("Items"):GetChildren() do
	if item:IsA("Model") and item:GetAttribute("ImageId") ~= nil and item:GetAttribute("DisplayName") ~= nil then
		local drops = 0
		local upgType = if item:GetAttribute("UpgradeType") == "Multiply" then "x" else "+$"
		local clone = menu.List.Template:Clone()
		clone.Name = item.Name
		clone.Visible = true
		clone.ItemImage.Image = item:GetAttribute("ImageId")
		clone.ItemName.Text = item:GetAttribute("DisplayName")
		clone.ItemPrice.Text = if item:GetAttribute("Cost") == 0 then "FREE" else "$" .. abbreviate(item:GetAttribute("Cost"))
		clone:SetAttribute("Type", item:GetAttribute("Type"))
		
		local MouseEnter, MouseLeave = mouseOver.MouseEnterLeaveEvent(clone)
		
		if item:GetAttribute("DropPrice") and item:GetAttribute("SpawnRate") then
			for _, drop in item:GetDescendants() do
				if drop:IsA("BasePart") and drop.Name == "Drop" then
					drops += 1
				end
			end
			
			if drops == 0 then drops = 1 end
			clone.LayoutOrder = math.ceil(item:GetAttribute("DropPrice")/item:GetAttribute("SpawnRate"))*drops
			clone.ItemEarn.Text = "$" .. abbreviate(roundDecimal((item:GetAttribute("DropPrice")/item:GetAttribute("SpawnRate"))*drops)) .. "/s"
		else
			clone.ItemEarn.Text = upgType .. item:GetAttribute("Upgrade")
			if upgType == "+$" then
				clone.LayoutOrder = (item:GetAttribute("Upgrade")*10)
			else
				clone.LayoutOrder = item:GetAttribute("Upgrade")*100
			end
		end
		
		MouseEnter:Connect(function()
			if item:GetAttribute("Type") == "Dropper" then
				script.Parent.TycoonMenu.ItemHover.Visible = true
				script.Parent.TycoonMenu.ItemHover.Position = UDim2.new(0, game.Players.LocalPlayer:GetMouse().X+10, 0, game.Players.LocalPlayer:GetMouse().Y+70)
				script.Parent.TycoonMenu.ItemHover.ItemName.Text = item:GetAttribute("DisplayName")

				if item:GetAttribute("DropPrice") then
					script.Parent.TycoonMenu.ItemHover.ItemDrop.Text = "Drop: $" .. abbreviate(roundDecimal(item:GetAttribute("DropPrice")))
				end

				if item:GetAttribute("SpawnRate") then
					script.Parent.TycoonMenu.ItemHover.ItemSpeed.Text = "Speed: " .. item:GetAttribute("SpawnRate") .. "s"
				end

				if item:GetAttribute("SpawnRate") and item:GetAttribute("DropPrice") then
					script.Parent.TycoonMenu.ItemHover.ItemMPS.Text = "Avg: " .. "$" .. abbreviate(roundDecimal((item:GetAttribute("DropPrice")/item:GetAttribute("SpawnRate"))*drops)) .. "/s"
				end
				
				if item:GetAttribute("Cost") then
					script.Parent.TycoonMenu.ItemHover.ItemPrice.Text = if item:GetAttribute("Cost") == 0 then "FREE" else "$" .. abbreviate(item:GetAttribute("Cost"))
				end
			end
		end)

		MouseLeave:Connect(function()
			script.Parent.TycoonMenu.ItemHover.Visible = false
		end)
		
		clone.Parent = menu.List
	end
end

game.Players.LocalPlayer:GetMouse().Move:Connect(function()
	script.Parent.TycoonMenu.ItemHover.Position = UDim2.new(0, game.Players.LocalPlayer:GetMouse().X+10, 0, game.Players.LocalPlayer:GetMouse().Y+70)
end)

menu.Changed:Connect(function()
	for _, frame in menu.List:GetChildren() do
		if frame:IsA("Frame") and frame.Name ~= "Template" then
			if frame:GetAttribute("Type") == selectedFilter then
				frame.Visible = menu.Visible
			end
		end
	end
end)

for _, frame in menu.List:GetChildren() do
	if frame:IsA("Frame") and frame.Name ~= "Template" then
		frame.Button.Activated:Connect(function()
			if not selectedBase or deb == true then return end
			deb = true
			game.ReplicatedStorage.Remotes.ChangeItem:FireServer(frame.Name, selectedBase)
			tweenDeb = true
			Tween:Create(menu, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
			task.wait(0.75)
			menu.Visible = false
			tweenDeb = false
			deb = false
		end)
	end
end

for _, model in tycoon.Value.Conveyors:GetChildren() do
	if model:FindFirstChild("Conveyor") then
		model.Conveyor.Changed:Connect(function()
			if math.abs(model.Conveyor.AssemblyLinearVelocity.X) > 5+game.Players.LocalPlayer.gStats.TimeUpgrades:FindFirstChild(model.Name).Value then
				game.Players.LocalPlayer:Kick("An unknown error occured. Code A1")
			end
		end)
	end
end

for _, item in menu.List:GetChildren() do
	if item:IsA("Frame") and item.Name ~= "Template" then
		local itemType = item:GetAttribute("Type")

		if itemType and itemType == "Dropper" then
			item.Visible = true
		else
			item.Visible = false
		end
	end
end

tycoon.Value.Rebirth.BillboardGui.Enabled = true

menu.Parent.Base.Confirm.Activated:Connect(function()
	if tweenDeb == false then
		tweenDeb = true
		game.ReplicatedStorage.Remotes.BuyBase:FireServer(selectedBase)
		Tween:Create(menu.Parent.Base, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		task.wait(0.75)
		tweenDeb = false
	end
end)

menu.Parent.Base.Cancel.Activated:Connect(function()
	if tweenDeb == false then
		tweenDeb = true
		Tween:Create(menu.Parent.Base, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		task.wait(0.75)
		tweenDeb = false
	end
end)

menu.Close.Activated:Connect(function()
	if menu.Position == UDim2.new(menu.Position.X.Scale, menu.Position.X.Offset, 0.5, menu.Position.Y.Offset) and tweenDeb == false then
		tweenDeb = true
		Tween:Create(menu, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		task.wait(0.75)
		menu.Visible = false
		tweenDeb = false
	end
end)

menu.Close.MouseEnter:Connect(function()
	Tween:Create(menu.Close, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false), {Rotation = 0}):Play()
end)

menu.Close.MouseLeave:Connect(function()
	Tween:Create(menu.Close, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false), {Rotation = 7}):Play()
end)

menu.DropperFilter.Activated:Connect(function()
	if selectedFilter ~= "Dropper" then
		selectedFilter = "Dropper"
		
		for _, item in menu.List:GetChildren() do
			if item:IsA("Frame") and item.Name ~= "Template" then
				local itemType = item:GetAttribute("Type")
				
				if itemType and itemType == "Dropper" then
					item.Visible = true
				else
					item.Visible = false
				end
			end
		end
	end
end)

menu.UpgraderFilter.Activated:Connect(function()
	if selectedFilter ~= "Upgrader" then
		selectedFilter = "Upgrader"

		for _, item in menu.List:GetChildren() do
			if item:IsA("Frame") and item.Name ~= "Template" then
				local itemType = item:GetAttribute("Type")

				if itemType and itemType == "Upgrader" then
					item.Visible = true
				else
					item.Visible = false
				end
			end
		end
	end
end)

game:GetService("RunService").RenderStepped:Connect(function(delta)
	for _, v in pairs(game.Workspace:GetDescendants()) do
		if v.Name == "Conveyor" or v.Name == "conveyor" then
			local conveyorTexture = v.Texture
			conveyorTexture.OffsetStudsV = conveyorTexture.OffsetStudsV - delta * v:GetAttribute("Speed")
		end
	end
end)