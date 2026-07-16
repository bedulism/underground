local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AttackEvent = ReplicatedStorage.Events.Combat.RangeWeaponAttack
local HitEvent    = ReplicatedStorage.Events.Combat.RangeWeaponAttackHit

-- ================== SETTINGS ==================
local ENABLED = false
local RANGE = 100
local TICK_RATE = 0.25
local MAX_TARGETS = 1
-- =============================================

local HITBOX_NAMES = {"RootPartHitbox", "BonesHitbox", "BodyHitbox", "ArmorHitbox", "HeadHITBOX", 
                     "Fire_Spider_MeshHitbox", "LavaElementalHitbox", "Body_LowHitbox", 
                     "Boar_MeshHitbox", "Body_LPHitbox", "LeftFoot", "Hitbox", "HumanoidRootPart"}

-- ================== GUI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Bow Only"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0.5, -100, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundColor3 = Color3.fromRGB(15,15,15)
title.Text = "Bow Only"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local statusBtn = Instance.new("TextButton", frame)
statusBtn.Size = UDim2.new(0, 180, 0, 40)
statusBtn.Position = UDim2.new(0.5, -90, 0, 40)
statusBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
statusBtn.Text = "Status: OFF"
statusBtn.TextColor3 = Color3.new(1,1,1)
statusBtn.Font = Enum.Font.GothamSemibold
statusBtn.TextSize = 14

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 180, 0, 35)
closeBtn.Position = UDim2.new(0.5, -90, 0, 90)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.new(1,1,1)

-- Fungsi Hitbox (sama seperti Melee)
local function getValidHitbox(mobModel)
    for _, name in ipairs(HITBOX_NAMES) do
        local part = mobModel:FindFirstChild(name, true)
        if part then return name end
    end
    return "BodyHitbox"  -- fallback
end

-- Toggle
statusBtn.MouseButton1Click:Connect(function()
    ENABLED = not ENABLED
    statusBtn.Text = ENABLED and "Status: ON" or "Status: OFF"
    statusBtn.BackgroundColor3 = ENABLED and Color3.fromRGB(60,255,60) or Color3.fromRGB(255,60,60)
end)

closeBtn.MouseButton1Click:Connect(function()
    ENABLED = false
    screenGui:Destroy()
end)

-- ================== MAIN LOOP ==================
local mobsFolder = Workspace.Game.Regions.Dion.Areas.AncientRuins.MobsSpots

task.spawn(function()
    while screenGui.Parent ~= nil do
        if not ENABLED then task.wait(0.5) continue end

        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then task.wait(0.5) continue end

        for _, obj in ipairs(mobsFolder:GetDescendants()) do
            if not obj:GetAttribute("CharacterId") then continue end
            if obj:IsDescendantOf(character) then continue end

            local mobRoot = obj:FindFirstChild("HumanoidRootPart")
            if not mobRoot or mobRoot:FindFirstChild("Dead") then continue end

            if (mobRoot.Position - root.Position).Magnitude > RANGE then continue end

            local targetCharId = obj:GetAttribute("CharacterId")
            local attackId = HttpService:GenerateGUID(false)
            local hitboxName = getValidHitbox(obj)        -- Dinamis seperti Melee
            local direction = (mobRoot.Position - root.Position).Unit

            -- 1. Fire Attack (Shoot)
            AttackEvent:FireServer(
                1, 
                attackId,
                root.Position,
                direction
            )

            -- 2. Register Hit
            HitEvent:FireServer(
                attackId,
                targetCharId,
                {
                    additionalData = {
                        targetsHitData = {
                            [targetCharId] = {
                                isCriticalDamage = true,
                                targetHRP = mobRoot,
                                damage = 950          -- Sementara
                            }
                        },
                        attackId = attackId,
                        hitPosition = mobRoot.Position,
                        hittedPartName = hitboxName   -- ← Dinamis
                    },
                    casterId = player.UserId,
                    weaponType = "Bow"
                }
            )

            break
        end

        task.wait(TICK_RATE)
    end
end)
