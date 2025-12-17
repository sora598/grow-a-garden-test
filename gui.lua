-- Grow a Garden - Full Control GUI
-- Feature-rich interface for all automation features with luck boost

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Load module
local Deobf = loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/src/Grow_a_Garden.deobf.lua"))()

print("✓ Module loaded!")

-- Configuration state
local config = {
    LuckBase = 0.10,
    LuckBoostPercent = 50,
    LuckCapMax = 0.80,
    ["Auto Collect Fruits"] = false,
    ["Delay To Collect"] = 0.05,
    ["Select Whitlist Fruit"] = {"All"},
    ["Stop Collect If Backpack Is Full Max"] = true,
    ["AutoWater Fruitlist"] = false,
    ["Select Water Fruit"] = {"Tomato", "Wheat"},
    ["DelayToWait"] = 0.1,
    ["Auto Favorite Backpack"] = false,
}

local running = false
local stats = {
    itemsCollected = 0,
    plantsWatered = 0,
    uptime = 0,
}

-- Create GUI
local sg = Instance.new("ScreenGui")
sg.Name = "GrowAGardenGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if player.PlayerGui then
        sg.Parent = player.PlayerGui
    elseif gethui then
        sg.Parent = gethui()
    elseif game.CoreGui then
        sg.Parent = game.CoreGui
    end
end)

-- Main Frame
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 420, 0, 500)
main.Position = UDim2.new(0.5, -210, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.Active = true
main.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🌱 Grow a Garden Control"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Content container with ScrollingFrame
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 6
content.CanvasSize = UDim2.new(0, 0, 0, 800)
content.Parent = main

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = content

-- Helper functions
local function createSection(name, order)
    local section = Instance.new("Frame")
    section.Name = name
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = order
    section.Parent = content
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 6)
    sectionCorner.Parent = section
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(100, 200, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    return section
end

local function createToggle(name, configKey, defaultValue, order)
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Size = UDim2.new(1, 0, 0, 35)
    toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggle.BorderSizePixel = 0
    toggle.LayoutOrder = order
    toggle.Parent = content
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 25)
    btn.Position = UDim2.new(1, -60, 0.5, -12.5)
    btn.BackgroundColor3 = defaultValue and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100)
    btn.Text = defaultValue and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = toggle
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        config[configKey] = not config[configKey]
        btn.Text = config[configKey] and "ON" or "OFF"
        btn.BackgroundColor3 = config[configKey] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 100)
    end)
    
    return toggle
end

local function createSlider(name, configKey, min, max, defaultValue, suffix, order)
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Size = UDim2.new(1, 0, 0, 50)
    slider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    slider.BorderSizePixel = 0
    slider.LayoutOrder = order
    slider.Parent = content
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = slider
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 80, 0, 20)
    valueLabel.Position = UDim2.new(1, -90, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue) .. suffix
    valueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = slider
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 8)
    sliderBar.Position = UDim2.new(0, 10, 1, -18)
    sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = slider
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = sliderBar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill
    
    local dragging = false
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = (input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X
            pos = math.clamp(pos, 0, 1)
            local value = min + (max - min) * pos
            
            if suffix == "%" then
                value = math.floor(value)
            else
                value = math.floor(value * 100) / 100
            end
            
            config[configKey] = value
            fill.Size = UDim2.new(pos, 0, 1, 0)
            valueLabel.Text = tostring(value) .. suffix
        end
    end)
    
    return slider
end

local function createStatusBox(order)
    local status = Instance.new("Frame")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 100)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    status.BorderSizePixel = 0
    status.LayoutOrder = order
    status.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = status
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 1, -10)
    statusLabel.Position = UDim2.new(0, 10, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle\nLuck: 0.00%\nItems: 0 | Watered: 0\nUptime: 0s"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Code
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = status
    
    return statusLabel
end

local function createStartButton(order)
    local btn = Instance.new("TextButton")
    btn.Name = "StartButton"
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    btn.Text = "▶ START"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.LayoutOrder = order
    btn.Parent = content
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    return btn
end

-- Build UI
createSection("⚙️ General Settings", 1)
createToggle("Auto Collect Fruits", "Auto Collect Fruits", false, 2)
createToggle("Stop If Backpack Full", "Stop Collect If Backpack Is Full Max", true, 3)
createToggle("Auto Water Plants", "AutoWater Fruitlist", false, 4)
createToggle("Auto Favorite Items", "Auto Favorite Backpack", false, 5)

createSection("🍀 Luck Boost", 6)
createSlider("Base Luck", "LuckBase", 0, 1, 0.10, "", 7)
createSlider("Boost Percentage", "LuckBoostPercent", 0, 500, 50, "%", 8)
createSlider("Max Cap", "LuckCapMax", 0, 1, 0.80, "", 9)

createSection("⏱️ Timing", 10)
createSlider("Collect Delay", "Delay To Collect", 0.01, 1, 0.05, "s", 11)
createSlider("Water Delay", "DelayToWait", 0.01, 1, 0.1, "s", 12)

createSection("📊 Status", 13)
local statusLabel = createStatusBox(14)
local startBtn = createStartButton(15)

-- Attach remotes (customize these based on your game)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
pcall(function()
    Deobf.attachRemotes({
        Crops = {
            Collect = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Crops") and ReplicatedStorage.Remotes.Crops:FindFirstChild("Collect")
        },
        Water_RE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Water_RE"),
        Favorite_Item = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Favorite_Item"),
    })
end)

-- Main loop
local helpers = {
    InventoryChecker = Deobf.InventoryChecker.new(player),
    FruitFilter = Deobf.Helpers.FruitFilter,
}

local api = {}

local function updateStatus()
    local luck = Deobf.GetEffectiveLuck(config)
    local statusText = string.format(
        "Status: %s\nLuck: %.2f%%\nItems: %d | Watered: %d\nUptime: %ds",
        running and "🟢 Running" or "⚪ Idle",
        luck * 100,
        stats.itemsCollected,
        stats.plantsWatered,
        stats.uptime
    )
    statusLabel.Text = statusText
end

task.spawn(function()
    while task.wait(1) do
        if running then
            stats.uptime = stats.uptime + 1
        end
        updateStatus()
    end
end)

startBtn.MouseButton1Click:Connect(function()
    running = not running
    startBtn.Text = running and "⏸ STOP" or "▶ START"
    startBtn.BackgroundColor3 = running and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 50)
    
    if running then
        stats.uptime = 0
        task.spawn(function()
            while running do
                local success, err = pcall(function()
                    Deobf.runCycle(player, config, api, helpers)
                end)
                if not success then
                    warn("Cycle error:", err)
                end
                task.wait(1)
            end
        end)
    end
end)

-- Minimize functionality
local minimized = false
local originalSize = main.Size

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 420, 0, 40) or originalSize
    minimizeBtn.Text = minimized and "+" or "—"
    
    TweenService:Create(main, TweenInfo.new(0.3), {Size = targetSize}):Play()
end)

-- Close functionality
closeBtn.MouseButton1Click:Connect(function()
    running = false
    sg:Destroy()
end)

-- Draggable
local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("✓ GUI loaded! Configure settings and press START")
updateStatus()
