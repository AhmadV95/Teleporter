-- // PREDICTIVE GIFTING SYSTEM
local function setupPredictiveDetection()
    -- Monitor player movements and behavior patterns
    local function analyzePlayerBehavior(player)
        if not player.Character then return end
        
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not hrp then return end
        
        -- Check if player stops moving (potential gift setup)
        if humanoid.MoveDirection.Magnitude < 0.1 then
            if not predictiveTracking[player.Name] then
                predictiveTracking[player.Name] = {
                    stoppedTime = tick(),
                    position = hrp.Position,
                    hasGiftItems = false,
                    chatIndicator = false
                }
            else
                local data = predictiveTracking[player.Name]
                local stationaryTime = tick() - data.stoppedTime
                
                -- If player has been stationary for 2+ seconds, check for gift indicators
                if stationaryTime >= 2 then
                    -- Check for gift-related items in backpack/character
                    local hasGiftItems = false
                    
                    -- Check backpack for gift items
                    if player:FindFirstChild("Backpack") then
                        for _, item in pairs(player.Backpack:GetChildren()) do
                            if item:IsA("Tool") then
                                local itemName = string.lower(item.Name)
                                if string.find(itemName, "gift") or string.find(itemName, "present") or 
                                   string.find(itemName, "reward") or string.find(itemName, "prize") then
                                    hasGiftItems = true
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Check character for gift items
                    for _, item in pairs(character:GetChildren()) do
                        if item:IsA("Tool") then
                            local itemName = string.lower(item.Name)
                            if string.find(itemName, "gift") or string.find(itemName, "present") or 
                               string.find(itemName, "reward") or string.find(itemName, "prize") then
                                hasGiftItems = true
                                break
                            end
                        end
                    end
                    
                    data.hasGiftItems = hasGiftItems
                    
                    -- PREDICTIVE TELEPORT: If player shows gift indicators
                    if (hasGiftItems or data.chatIndicator) and stationaryTime >= 3 then
                        print("🔮 PREDICTIVE GIFTING DETECTED: " .. player.Name .. " is likely about to gift!")
                        
                        -- Update search GUI
                        searchLabel.Text = "🔮 Predicting gift from " .. player.Name
                        searchStroke.Color = Color3.fromRGB(255, 0, 255) -- Purple for prediction
                        
                        -- Predictive teleport
                        teleportToGiftingPlayer(player)
                        showNotification(player.Name .. " (Predicted)")
                        
                        -- Clear prediction data
                        predictiveTracking[player.Name] = nil
                    end
                end
            end
        else
            -- Player is moving, clear tracking
            predictiveTracking[player.Name] = nil
        end
    end
    
    -- Monitor chat for gift announcements
    local function setupChatMonitoring()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not chatConnections[player.Name] then
                chatConnections[player.Name] = player.Chatted:Connect(function(message)
                    local lowerMessage = string.lower(message)
                    
                    -- Check for gift-related keywords in chat
                    for _, keyword in ipairs(giftPredictionKeywords) do
                        if string.find(lowerMessage, keyword) then
                            print("💬 CHAT GIFT INDICATOR: " .. player.Name .. " said: " .. message)
                            
                            -- Mark player as likely to gift
                            if not predictiveTracking[player.Name] then
                                predictiveTracking[player.Name] = {}
                            end
                            predictiveTracking[player.Name].chatIndicator = true
                            predictiveTracking[player.Name].chatTime = tick()
                            
                            -- Update GUI
                            searchLabel.Text = "💬 " .. player.Name .. " mentioned gifting!"
                            searchStroke.Color = Color3.fromRGB(255, 255, 0) -- Yellow for chat indicator
                            
                            -- If they're also stationary, immediate prediction
                            if player.Character and player.Character:FindFirstChild("Humanoid") then
                                local humanoid = player.Character.Humanoid
                                if humanoid.MoveDirection.Magnitude < 0.1 then
                                    task.wait(1) -- Brief delay
                                    print("🚀 IMMEDIATE PREDICTIVE TELEPORT: " .. player.Name)
                                    teleportToGiftingPlayer(player)
                                    showNotification(player.Name .. " (Chat Predicted)")
                                end
                            end
                            
                            break
                        end
                    end
                    
                    -- Clear chat indicator after 30 seconds
                    task.delay(30, function()
                        if predictiveTracking[player.Name] then
                            predictiveTracking[player.Name].chatIndicator = false
                        end
                    end)
                end)
            end
        end
    end
    
    -- Setup new player connections
    Players.PlayerAdded:Connect(function(player)
        task.wait(1) -- Wait for player to load
        if player ~= LocalPlayer then
            chatConnections[player.Name] = player.Chatted:Connect(function(message)
                local lowerMessage = string.lower(message)
                
                for _, keyword in ipairs(giftPredictionKeywords) do
                    if string.find(lowerMessage, keyword) then
                        print("💬 NEW PLAYER GIFT INDICATOR: " .. player.Name)
                        
                        if not predictiveTracking[player.Name] then
                            predictiveTracking[player.Name] = {}
                        end
                        predictiveTracking[player.Name].chatIndicator = true
                        predictiveTracking[player.Name].chatTime = tick()
                        
                        searchLabel.Text = "💬 " .. player.Name .. " mentioned gifting!"
                        searchStroke.Color = Color3.fromRGB(255, 255, 0)
                        break
                    end
                end
            end)
        end
    end)
    
    -- Cleanup when players leave
    Players.PlayerRemoving:Connect(function(player)
        if chatConnections[player.Name] then
            chatConnections[player.Name]:Disconnect()
            chatConnections[player.Name] = nil
        end
        predictiveTracking[player.Name] = nil
    end)
    
    -- Run behavior analysis
    spawn(function()
        while true do
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    analyzePlayerBehavior(player)
                end
            end
            task.wait(0.5)
        end
    end)
    
    -- Initialize chat monitoring for existing players
    setupChatMonitoring()
