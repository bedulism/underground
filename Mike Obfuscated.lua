local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = workspace

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Combat"):WaitForChild("MeleeWeaponAttackHit")

-- ================== SETTINGS ==================
local ENABLED = false
local RANGE = 25
local TICK_RATE = 0.5
-- =============================================

local HITBOX_NAMES = {"RootPartHitbox", "BonesHitbox", "BodyHitbox", "ArmorHitbox", "HeadHITBOX", 
                     "Fire_Spider_MeshHitbox", "LavaElementalHitbox", "Body_LowHitbox", 
                     "Boar_MeshHitbox", "Body_LPHitbox", "LeftFoot", "Hitbox", "HumanoidRootPart"}

-- ================== GUI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Melee Only"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 130)
frame.Position = UDim2.new(0.5, -90, 0.5, -65)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Melee Only"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 35)
button.Position = UDim2.new(0.5, -80, 0, 40)
button.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
button.Text = "Status: OFF"
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.GothamSemibold
button.TextSize = 14
button.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 160, 0, 30)
closeBtn.Position = UDim2.new(0.5, -80, 0, 85)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.Parent = frame

-- Fungsi Hitbox
local function getValidHitbox(mobModel)
    for _, name in ipairs(HITBOX_NAMES) do
        local part = mobModel:FindFirstChild(name, true)
        if part then return name end
    end
    return "HumanoidRootPart"
end

-- Toggle Button
button.MouseButton1Click:Connect(function()
    ENABLED = not ENABLED
    button.Text = ENABLED and "Status: ON" or "Status: OFF"
    button.BackgroundColor3 = ENABLED and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(255, 60, 60)
end)

-- Close Button
closeBtn.MouseButton1Click:Connect(function()
    ENABLED = false
    screenGui:Destroy()
end)

-- ================== KILL AURA LOGIC ==================
local mobsFolder = Workspace.Game.Regions.Dion.Areas.AncientRuins.MobsSpots

task.spawn(function()
    while screenGui.Parent ~= nil do
        if ENABLED then
            local myChar = player.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if myRoot and mobsFolder then
                for _, obj in ipairs(mobsFolder:GetDescendants()) do
                    if not obj:GetAttribute("CharacterId") then continue end
                    if obj:IsDescendantOf(myChar) then continue end

                    local mobRoot = obj:FindFirstChild("HumanoidRootPart")
                    if not mobRoot then continue end
                    if mobRoot:FindFirstChild("Dead") then continue end   -- Skip mob mati
                    
                    if (mobRoot.Position - myRoot.Position).Magnitude <= RANGE then
                        
                        local targetCharId = obj:GetAttribute("CharacterId")
                        local hitboxName = getValidHitbox(obj)
                        
                        Event:FireServer({
                            [targetCharId] = {
                                clientAuthoroty = true,
                                aimedTarget = targetCharId,
                                additionalData = { hittedPartName = hitboxName }
                            }
                        })
                        
                        break   -- Serang 1 target hidup, lalu cycle berikutnya cari lagi
                    end
                end
            end
        end
        task.wait(TICK_RATE)
    end
end)

-- Cleanup
screenGui.Destroying:Connect(function()
    -- Script akan otomatis berhenti karena while loop mengecek screenGui.Parent
end)
