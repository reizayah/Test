local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

print("Script starting...")
print("Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-02-18 23:10:35")
print("Current User's Login: reizayah")
print("Press 'K' to force server hop")

local LoggingEnabled = true

local function debugLog(message)
    if LoggingEnabled then
        print(string.format("[%s] %s", os.date("%H:%M:%S"), message))
    end
end

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

Players.LocalPlayer.OnTeleport:Connect(function(State)
    if (not TeleportCheck) and queueteleport then
        TeleportCheck = true
        queueteleport([[
            task.wait(5)
            repeat task.wait() until game:IsLoaded()
            repeat task.wait() until game.Players.LocalPlayer
            repeat task.wait() until game.Players.LocalPlayer.Character
            repeat task.wait() until game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid")
            
            loadstring(game:HttpGet('https://raw.githubusercontent.com/reizayah/Test/refs/heads/main/Farm2.lua'))()
        ]])
    end
end)

-- Add force server hop key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        debugLog("Force server hop triggered by user")
        serverHop()
    end
end)

local function waitForCharacter()
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        debugLog("Waiting for character...")
        player.CharacterAdded:Wait()
        player.Character:WaitForChild("Humanoid")
    end
    debugLog("Character loaded")
    return player.Character
end

local function handleLoadingScreen()
    debugLog("Waiting for loading screen...")
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 10)
    local loadScreen = playerGui:WaitForChild("BronxLoadscreen", 10)
    if loadScreen then
        debugLog("Found loading screen, handling sequence...")
        
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
        debugLog("Loading screen handled successfully")
        return true
    else
        debugLog("Warning: Loading screen not found!")
        return false
    end
end

local function initializeMoneyModels()
    local maxAttempts = 10
    local attempts = 0
    
    debugLog("Starting money models initialization...")
    
    while attempts < maxAttempts do
        if not Workspace:FindFirstChild("StudioPay") then
            debugLog("Waiting for StudioPay folder... Attempt " .. attempts)
            attempts = attempts + 1
            task.wait(1)
            continue
        end
        
        if not Workspace.StudioPay:FindFirstChild("Money") then
            debugLog("Waiting for Money folder... Attempt " .. attempts)
            attempts = attempts + 1
            task.wait(1)
            continue
        end
        
        local studioPayFolder = Workspace.StudioPay.Money
        
        -- Check each model individually
        local models = {
            studioPayFolder:WaitForChild("StudioPay1", 2),
            studioPayFolder:WaitForChild("StudioPay2", 2),
            studioPayFolder:WaitForChild("StudioPay3", 2)
        }
        
        -- Verify all models exist
        local allModelsExist = true
        for i, model in ipairs(models) do
            if not model then
                debugLog("StudioPay" .. i .. " not found")
                allModelsExist = false
                break
            end
        end
        
        if allModelsExist then
            debugLog("All money models found successfully!")
            return models
        end
        
        attempts = attempts + 1
        task.wait(1)
    end
    
    debugLog("Failed to initialize money models after " .. maxAttempts .. " attempts")
    return nil
end

if not handleLoadingScreen() then
    debugLog("Failed to handle loading screen!")
    return
end

local moneyModels = initializeMoneyModels()
if not moneyModels then
    debugLog("Failed to initialize money models!")
    return
end

local tweenInfo = TweenInfo.new(
    4,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.Out
)

local CHECKS_BEFORE_HOP = 10
local emptyChecks = 0
local lastServerHop = 0
local SERVER_HOP_COOLDOWN = 30
local lastServerCheck = 0
local SERVER_CHECK_COOLDOWN = 5

local isProcessingMoney = false
local currentMoneyPart = nil

-- [Previous getServers and serverHop functions remain the same]

local function isAnyMoneyVisible()
    if not moneyModels then
        debugLog("Money models not initialized!")
        return false
    end
    
    for i, model in ipairs(moneyModels) do
        if not model:IsDescendantOf(game) then
            debugLog("Money model " .. i .. " no longer exists in game!")
            moneyModels = initializeMoneyModels()
            return false
        end
        
        local moneyPart = model:FindFirstChild("StudioMoney1")
        if moneyPart then
            if moneyPart.Transparency == 0 then
                debugLog("Found visible money in model " .. i)
                return true
            end
        else
            debugLog("StudioMoney1 part missing from model " .. i)
        end
    end
    
    return false
end

local function isPlayerInCorrectPosition(character, targetPosition)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        debugLog("No HumanoidRootPart found")
        return false 
    end
    
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude
    debugLog("Distance to target: " .. distance)
    return distance <= 5
end