end

-- // FUNCTION: Teleport to exact same position (optimized for instant response)
local function teleportToGiftingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    -- Teleport to EXACT same position
    myHRP.CFrame = targetHRP.CFrame
    
    print("🎯 Teleported to player: " .. targetPlayer.Name .. " at exact position!")
    
    -- Track this player
    activeGiftingPlayers[targetPlayer.Name] = {
        player = targetPlayer,
        timestamp = tick(),
        isInstant = true
    }
end

-- // FUNCTION: Auto-accept gifts
local function setupGiftAutoAccept()
    -- Monitor for gift prompts that appear for the local player
    local function checkForGiftPrompts()
        if LocalPlayer.Character then
            for _, descendant in pairs(LocalPlayer.Character:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local objectText = string.lower(descendant.ObjectText or "")
                    local actionText = string.lower(descendant.ActionText or "")
                    
                    -- Check if this is a gift acceptance prompt
                    local giftAcceptKeywords = {"accept", "claim", "take", "receive", "get"}
                    local isGiftAcceptPrompt = false
                    
                    for _, keyword in ipairs(giftAcceptKeywords) do
                        if string.find(objectText, keyword) or string.find(actionText, keyword) then
                            isGiftAcceptPrompt = true
                            break
                        end
                    end
                    
                    if isGiftAcceptPrompt then
                        print("Auto-accepting gift!")
                        descendant:InputHoldBegin()
                        task.wait(0.1)
                        descendant:InputHoldEnd()
                        
                        -- Update search GUI
                        searchLabel.Text = "🎁 Gift auto-accepted!"
                        searchStroke.Color = Color3.fromRGB(0, 255, 255)
                        
                        task.delay(2, function()
                            searchLabel.Text = "🔍 Searching for gifts on server..."
                            searchStroke.Color = Color3.fromRGB(255, 165, 0)
                        end)
                    end
                end
            end
        end
    end
    
    -- Also check PlayerGui for gift acceptance prompts
    local function checkPlayerGuiForGifts()
        for _, gui in pairs(PlayerGui:GetDescendants()) do
            if gui:IsA("ProximityPrompt") then
                local objectText = string.lower(gui.ObjectText or "")
                local actionText = string.lower(gui.ActionText or "")
                
                local giftAcceptKeywords = {"accept", "claim", "take", "receive", "get"}
                local isGiftAcceptPrompt = false
                
                for _, keyword in ipairs(giftAcceptKeywords) do
                    if string.find(objectText, keyword) or string.find(actionText, keyword) then
                        isGiftAcceptPrompt = true
                        break
                    end
                end
                
                if isGiftAcceptPrompt then
                    print("Auto-accepting gift from GUI!")
                    gui:InputHoldBegin()
                    task.wait(0.1)
                    gui:InputHoldEnd()
                end
            end
        end
    end
    
    -- Run checks continuously
    spawn(function()
        while true do
            checkForGiftPrompts()
            checkPlayerGuiForGifts()
            task.wait(0.5)
        end
    end)
end

-- Start auto-accept system
setupGiftAutoAccept()-- // SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Wait for PlayerGui to exist with timeout
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("PlayerGui not found after timeout")
    return
end

-- // VARIABLES
local lastGiftingPlayer = nil
local lastNotificationTime = 0
local cooldownTime = 2 -- Reduced cooldown for faster response
local processedPrompts = {}
local isDragging = false
local dragStart = nil
local startPos = nil
local activeGiftingPlayers = {}
local giftAcceptConnections = {}
local hasDetectedGifting = false
local instantTeleportConnections = {}
local promptActivationConnections = {}

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

-- // SEARCHING GUI
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(0, 200, 0, 60)
searchFrame.Position = UDim2.new(0, 20, 0, 20)
searchFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
searchFrame.BorderSizePixel = 0
searchFrame.Active = true
searchFrame.Draggable = true
searchFrame.Parent = screenGui

-- Add rounded corners to search frame
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchFrame

-- Add stroke to search frame
local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(255, 165, 0)
searchStroke.Thickness = 2
searchStroke.Parent = searchFrame

-- Search status label
local searchLabel = Instance.new("TextLabel")
searchLabel.Size = UDim2.new(1, -10, 1, 0)
searchLabel.Position = UDim2.new(0, 5, 0, 0)
searchLabel.BackgroundTransparency = 1
searchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
searchLabel.Font = Enum.Font.GothamBold
searchLabel.TextSize = 12
searchLabel.TextWrapped = true
searchLabel.Text = "🔍 Searching for gifts on server..."
searchLabel.Parent = searchFrame

-- Animated dots for searching effect
local dots = ""
spawn(function()
    while true do
        for i = 1, 3 do
            dots = dots .. "."
            searchLabel.Text = "🔍 Searching for gifts on server" .. dots
            wait(0.5)
        end
        dots = ""
        searchLabel.Text = "🔍 Searching for gifts on server"
        wait(0.5)
    end
end)

-- // MAIN NOTIFICATION FRAME
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 80)
frame.Position = UDim2.new(0.5, -140, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true
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
textLabel.Text = "Gift detected!"
textLabel.Parent = frame

-- // DRAG FUNCTIONALITY FOR NOTIFICATION FRAME
local function updateInput(input)
    local delta = input.Position - dragStart
    local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    frame.Position = newPosition
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if isDragging then
            updateInput(input)
        end
    end
end)

