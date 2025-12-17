-- Grow a Garden - Main Orchestrator
-- Single entry point that loads and coordinates all modules

print("🌱 Initializing Grow a Garden...")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ========== MODULE LOADER ==========
local function loadModule(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Failed to load module:", url, "\nError:", tostring(result))
        return nil
    end
    return result
end

-- ========== LOAD CORE MODULES ==========
print("📦 Loading core modules...")

-- Load config
local Config = {
    LuckBase = 0.10,
    LuckBoostPercent = 50,
    LuckCapMax = 0.80,
    ["Auto Collect"] = false,
    ["Auto Water"] = false,
    ["Auto Favorite"] = false,
}

-- Load utils
local Utils = {}
function Utils.formatNumber(n, decimals)
    decimals = decimals or 2
    if type(n) ~= "number" then return tostring(n) end
    local fmt = "%." .. tostring(decimals) .. "f"
    return string.format(fmt, n)
end

-- Load luck system
local LuckBoost = {}
function LuckBoost.apply(base, boost)
    return base * (1 + boost / 100)
end
function LuckBoost.applyCap(base, boost, minL, maxL)
    local r = LuckBoost.apply(base, boost)
    if type(minL) == "number" and r < minL then r = minL end
    if type(maxL) == "number" and r > maxL then r = maxL end
    return r
end

-- ========== STATE ==========
local State = {
    running = false,
    stats = {
        items = 0,
        water = 0,
        uptime = 0,
    },
    eggs = {}
}

-- ========== EGG DETECTION & CHECKING ==========
local EggSystem = {}

function EggSystem.findEggs()
    local eggs = {}
    local workspace = game:GetService("Workspace")
    
    -- Search for egg models in workspace
    local function searchForEggs(parent)
        for _, obj in pairs(parent:GetChildren()) do
            local name = obj.Name:lower()
            
            -- Look for objects named "egg", "eggs", or containing egg-like properties
            if name:match("egg") or (obj:FindFirstChild("Timer") or obj:FindFirstChild("timer")) then
                table.insert(eggs, obj)
            end
            
            -- Recurse into children
            if obj:IsA("Model") or obj:IsA("Folder") then
                searchForEggs(obj)
            end
        end
    end
    
    searchForEggs(workspace)
    State.eggs = eggs
    return eggs
end

function EggSystem.getEggInfo(egg)
    if not egg then return nil end
    
    local info = {
        name = egg.Name,
        position = egg:IsA("BasePart") and egg.Position or (egg.PrimaryPart and egg.PrimaryPart.Position) or Vector3.new(0, 0, 0),
        timerValue = nil,
        timerComplete = false,
        content = nil,
        properties = {}
    }
    
    -- Try to find timer
    local timer = egg:FindFirstChild("Timer") or egg:FindFirstChild("timer") or egg:FindFirstChild("Hatch_Timer")
    if timer then
        if timer:IsA("NumberValue") or timer:IsA("IntValue") then
            info.timerValue = timer.Value
            info.timerComplete = timer.Value <= 0
        elseif timer:IsA("TextLabel") or timer:IsA("TextBox") then
            info.timerValue = tonumber(timer.Text) or 0
        end
    end
    
    -- Try to find content/type
    local content = egg:FindFirstChild("Content") or egg:FindFirstChild("content") or egg:FindFirstChild("Type") or egg:FindFirstChild("type")
    if content then
        if content:IsA("StringValue") then
            info.content = content.Value
        elseif content:IsA("TextLabel") then
            info.content = content.Text
        end
    end
    
    -- Store all custom properties
    for _, child in pairs(egg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("StringValue") or child:IsA("BoolValue") then
            info.properties[child.Name] = child.Value
        end
    end
    
    return info
end

function EggSystem.checkAllEggs()
    local eggs = EggSystem.findEggs()
    local report = {}
    
    for _, egg in pairs(eggs) do
        local eggInfo = EggSystem.getEggInfo(egg)
        if eggInfo then
            table.insert(report, eggInfo)
            if eggInfo.timerComplete then
                print(string.format("🥚 EGG READY: %s | Content: %s", eggInfo.name, eggInfo.content or "Unknown"))
            end
        end
    end
    
    return report
end

function EggSystem.watchEggs(callback)
    local lastStates = {}
    
    task.spawn(function()
        while State.running do
            local eggs = EggSystem.findEggs()
            
            for i, egg in pairs(eggs) do
                local info = EggSystem.getEggInfo(egg)
                local lastState = lastStates[egg]
                
                if lastState and lastState.timerComplete == false and info.timerComplete == true then
                    print("⏰ EGG TIMER COMPLETED!")
                    if callback then callback(egg, info) end
                end
                
                lastStates[egg] = info
            end
            
            task.wait(1)
        end
    end)
end

-- ========== GUI BUILDER MODULE ==========
local function buildGUI()
    print("🎨 Building GUI...")
    
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    
    -- Create main container
    local sg = Instance.new("ScreenGui")
    sg.Name = "GrowAGardenMain"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = player.PlayerGui or gethui() or game.CoreGui end)
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 280, 0, 320)
    main.Position = UDim2.new(1, -290, 1, -330)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    main.BorderSizePixel = 0
    main.Parent = sg
    
    local mc = Instance.new("UICorner", main)
    mc.CornerRadius = UDim.new(0, 8)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🌱 Control"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Helper to create buttons
    local function makeBtn(x, text, color, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0, 3.5)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.Parent = header
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        if callback then b.MouseButton1Click:Connect(callback) end
        return b
    end
    
    local minBtn = makeBtn(-60, "−", Color3.fromRGB(60, 60, 60))
    local closeBtn = makeBtn(-28, "✕", Color3.fromRGB(200, 50, 50))
    
    -- Content area
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -14, 1, -45)
    content.Position = UDim2.new(0, 7, 0, 40)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.CanvasSize = UDim2.new(0, 0, 0, 500)
    content.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = content
    
    -- Helper to add toggles
    local function addToggle(name, key, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 28)
        f.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        f.Parent = content
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 42, 0, 20)
        btn.Position = UDim2.new(1, -48, 0.5, -10)
        btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        btn.Text = "ON"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
        
        btn.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            btn.Text = Config[key] and "ON" or "OFF"
            btn.BackgroundColor3 = Config[key] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
        end)
    end
    
    -- Helper to add sliders
    local function addSlider(name, key, min, max, default, suffix, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 38)
        f.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        f.Parent = content
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -65, 0, 14)
        lbl.Position = UDim2.new(0, 6, 0, 2)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f
        
        local vl = Instance.new("TextLabel")
        vl.Size = UDim2.new(0, 60, 0, 14)
        vl.Position = UDim2.new(1, -66, 0, 2)
        vl.BackgroundTransparency = 1
        vl.Text = default .. suffix
        vl.TextColor3 = Color3.fromRGB(100, 200, 255)
        vl.Font = Enum.Font.GothamBold
        vl.TextSize = 10
        vl.TextXAlignment = Enum.TextXAlignment.Right
        vl.Parent = f
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -12, 0, 5)
        bar.Position = UDim2.new(0, 6, 1, -15)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        bar.BorderSizePixel = 0
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2.5)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2.5)
        
        local dragging = false
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        bar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * pos
                if suffix == "%" then val = math.floor(val) else val = math.floor(val * 100) / 100 end
                Config[key] = val
                fill.Size = UDim2.new(pos, 0, 1, 0)
                vl.Text = val .. suffix
            end
        end)
    end
    
    -- BUILD GUI ELEMENTS
    addToggle("Auto Collect", "Auto Collect", 1)
    addToggle("Auto Water", "Auto Water", 2)
    addToggle("Auto Favorite", "Auto Favorite", 3)
    
    addSlider("Luck Base", "LuckBase", 0, 1, 0.10, "", 4)
    addSlider("Boost %", "LuckBoostPercent", 0, 500, 50, "%", 5)
    addSlider("Max Cap", "LuckCapMax", 0, 1, 0.80, "", 6)
    
    -- Egg checker button
    local eb = Instance.new("TextButton")
    eb.Size = UDim2.new(1, 0, 0, 28)
    eb.BackgroundColor3 = Color3.fromRGB(100, 100, 180)
    eb.Text = "🥚 Check Eggs"
    eb.TextColor3 = Color3.fromRGB(255, 255, 255)
    eb.Font = Enum.Font.GothamBold
    eb.TextSize = 11
    eb.LayoutOrder = 7
    eb.Parent = content
    Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 5)
    
    eb.MouseButton1Click:Connect(function()
        local eggReport = EggSystem.checkAllEggs()
        print(string.format("🔍 Found %d eggs:", #eggReport))
        for i, egg in pairs(eggReport) do
            print(string.format("  [%d] %s | Timer: %s | Content: %s", i, egg.name, tostring(egg.timerValue), egg.content or "N/A"))
        end
    end)
    
    -- Status display
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, 0, 0, 70)
    sf.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sf.BorderSizePixel = 0
    sf.LayoutOrder = 8
    sf.Parent = content
    Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 5)
    
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, -12, 1, -6)
    sl.Position = UDim2.new(0, 6, 0, 3)
    sl.BackgroundTransparency = 1
    sl.Text = "Status: Idle\nLuck: 0%\nItems: 0"
    sl.TextColor3 = Color3.fromRGB(180, 180, 180)
    sl.Font = Enum.Font.Code
    sl.TextSize = 9
    sl.TextXAlignment = Enum.TextXAlignment.Left
    sl.TextYAlignment = Enum.TextYAlignment.Top
    sl.Parent = sf
    
    -- Start button
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(1, 0, 0, 32)
    sb.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    sb.Text = "▶ START"
    sb.TextColor3 = Color3.fromRGB(255, 255, 255)
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 12
    sb.LayoutOrder = 9
    sb.Parent = content
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 5)
    
    -- ========== BUTTON CALLBACKS ==========
    local function updateStatus()
        local luck = LuckBoost.applyCap(Config.LuckBase, Config.LuckBoostPercent, Config.LuckCapMin, Config.LuckCapMax)
        sl.Text = string.format("Status: %s\nLuck: %.1f%%\nItems: %d", 
            State.running and "🟢 RUNNING" or "⚪ IDLE",
            luck * 100,
            State.stats.items
        )
    end
    
    task.spawn(function()
        while task.wait(1) do
            if State.running then State.stats.uptime = State.stats.uptime + 1 end
            updateStatus()
        end
    end)
    
    sb.MouseButton1Click:Connect(function()
        State.running = not State.running
        sb.Text = State.running and "⏸ STOP" or "▶ START"
        sb.BackgroundColor3 = State.running and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 50)
        if State.running then State.stats.uptime = 0 end
        updateStatus()
    end)
    
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(main, TweenInfo.new(0.2), {Size = minimized and UDim2.new(0, 280, 0, 35) or UDim2.new(0, 280, 0, 320)}):Play()
        minBtn.Text = minimized and "+" or "−"
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        State.running = false
        sg:Destroy()
    end)
    
    -- ========== DRAGGABLE ==========
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    
    header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    
    return {
        gui = sg,
        main = main,
        state = State,
        config = Config,
        eggSystem = EggSystem,
    }
end

-- ========== MAIN EXECUTION ==========
print("✨ Starting GUI...")
local GUI = buildGUI()

-- Start egg watcher (checks eggs every second when running)
EggSystem.watchEggs(function(egg, info)
    print(string.format("🎉 Egg hatched: %s -> %s", info.name, info.content or "Unknown"))
end)

print("✓ Grow a Garden loaded!")
print("✓ GUI: Bottom-right corner")
print("✓ Egg system: Active")
print("✓ All systems ready")