local function tweenToPosition(character, targetPosition)
    debugLog("Attempting to tween to position: " .. tostring(targetPosition))
    
    local success, result = pcall(function()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local tween = TweenService:Create(
            humanoidRootPart,
            tweenInfo,
            {CFrame = CFrame.new(targetPosition)}
        )
        tween:Play()
        return tween
    end)
    
    if not success then
        debugLog("Tween creation failed: " .. tostring(result))
        return nil
    end
    
    return result
end

local function waitForMoneyCollection(moneyPart)
    local startTime = tick()
    local maxWaitTime = 3
    
    debugLog("Waiting for money collection...")
    while moneyPart and moneyPart.Parent and moneyPart.Transparency == 0 do
        if tick() - startTime > maxWaitTime then
            debugLog("Collection timeout")
            return false
        end
        task.wait(0.1)
    end
    debugLog("Money collected")
    return true
end

local function handleVisibleMoney(moneyPart)
    if isProcessingMoney then 
        debugLog("Already processing money, skipping...")
        return 
    end
    
    if not moneyPart or not moneyPart:IsDescendantOf(game) then
        debugLog("Money part is no longer valid")
        return
    end
    
    debugLog("Starting to handle money at position: " .. tostring(moneyPart.Position))
    isProcessingMoney = true
    currentMoneyPart = moneyPart
    
    local prompt = moneyPart:FindFirstChild("Prompt")
    if not prompt then
        debugLog("No prompt found on money part!")
        isProcessingMoney = false
        currentMoneyPart = nil
        return
    end
    
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        debugLog("No character found!")
        isProcessingMoney = false
        currentMoneyPart = nil
        return
    end
    
    local maxAttempts = 3
    local attempts = 0
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        debugLog("Collection attempt " .. attempts)
        
        if not moneyPart or not moneyPart:IsDescendantOf(game) or moneyPart.Transparency ~= 0 then
            debugLog("Money part became invalid during collection")
            break
        end
        
        local tween = tweenToPosition(character, moneyPart.Position)
        if not tween then
            debugLog("Failed to create tween")
            task.wait(0.5)
            continue
        end
        
        tween.Completed:Wait()
        task.wait(0.5)
        
        if isPlayerInCorrectPosition(character, moneyPart.Position) then
            debugLog("In position, attempting collection...")
            prompt:InputHoldBegin()
            getgenv().AutoFarm = true
            
            local collected = waitForMoneyCollection(moneyPart)
            if collected then
                debugLog("Money collected successfully!")
                emptyChecks = 0
                break
            else
                debugLog("Collection attempt " .. attempts .. " failed")
                task.wait(0.5)
            end
        else
            debugLog("Not in correct position, distance check failed")
            task.wait(0.5)
        end
    end
    
    if attempts >= maxAttempts then
        debugLog("Failed to collect money after " .. maxAttempts .. " attempts")
    end
    
    isProcessingMoney = false
    currentMoneyPart = nil
end

local function checkAllMoney()
    if isProcessingMoney then return end
    
    local success, err = pcall(function()
        if not moneyModels then
            debugLog("Attempting to reinitialize money models...")
            moneyModels = initializeMoneyModels()
            if not moneyModels then
                debugLog("Failed to initialize money models")
                return
            end
        end
        
        if not isAnyMoneyVisible() then
            emptyChecks = emptyChecks + 1
            debugLog("No money visible. Empty checks: " .. emptyChecks)
            if emptyChecks >= CHECKS_BEFORE_HOP then
                debugLog("Server hop triggered after " .. CHECKS_BEFORE_HOP .. " empty checks")
                serverHop()
                emptyChecks = 0
            end
            return
        end
        
        for i, model in ipairs(moneyModels) do
            local moneyPart = model:FindFirstChild("StudioMoney1")
            if moneyPart and moneyPart.Transparency == 0 then
                debugLog("Processing money from model " .. i)
                handleVisibleMoney(moneyPart)
                break
            end
        end
    end)
    
    if not success then
        debugLog("Error in checkAllMoney: " .. tostring(err))
        isProcessingMoney = false
        currentMoneyPart = nil
    end
end

RunService.Heartbeat:Connect(function()
    local success, err = pcall(function()
        checkAllMoney()
    end)
    
    if not success then
        debugLog("Error in main loop: " .. tostring(err))
        isProcessingMoney = false
        currentMoneyPart = nil
    end
end)

TeleportService.TeleportInitFailed:Connect(function()
    debugLog("Teleport failed, retrying...")
    task.wait(SERVER_HOP_COOLDOWN)
    serverHop()
end)

debugLog("Script initialization complete!")
