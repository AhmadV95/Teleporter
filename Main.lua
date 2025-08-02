-- // SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Wait for PlayerGui to exist with timeout
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("PlayerGui not found after timeout")
    return
end

-- // VARIABLES
local lastGiftingPlayer = nil
local lastNotificationTime = 0
local cooldownTime = 5 -- seconds between notifications for same player
local processedPrompts = {}

-- // CREATE NOTIFICATION UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GiftNotifier"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Protected call to parent the GUI
local success = pcall(function()
    screenGui.Parent = PlayerGui
end)

if not success then
    warn("Failed to create ScreenGui")
    return
end

-- Main frame with rounded corners
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 80)
frame.Position = UDim2.new(0.5, -140, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Add stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 0)
stroke.Thickness = 2
stroke.Parent = frame

-- Avatar image with rounded corners
local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 60, 0, 60)
avatarImage.Position = UDim2.new(0, 10, 0.5, -30)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatarImage.Parent = frame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(0, 30)
avatarCorner.Parent = avatarImage

-- Text label
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -80, 1, 0)
textLabel.Position = UDim2.new(0, 80, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextSize = 14
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.Text = "Searching for gifts..."
textLabel.Parent = frame

-- // ANIMATION TWEENS
local showTween = TweenService:Create(frame, 
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position = UDim2.new(0.5, -140, 0.8, 0)}
)

local hideTween = TweenService:Create(frame,
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
    {Position = UDim2.new(0.5, -140, 0.85, 0)}
)

-- // FUNCTION: Show Notification with improved error handling
local function showNotification(playerName)
    local currentTime = tick()
    
    -- Cooldown check
    if lastGiftingPlayer == playerName and (currentTime - lastNotificationTime) < cooldownTime then
        return
    end
    
    lastGiftingPlayer = playerName
    lastNotificationTime = currentTime
    
    -- Get avatar with error handling
    spawn(function()
        local success, result = pcall(function()
            local userId = Players:GetUserIdFromNameAsync(playerName)
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size100x100
            return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        end)
        
        if success and result then
            avatarImage.Image = result
        else
            avatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        end
    end)
    
    textLabel.Text = playerName .. " is gifting! 🎁"
    
    -- Show with animation
    frame.Visible = true
    showTween:Play()
    
    -- Hide after delay
    task.delay(4, function()
        hideTween:Play()
        hideTween.Completed:Wait()
        frame.Visible = false
    end)
end

-- // FUNCTION: Safe teleport with collision detection
local function teleportBeside(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    -- Multiple offset positions to try
    local offsets = {
        Vector3.new(5, 0, 0),
        Vector3.new(-5, 0, 0),
        Vector3.new(0, 0, 5),
        Vector3.new(0, 0, -5),
        Vector3.new(3, 0, 3),
        Vector3.new(-3, 0, -3)
    }
    
    for _, offset in ipairs(offsets) do
        local newPosition = targetHRP.Position + offset
        local newCFrame = CFrame.new(newPosition, targetHRP.Position)
        
        -- Check if position is safe (basic check)
        local raycast = workspace:Raycast(newPosition + Vector3.new(0, 10, 0), Vector3.new(0, -15, 0))
        if raycast then
            myHRP.CFrame = newCFrame
            break
        end
    end
end

-- // IMPROVED DETECTION SYSTEM
local connection
connection = RunService.Heartbeat:Connect(function()
    -- Safety check
    if not LocalPlayer.Character then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Look for ProximityPrompts in the character
            for _, descendant in pairs(player.Character:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local promptId = player.Name .. "_" .. descendant:GetDebugId()
                    
                    -- Check if we've already processed this prompt
                    if not processedPrompts[promptId] then
                        -- Check for gift-related text
                        local objectText = descendant.ObjectText or ""
                        local actionText = descendant.ActionText or ""
                        
                        local giftKeywords = {"gift", "present", "reward", "give", "donate"}
                        local isGiftPrompt = false
                        
                        for _, keyword in ipairs(giftKeywords) do
                            if string.find(string.lower(objectText), keyword) or 
                               string.find(string.lower(actionText), keyword) then
                                isGiftPrompt = true
                                break
                            end
                        end
                        
                        if isGiftPrompt then
                            processedPrompts[promptId] = true
                            showNotification(player.Name)
                            teleportBeside(player)
                            
                            -- Clean up processed prompts after delay
                            task.delay(10, function()
                                processedPrompts[promptId] = nil
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- // CLEANUP ON PLAYER LEAVING
Players.PlayerRemoving:Connect(function(player)
    -- Clean up any references to the leaving player
    for promptId, _ in pairs(processedPrompts) do
        if string.find(promptId, player.Name) then
            processedPrompts[promptId] = nil
        end
    end
    
    if lastGiftingPlayer == player.Name then
        lastGiftingPlayer = nil
    end
end)

-- // CLEANUP ON SCRIPT END
game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
    if screenGui then
        screenGui:Destroy()
    end
end)

print("Gift Notifier loaded successfully!")
