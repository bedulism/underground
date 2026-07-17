local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mobFolderPath = workspace:WaitForChild("Game"):WaitForChild("Regions"):WaitForChild("Dion"):WaitForChild("Areas"):WaitForChild("AncientRuins"):WaitForChild("MobsSpots")

local enabled = false
local currentTarget = nil

-- Resize HumanoidRootPart untuk menghindari stuck
local function resizeHumanoidRootPart()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Size = Vector3.new(1.25, 10, 1.25)
    end
end

local function resetHumanoidRootPart()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
    end
end

-- Mengecek apakah musuh masih hidup
local function isMobStillAlive(mob)
    if mob and mob.Parent then
        for _, part in ipairs(mob:GetDescendants()) do
            if part:IsA("MeshPart") and part.Transparency < 0.9 then
                return true
            end
        end
    end
    return false
end

-- Teleportasi smooth ke belakang musuh
local function tweenTeleport(targetPosition, mobRootPart)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = player.Character.HumanoidRootPart
        local mobLookVector = mobRootPart.CFrame.LookVector
        local behindMobPosition = targetPosition - (mobLookVector * 6) + Vector3.new(0, 10, 0)

        local targetCFrame = CFrame.new(behindMobPosition)
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local goal = {CFrame = targetCFrame}
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
        tween:Play()
    end
end

-- Mencari musuh terdekat yang masih hidup
local function findNearestAliveMob()
    local closestMob = nil
    local shortestDistance = math.huge
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = player.Character.HumanoidRootPart
        for _, mobFolder in ipairs(mobFolderPath:GetChildren()) do
            if mobFolder:IsA("Folder") and not (mobFolder.Name == "DropChest" or mobFolder.Name == "CityGuard" or mobFolder.Name == "TrainingDummyMedium") then
                for _, spawnPart in ipairs(mobFolder:GetChildren()) do
                    if spawnPart:IsA("Part") then
                        for _, mob in ipairs(spawnPart:GetChildren()) do
                            if mob:IsA("Model") and isMobStillAlive(mob) then
                                local mobRootPart = mob:FindFirstChild("HumanoidRootPart")
                                if mobRootPart then
                                    local distance = (humanoidRootPart.Position - mobRootPart.Position).Magnitude
                                    if distance < shortestDistance then
                                        shortestDistance = distance
                                        closestMob = mob
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestMob
end

-- Loop utama untuk AutoFarm
local function teleportLoop()
    while enabled do
        local targetMob = findNearestAliveMob()
        if targetMob then
            currentTarget = targetMob
            tweenTeleport(targetMob.HumanoidRootPart.Position, targetMob.HumanoidRootPart)
            while enabled and isMobStillAlive(currentTarget) do
                task.wait(0.2)
            end
        else
            task.wait(1)
        end
    end
end

-- GUI Modern dan Kecil
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local ToggleUICorner = Instance.new("UICorner")
local CloseUICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ScreenGui.Parent = game:GetService("CoreGui")

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 150, 0, 100)
Frame.Position = UDim2.new(0.4, 0, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 10)

UIStroke.Parent = Frame
UIStroke.Color = Color3.fromRGB(255, 215, 0)
UIStroke.Thickness = 2

ToggleButton.Parent = Frame
ToggleButton.Size = UDim2.new(0, 130, 0, 30)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.Text = "AutoFarm: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)

ToggleUICorner.Parent = ToggleButton
ToggleUICorner.CornerRadius = UDim.new(0, 8)

CloseButton.Parent = Frame
CloseButton.Size = UDim2.new(0, 130, 0, 30)
CloseButton.Position = UDim2.new(0, 10, 0, 50)
CloseButton.Text = "Close"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 69, 0)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)

CloseUICorner.Parent = CloseButton
CloseUICorner.CornerRadius = UDim.new(0, 8)

-- Efek Hover
ToggleButton.MouseEnter:Connect(function()
    ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
end)

ToggleButton.MouseLeave:Connect(function()
    ToggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 69, 0)
end)

-- Toggle AutoFarm
ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    ToggleButton.Text = enabled and "AutoFarm: ON" or "AutoFarm: OFF"
    ToggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)

    if enabled then
        resizeHumanoidRootPart()
        teleportLoop()
    else
        resetHumanoidRootPart()
    end
end)

-- Close GUI
CloseButton.MouseButton1Click:Connect(function()
    enabled = false
    resetHumanoidRootPart()
    ScreenGui:Destroy()
end)