-- // ANIMATION TWEENS
local showTween = TweenService:Create(frame, 
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.new(0, 280, 0, 80)}
)

local hideTween = TweenService:Create(frame,
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
    {Size = UDim2.new(0, 280, 0, 0)}
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

-- // FUNCTION: Auto-accept gifts
local function setupGiftAutoAccept()
    -- Monitor for gift prompts that appear for the local player
    local function checkForGiftPrompts()
        if LocalPlayer.Character then
            for _, descendant in pairs(LocalPlayer.Character:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local objectText = string.lower(descendant.ObjectText or "")
                    local actionText = string.lower(descendant.ActionText or "")
                    
                    -- Check if this is a gift acceptance prompt
                    local giftAcceptKeywords = {"accept", "claim", "take", "receive", "get"}
                    local isGiftAcceptPrompt = false
                    
                    for _, keyword in ipairs(giftAcceptKeywords) do
                        if string.find(objectText, keyword) or string.find(actionText, keyword) then
                            isGiftAcceptPrompt = true
                            break
                        end
                    end
                    
                    if isGiftAcceptPrompt then
                        print("Auto-accepting gift!")
                        descendant:InputHoldBegin()
                        task.wait(0.1)
                        descendant:InputHoldEnd()
                        
                        -- Update search GUI
                        searchLabel.Text = "🎁 Gift auto-accepted!"
                        searchStroke.Color = Color3.fromRGB(0, 255, 255)
                        
                        task.delay(2, function()
                            searchLabel.Text = "🔍 Searching for gifts on server..."
                            searchStroke.Color = Color3.fromRGB(255, 165, 0)
                        end)
                    end
                end
            end
        end
    end
    
    -- Also check PlayerGui for gift acceptance prompts
    local function checkPlayerGuiForGifts()
        for _, gui in pairs(PlayerGui:GetDescendants()) do
            if gui:IsA("ProximityPrompt") then
                local objectText = string.lower(gui.ObjectText or "")
                local actionText = string.lower(gui.ActionText or "")
                
                local giftAcceptKeywords = {"accept", "claim", "take", "receive", "get"}
                local isGiftAcceptPrompt = false
                
                for _, keyword in ipairs(giftAcceptKeywords) do
                    if string.find(objectText, keyword) or string.find(actionText, keyword) then
                        isGiftAcceptPrompt = true
                        break
                    end
                end
                
                if isGiftAcceptPrompt then
                    print("Auto-accepting gift from GUI!")
                    gui:InputHoldBegin()
                    task.wait(0.1)
                    gui:InputHoldEnd()
                end
            end
        end
    end
    
    -- Run checks continuously
    spawn(function()
        while true do
            checkForGiftPrompts()
            checkPlayerGuiForGifts()
            task.wait(0.5)
        end
    end)
end

-- Start auto-accept system
setupGiftAutoAccept()

-- // ENHANCED DETECTION SYSTEM - Instant Action Response + Backup Detection
local connection
connection = RunService.Heartbeat:Connect(function()
    -- Safety check
    if not LocalPlayer.Character then return end
    
    -- Backup detection system (in case instant detection misses something)
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
                        
                        local giftKeywords = {"gift", "present", "reward", "give", "donate", "free"}
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
                            hasDetectedGifting = true
                            
                            -- Show notification
                            showNotification(player.Name)
                            
                            -- BACKUP teleport (if instant detection didn't trigger)
                            if not activeGiftingPlayers[player.Name] then
                                print("🔄 BACKUP DETECTION! Teleporting to: " .. player.Name)
                                teleportToGiftingPlayer(player)
                                
                                -- Update search GUI
                                searchLabel.Text = "🔄 Backup teleport → " .. player.Name
                                searchStroke.Color = Color3.fromRGB(255, 165, 0)
                            end
                            
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

-- Start instant action detection
setupInstantActionDetection()

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

print("🔮 Predictive Gift Notifier loaded! Now predicting and detecting gifts...")
