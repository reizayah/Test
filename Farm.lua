local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

print("Script starting...")
print("Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-02-17 07:38:26")

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

Players.LocalPlayer.OnTeleport:Connect(function(State)
    if (not TeleportCheck) and queueteleport then
        TeleportCheck = true
        queueteleport([[
            task.wait(5) -- Wait for game to load
            repeat task.wait() until game:IsLoaded()
            repeat task.wait() until game.Players.LocalPlayer
            repeat task.wait() until game.Players.LocalPlayer.Character
            repeat task.wait() until game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid")
            
            loadstring(game:HttpGet('https://raw.githubusercontent.com/reizayah/Test/refs/heads/main/Farm.lua'))()
        ]])
    end
end)

local function waitForCharacter()
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        player.CharacterAdded:Wait()
        player.Character:WaitForChild("Humanoid")
    end
    return player.Character
end
-- Handle loading screen first
local function handleLoadingScreen()
    print("Waiting for loading screen...")
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 10)
    local loadScreen = playerGui:WaitForChild("BronxLoadscreen", 10)
    if loadScreen then
        print("Found loading screen, replicating play button sequence...")
        
        if game.ReplicatedStorage:FindFirstChild("Beat") then
            game.ReplicatedStorage.Beat:Stop()
        end
        
        if workspace:FindFirstChild("INTRO_ASSETS") then
            for _, child in pairs(workspace.INTRO_ASSETS:GetChildren()) do
                child:Destroy()
            end
        end
        
        if game.Lighting:FindFirstChild("IntroBlur") then
            game.Lighting.IntroBlur.Enabled = false
        end
        
        if not game.ReplicatedStorage:FindFirstChild("INTRO") then
            local introFlag = Instance.new("NumberValue")
            introFlag.Name = "INTRO"
            introFlag.Parent = game.ReplicatedStorage
        end
        
        -- Wait for character before setting camera
        local character = waitForCharacter()
        local humanoid = character:WaitForChild("Humanoid")
        
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
        
        local PlayerGui = player.PlayerGui
        local UIs = {
            "MoneyGui",
            "Hunger",
            "Run",
            "HealthGui",
            "SleepGui"
        }
        
        for _, ui in pairs(UIs) do
            if PlayerGui:FindFirstChild(ui) then
                PlayerGui[ui].Enabled = true
            end
        end
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "ToolText" then
                v.Visible = true
            end
        end
        
        loadScreen:Destroy()
        
        if game.ReplicatedStorage:FindFirstChild("SpawnCharacter") then
            game.ReplicatedStorage.SpawnCharacter:FireServer()
        end
        
        task.wait(2)
        return true
    else
        print("Warning: Loading screen not found!")
        return false
    end
end

local function initializeMoneyModels()
    local maxAttempts = 10
    local attempts = 0
    
    while attempts < maxAttempts do
        if Workspace:FindFirstChild("StudioPay") and 
           Workspace.StudioPay:FindFirstChild("Money") then
            local studioPayFolder = Workspace.StudioPay.Money
            if studioPayFolder:FindFirstChild("StudioPay1") and
               studioPayFolder:FindFirstChild("StudioPay2") and
               studioPayFolder:FindFirstChild("StudioPay3") then
                return {
                    studioPayFolder.StudioPay1,
                    studioPayFolder.StudioPay2,
                    studioPayFolder.StudioPay3
                }
            end
        end
        attempts = attempts + 1
        task.wait(1)
    end
    return nil
end

-- Handle loading screen before proceeding
if not handleLoadingScreen() then
    print("Failed to handle loading screen!")
    return
end

local moneyModels = initializeMoneyModels()
if not moneyModels then
    print("Failed to initialize money models!")
    return
end
-- Get all StudioPay models
local studioPayFolder = Workspace.StudioPay.Money
local moneyModels = {
    studioPayFolder.StudioPay1,
    studioPayFolder.StudioPay2,
    studioPayFolder.StudioPay3
}

-- Configuration
local tweenInfo = TweenInfo.new(
    4, -- Duration
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.Out
)

-- Server hop configuration
local CHECKS_BEFORE_HOP = 10 -- Number of empty checks before server hop
local emptyChecks = 0
local lastServerHop = 0
local SERVER_HOP_COOLDOWN = 30 -- Seconds between server hop attempts
local lastServerCheck = 0
local SERVER_CHECK_COOLDOWN = 5 -- Seconds between server list checks

-- Tracking variables
local isProcessingMoney = false
local currentMoneyPart = nil

-- Function to get server list
local function getServers()
    local currentTime = tick()
    if currentTime - lastServerCheck < SERVER_CHECK_COOLDOWN then
        return {} -- Return empty if checking too frequently
    end
    lastServerCheck = currentTime
    
    local placeId = game.PlaceId
    local servers = {}
    local continuation = nil
    local success, result = pcall(function()
        local response = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"
            ..(continuation and "&cursor="..continuation or "")
        ))
        return response
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    return servers
end

