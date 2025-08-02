-- // SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Wait for PlayerGui to exist (important for Delta)
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

-- // CREATE NOTIFICATION UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GiftNotifier"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 100)
frame.Position = UDim2.new(0.5, -125, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 80, 0, 80)
avatarImage.Position = UDim2.new(0, 10, 0.5, -40)
avatarImage.BackgroundTransparency = 1
avatarImage.Parent = frame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -100, 1, 0)
textLabel.Position = UDim2.new(0, 100, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextScaled = true
textLabel.Text = "Player gifting detected"
textLabel.Parent = frame

-- // FUNCTION: Show Notification
local function showNotification(playerName)
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(playerName)
	end)

	if success and userId then
		local thumb, ready = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ready then
			avatarImage.Image = thumb
		end
	end

	textLabel.Text = playerName .. " is gifting!"
	frame.Visible = true

	task.delay(3, function()
		frame.Visible = false
	end)
end

-- // FUNCTION: Teleport beside player
local function teleportBeside(targetPlayer)
	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = myChar:FindFirstChild("HumanoidRootPart")
	if hrp then
		local offset = Vector3.new(3, 0, 0) -- 3 studs beside
		hrp.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position + offset)
	end
end

-- // DETECT GIFTING LOOP
RunService.Heartbeat:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local prompt = plr.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and prompt.ObjectText and string.lower(prompt.ObjectText):find("gift") then
				showNotification(plr.Name)
				teleportBeside(plr)
			end
		end
	end
end)
