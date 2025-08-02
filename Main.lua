-- // SERVICES
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- // LOCAL PLAYER
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- // CREATE NOTIFICATION GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GiftNotification"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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

	-- Hide after 3 seconds
	task.delay(3, function()
		frame.Visible = false
	end)
end

-- // FUNCTION: Teleport beside player
local function teleportBeside(targetPlayer)
	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local myChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hrp = myChar:FindFirstChild("HumanoidRootPart")
	if hrp then
		local offset = Vector3.new(3, 0, 0) -- 3 studs to the side
		hrp.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position + offset)
	end
end

-- // DETECT GIFTING
ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	-- Ignore if local player triggered it themselves
	if playerWhoTriggered == localPlayer then return end

	-- Check if prompt is related to gifting
	if prompt.ObjectText and string.lower(prompt.ObjectText):find("gift") then
		showNotification(playerWhoTriggered.Name)
		teleportBeside(playerWhoTriggered)
	end
end)