-- Function to server hop
local function serverHop()
    local currentTime = tick()
    if currentTime - lastServerHop < SERVER_HOP_COOLDOWN then
        print("Server hop on cooldown. Waiting " .. math.floor(SERVER_HOP_COOLDOWN - (currentTime - lastServerHop)) .. " seconds...")
        return
    end
    
    if currentTime - lastServerCheck < SERVER_CHECK_COOLDOWN then
        print("Server check on cooldown. Waiting " .. math.floor(SERVER_CHECK_COOLDOWN - (currentTime - lastServerCheck)) .. " seconds...")
        return
    end
    
    print("Attempting to server hop...")
    local servers = getServers()
    
    if #servers > 0 then
        lastServerHop = currentTime
        local randomServer = servers[math.random(1, #servers)]
        print("Teleporting to server:", randomServer)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer)
    else
        print("No suitable servers found or rate limit hit. Will retry later.")
    end
end

-- Force Server Hop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        print("Force server hop triggered by user")
        -- Reset cooldowns to allow immediate hop
        lastServerHop = 0
        lastServerCheck = 0
        -- Call server hop
        serverHop()
    end
end)

-- Function to check for any visible money
local function isAnyMoneyVisible()
    for _, model in ipairs(moneyModels) do
        local moneyPart = model:FindFirstChild("StudioMoney1")
        if moneyPart and moneyPart.Transparency == 0 then
            return true
        end
    end
    return false
end

-- Function to check if player is in correct position
local function isPlayerInCorrectPosition(character, targetPosition)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude
    return distance <= 5
end

-- Function to tween to position
local function tweenToPosition(character, targetPosition)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local tween = TweenService:Create(
        humanoidRootPart,
        tweenInfo,
        {CFrame = CFrame.new(targetPosition)}
    )
    tween:Play()
    return tween
end

-- Function to wait for money collection
local function waitForMoneyCollection(moneyPart)
    local startTime = tick()
    local maxWaitTime = 3 -- Wait 3 seconds for collection
    
    while moneyPart and moneyPart.Parent and moneyPart.Transparency == 0 do
        if tick() - startTime > maxWaitTime then
            return false -- Collection failed
        end
        task.wait(0.1)
    end
    return true -- Collection successful
end

--Function to check for the prompt
local function waitForMoneyPrompt(moneyPart, maxWaitTime)
    maxWaitTime = maxWaitTime or 5 -- Default 5 seconds wait time
    local startTime = tick()
    
    -- Check if money is still valid and visible
    while moneyPart and moneyPart.Parent and moneyPart.Transparency == 0 and (tick() - startTime) < maxWaitTime do
        local prompt = moneyPart:FindFirstChild("Prompt")
        if prompt then
            return prompt
        end
        task.wait(0.1)
    end
    
    return nil
end

-- Function to handle visible money
local function handleVisibleMoney(moneyPart)
    if isProcessingMoney then return end
    
    isProcessingMoney = true
    currentMoneyPart = moneyPart
    
    -- Use the helper function to wait for prompt
    local prompt = waitForMoneyPrompt(moneyPart)
    if prompt then
        -- Set hold duration to 0
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            local maxAttempts = 3 -- Maximum number of collection attempts
            local attempts = 0
            
            while attempts < maxAttempts do
                attempts = attempts + 1
                
                -- Recheck prompt before each attempt
                prompt = waitForMoneyPrompt(moneyPart, 2) -- Shorter timeout for rechecks
                if not prompt then
                    print("Lost prompt during collection attempt")
                    break
                end
                
                -- Tween to money
                local tween = tweenToPosition(character, moneyPart.Position)
                tween.Completed:Wait()
                task.wait(0.5)
                
                -- Check position and try to collect
                if isPlayerInCorrectPosition(character, moneyPart.Position) then
                    prompt:InputHoldBegin()
                    getgenv().AutoFarm = true
                    
                    local collected = waitForMoneyCollection(moneyPart)
                    if collected then
                        print("Money collected successfully!")
                        emptyChecks = 0 -- Reset empty checks counter on successful collection
                        break -- Exit the retry loop
                    else
                        print("Collection attempt " .. attempts .. " failed, retrying...")
                        task.wait(0.5) -- Wait before next attempt
                    end
                else
                    print("Not in correct position, attempt " .. attempts .. ", retrying...")
                    task.wait(0.5) -- Wait before next attempt
                end
                
                -- If money is no longer visible, break the loop
                if not moneyPart or not moneyPart.Parent or moneyPart.Transparency ~= 0 then
                    break
                end
            end
            
            if attempts >= maxAttempts then
                print("Failed to collect money after " .. maxAttempts .. " attempts")
            end
        end
    else
        print("No prompt found after waiting - skipping this money part")
    end
    
    isProcessingMoney = false
    currentMoneyPart = nil
end

-- Main loop
local function checkAllMoney()
    if isProcessingMoney then return end
    
    if not isAnyMoneyVisible() then
        emptyChecks = emptyChecks + 1
        if emptyChecks >= CHECKS_BEFORE_HOP then
            print("No money found after", CHECKS_BEFORE_HOP, "checks, server hopping...")
            serverHop()
            emptyChecks = 0
        end
        return
    end
    
    for _, model in ipairs(moneyModels) do
        local moneyPart = model:FindFirstChild("StudioMoney1")
        if moneyPart and moneyPart.Transparency == 0 then
            handleVisibleMoney(moneyPart)
            break
        end
    end
end

-- Set up continuous checking
RunService.Heartbeat:Connect(function()
    checkAllMoney()
end)

-- Handle teleport errors
TeleportService.TeleportInitFailed:Connect(function()
    task.wait(SERVER_HOP_COOLDOWN)
    serverHop()
end)

print("Script initialization complete!")
