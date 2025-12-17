-- Full Example Script for Mobile Executors
-- This is a complete ready-to-run script

-- === CONFIGURATION ===
local USE_GITHUB = false  -- Set to true if repo is public, false to use local files
local GITHUB_TOKEN = ""   -- Only needed for private repos (not recommended)

-- === LOAD MODULE ===
local Deobf
if USE_GITHUB then
    -- Public repo method
    local url = "https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/src/Grow_a_Garden.deobf.lua"
    if GITHUB_TOKEN ~= "" then
        -- Private repo with token (WARNING: token can be stolen!)
        url = "https://" .. GITHUB_TOKEN .. "@raw.githubusercontent.com/sora598/grow-a-garden-test/main/src/Grow_a_Garden.deobf.lua"
    end
    Deobf = loadstring(game:HttpGet(url))()
else
    -- Local files method (recommended for private repos)
    Deobf = loadstring(readfile("src/Grow_a_Garden.deobf.lua"))()
end

print("✓ Module loaded successfully!")

-- === YOUR CONFIG ===
local config = {
    -- Luck System
    LuckBase = 0.10,              -- 10% base luck
    LuckBoostPercent = 50,         -- +50% boost = 15% total
    LuckCapMax = 0.80,             -- Optional: cap at 80%
    
    -- Auto Collection
    ["Auto Collect Fruits"] = true,
    ["Delay To Collect"] = 0.05,
    ["Select Whitlist Fruit"] = {"All"},  -- or specific: {"Tomato", "Wheat"}
    ["Stop Collect If Backpack Is Full Max"] = true,
    
    -- Auto Watering
    ["AutoWater Fruitlist"] = false,  -- Enable if you want auto-watering
    ["Select Water Fruit"] = {"Tomato", "Wheat"},
    ["DelayToWait"] = 0.1,
    
    -- Tools
    ["Auto Favorite Backpack"] = false,  -- Auto-favorite items
}

-- === FIND & ATTACH REMOTES ===
-- You need to find these paths in your game using Remote Spy
-- Replace the paths below with the actual remote locations

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Example remote paths (UPDATE THESE!)
Deobf.attachRemotes({
    Crops = {
        Collect = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Crops") and ReplicatedStorage.Remotes.Crops:FindFirstChild("Collect")
    },
    Water_RE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Water_RE"),
    Favorite_Item = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Favorite_Item"),
    -- Add more remotes as needed
})

print("✓ Remotes attached!")

-- === INITIALIZE ===
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local helpers = {
    InventoryChecker = Deobf.InventoryChecker.new(player),
    FruitFilter = Deobf.Helpers.FruitFilter,
}

-- API object (optional, can be empty table)
local api = {
    -- Add your API methods here if you have them
}

print("✓ Starting main loop...")
print("✓ Luck: " .. string.format("%.2f%%", Deobf.GetEffectiveLuck(config) * 100))

-- === MAIN LOOP ===
local running = true

-- Stop button (optional)
local function createStopButton()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GrowAGardenStop"
    sg.ResetOnSpawn = false
    
    pcall(function()
        if player.PlayerGui then
            sg.Parent = player.PlayerGui
        elseif gethui then
            sg.Parent = gethui()
        end
    end)
    
    local btn = Instance.new("TextButton", sg)
    btn.Size = UDim2.new(0, 100, 0, 40)
    btn.Position = UDim2.new(1, -110, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = "STOP"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    
    btn.MouseButton1Click:Connect(function()
        running = false
        sg:Destroy()
        print("✓ Script stopped by user")
    end)
end

createStopButton()

-- Main execution loop
while running do
    local success, err = pcall(function()
        Deobf.runCycle(player, config, api, helpers)
    end)
    
    if not success then
        warn("Error in cycle: " .. tostring(err))
    end
    
    task.wait(1)  -- Adjust loop speed as needed
end

print("✓ Script ended")
