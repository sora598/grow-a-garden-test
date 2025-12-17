-- Grow a Garden - Main Orchestrator
-- Single entry point that loads and coordinates all modules

print("🌱 Initializing Grow a Garden...")

-- Version
local VERSION = "v0.8"

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
    ["ESP Enabled"] = true,
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

-- Simple in-memory console for GUI; use `Log(...)` to record messages
State.console = {}
local function _safe_tostring(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then return "<table>" end
    return tostring(v)
end
function Log(...)
    local parts = {}
    for i = 1, select('#', ...) do
        parts[#parts+1] = _safe_tostring(select(i, ...))
    end
    local line = table.concat(parts, " ")
    -- store with timestamp
    local entry = {time = os.date("%X"), text = line}
    table.insert(State.console, entry)
    -- limit history
    if #State.console > 200 then table.remove(State.console, 1) end
    -- also print to normal console
    pcall(function() print(string.format("[%s] %s", entry.time, entry.text)) end)
    -- if GUI present, append there too
    if GUI and GUI.appendConsole then
        pcall(function() GUI.appendConsole(entry.time, entry.text) end)
    end
end

-- ========== EGG DETECTION & CHECKING ==========
local EggSystem = {}

-- Determine if an egg belongs to the local player (returns true/false/nil if unknown)
function EggSystem.isOwnedByPlayer(egg, playerRef)
    if not egg then return nil end
    local p = playerRef or player
    local uname = p and p.Name or nil
    local uid = p and p.UserId or nil

    local function matches(val)
        if val == nil then return nil end
        if typeof(val) == "string" then
            return val == uname and true or (val ~= uname and false or nil)
        elseif typeof(val) == "number" then
            return uid and val == uid and true or (uid and val ~= uid and false or nil)
        end
        return nil
    end

    -- Check attributes on egg
    for k, v in pairs(egg:GetAttributes()) do
        local key = k:lower()
        if key == "owner" or key == "player" or key == "owner_name" or key == "playername" or key == "userid" or key == "user_id" then
            local m = matches(v)
            if m ~= nil then return m end
        end
    end

    -- Check children ValueBase/StringValue nodes that may store owner
    for _, child in pairs(egg:GetChildren()) do
        local key = child.Name:lower()
        if child:IsA("StringValue") or child:IsA("NumberValue") then
            if key == "owner" or key == "player" or key == "owner_name" or key == "playername" or key == "userid" or key == "user_id" then
                local m = matches(child.Value)
                if m ~= nil then return m end
            end
        end
    end

    -- Check parent attributes/values as a fallback (some games store ownership on the container)
    if egg.Parent then
        for k, v in pairs(egg.Parent:GetAttributes()) do
            local key = k:lower()
            if key == "owner" or key == "player" or key == "owner_name" or key == "playername" or key == "userid" or key == "user_id" then
                local m = matches(v)
                if m ~= nil then return m end
            end
        end
        for _, child in pairs(egg.Parent:GetChildren()) do
            local key = child.Name:lower()
            if child:IsA("StringValue") or child:IsA("NumberValue") then
                if key == "owner" or key == "player" or key == "owner_name" or key == "playername" or key == "userid" or key == "user_id" then
                    local m = matches(child.Value)
                    if m ~= nil then return m end
                end
            end
        end
    end

    return nil -- unknown ownership
end

function EggSystem.findEggs(maxEggs)
    maxEggs = maxEggs or 20  -- Limit to 20 eggs by default for performance
    local eggs = {}
    local workspace = game:GetService("Workspace")

    -- Common candidate roots where eggs are often placed
    local roots = { workspace }
    local candidates = { "Garden", "PhysicalEggsShop", "PhysicalEggs", "Eggs", "PhysicalGarden" }
    for _, name in ipairs(candidates) do
        local r = workspace:FindFirstChild(name)
        if r then table.insert(roots, r) end
    end

    local function searchForEggs(parent)
        if #eggs >= maxEggs then return end  -- Stop if we've reached the limit
        
        for _, obj in pairs(parent:GetChildren()) do
            if #eggs >= maxEggs then break end  -- Stop if we've reached the limit
            
            local ok, name = pcall(function() return obj.Name end)
            name = (ok and tostring(name) or ""):lower()

            -- Look for objects named "egg" or that contain a Timer child
            if name:match("egg") or obj:FindFirstChild("Timer") or obj:FindFirstChild("timer") then
                local owned = EggSystem.isOwnedByPlayer(obj, player)

                -- If ownership is unknown, try a proximity heuristic to the local player
                if owned == nil then
                    local ok, info = pcall(function() return EggSystem.getEggInfo(obj) end)
                    if ok and info and info.position and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = player.Character.HumanoidRootPart
                        local success, dist = pcall(function() return (hrp.Position - info.position).Magnitude end)
                        if success and dist and type(dist) == "number" and dist <= 80 then
                            owned = true
                        end
                    end
                end

                if owned == true then
                    table.insert(eggs, obj)
                end
            end

            if obj:IsA("Model") or obj:IsA("Folder") then
                searchForEggs(obj)
            end
        end
    end

    for _, root in ipairs(roots) do
        if #eggs >= maxEggs then break end  -- Stop if we've reached the limit
        if root and root:IsA("Instance") then
            pcall(function() searchForEggs(root) end)
        end
    end

    State.eggs = eggs
    return eggs
end

function EggSystem.getEggInfo(egg)
    if not egg then return nil end

    local info = {
        name = tostring(egg.Name or "<unknown>"),
        position = Vector3.new(0,0,0),
        timerValue = nil,
        timerComplete = false,
        content = nil,
        properties = {},
        parentInfo = nil
    }

    -- Safe position extraction: only query PrimaryPart for Models, never index PrimaryPart on Folders
    if egg:IsA("BasePart") then
        local ok, pos = pcall(function() return egg.Position end)
        if ok and pos then info.position = pos end
    elseif egg:IsA("Model") then
        local ok, pp = pcall(function() return egg.PrimaryPart end)
        if ok and pp and pp:IsA("BasePart") then
            local ok2, pos2 = pcall(function() return pp.Position end)
            if ok2 and pos2 then info.position = pos2 end
        else
            -- Try pivot as fallback
            local ok3, pivot = pcall(function() return egg:GetPivot().Position end)
            if ok3 and pivot then info.position = pivot end
        end
    end

    -- Try to find timer (check egg itself first, then parent)
    -- Helper: recursive descendant search by name list
    local function _findDescendantByNames(root, names, maxDepth, depth)
        depth = depth or 0
        maxDepth = maxDepth or 4
        if not root or depth > maxDepth then return nil end
        for _, n in ipairs(names) do
            local f = root:FindFirstChild(n)
            if f then return f end
        end
        for _, c in pairs(root:GetChildren()) do
            local r = _findDescendantByNames(c, names, maxDepth, depth + 1)
            if r then return r end
        end
        return nil
    end

    local timerNames = {"Timer", "timer", "Hatch_Timer", "HatchTimer", "TimerValue"}
    local timer = _findDescendantByNames(egg, timerNames, 4)
    if not timer and egg.Parent then
        timer = _findDescendantByNames(egg.Parent, timerNames, 3)
        if timer then info.parentInfo = egg.Parent.Name end
    end
    
    if timer then
        if timer:IsA("NumberValue") or timer:IsA("IntValue") then
            local ok, v = pcall(function() return timer.Value end)
            if ok then
                info.timerValue = v
                info.timerComplete = (type(v) == "number" and v <= 0) or false
            end
        elseif timer:IsA("StringValue") or timer:IsA("TextLabel") or timer:IsA("TextBox") then
            local ok, txt = pcall(function() return timer.Value or timer.Text end)
            local num = tonumber(ok and txt)
            info.timerValue = num or tonumber(txt) or tostring(txt)
            info.timerComplete = (type(info.timerValue) == "number" and info.timerValue <= 0) or false
        end
    end

    -- Try to find content/type (search descendants on egg then parent)
    local contentNames = {"Content", "content", "Type", "type", "EggType", "ItemType", "Plant", "Pet", "PetType", "Breed", "Contents", "Value", "Name"}
    local content = _findDescendantByNames(egg, contentNames, 4)
    if not content and egg.Parent then
        content = _findDescendantByNames(egg.Parent, contentNames, 3)
        if content and not info.parentInfo then info.parentInfo = egg.Parent.Name end
    end
    
    if content then
        if content:IsA("StringValue") then
            local ok, v = pcall(function() return content.Value end)
            if ok then info.content = v end
        elseif content:IsA("TextLabel") or content:IsA("TextBox") then
            local ok, v = pcall(function() return content.Text end)
            if ok then info.content = v end
        elseif content:IsA("ObjectValue") or content:IsA("Instance") then
            local ok, val = pcall(function() return content.Value end)
            if ok and val then
                info.content = tostring((type(val) == "table" and val.Name) or (typeof(val) == "Instance" and val.Name) or tostring(val))
            end
        end
    end

    -- Store safe custom properties from egg
    for _, child in pairs(egg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("StringValue") or child:IsA("BoolValue") then
            local ok, v = pcall(function() return child.Value end)
            if ok then info.properties[child.Name] = v end
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
        while true do
            -- Only watch while running
            if not State.running then
                task.wait(1)
            else
                local eggs = EggSystem.findEggs()

                for i, egg in pairs(eggs) do
                    local info = EggSystem.getEggInfo(egg)
                    local lastState = lastStates[egg]

                    if lastState and lastState.timerComplete == false and info and info.timerComplete == true then
                        print("⏰ EGG TIMER COMPLETED!")
                        if callback then pcall(callback, egg, info) end
                    end

                    lastStates[egg] = info
                end
            end

            task.wait(1)
        end
    end)
end

-- Debug function: dump full structure of first egg
function EggSystem.dumpEggStructure()
    local eggs = EggSystem.findEggs(1)
    if #eggs == 0 then
        print("❌ No eggs found")
        return
    end
    
    local egg = eggs[1]
    print("🥚 EGG STRUCTURE DUMP: " .. egg.Name)
    print("=" .. string.rep("=", 60))
    
    local function dump(obj, depth, maxDepth)
        if depth > (maxDepth or 5) then return end
        local indent = string.rep("  ", depth)
        
        local info = indent .. "├─ " .. obj.Name .. " (" .. obj.ClassName .. ")"
        
        -- Show values for value types
        if obj:IsA("ValueBase") then
            local ok, val = pcall(function() return obj.Value end)
            info = info .. " = " .. tostring(ok and val or "<?>")
        elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local ok, txt = pcall(function() return obj.Text end)
            info = info .. " = \"" .. tostring(ok and txt or "<?>") .. "\""
        end
        
        print(info)
        
        -- Show attributes
        local attrs = obj:GetAttributes()
        if next(attrs) then
            for k, v in pairs(attrs) do
                print(indent .. "   📌 " .. k .. " = " .. tostring(v))
            end
        end
        
        -- Recurse
        for _, child in pairs(obj:GetChildren()) do
            dump(child, depth + 1, maxDepth)
        end
    end
    
    dump(egg, 0, 4)
    
    -- Also dump parent
    if egg.Parent then
        print("\n📂 PARENT STRUCTURE: " .. egg.Parent.Name)
        print("=" .. string.rep("=", 60))
        dump(egg.Parent, 0, 3)
    end
end

-- Find candidate content locations for a given egg
function EggSystem.findContentCandidates(egg, opts)
    opts = opts or {}
    if not egg then return {} end

    local results = {}
    local seen = {}

    local function push(obj, note)
        if not obj or seen[obj] then return end
        seen[obj] = true
        local path = ""
        local cur = obj
        local parts = {}
        while cur and cur ~= game do
            table.insert(parts, 1, cur.Name)
            cur = cur.Parent
        end
        path = table.concat(parts, ".")

        local entry = {
            instance = obj,
            path = path,
            class = obj.ClassName,
            note = note or "",
            value = nil,
        }

        -- Try to read common fields safely
        if obj:IsA("ValueBase") then
            local ok, v = pcall(function() return obj.Value end)
            entry.value = ok and v or "<error>"
        elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local ok, v = pcall(function() return obj.Text end)
            entry.value = ok and v or "<error>"
        elseif obj:IsA("ObjectValue") then
            local ok, v = pcall(function() return obj.Value end)
            entry.value = ok and (v and tostring(v.Name) or nil) or "<error>"
        else
            -- try attribute read
            local attrs = obj:GetAttributes()
            if next(attrs) then
                entry.value = {}
                for k, v in pairs(attrs) do entry.value[k] = v end
            end
        end

        table.insert(results, entry)
    end

    -- Candidate name patterns to check (children and descendants)
    local nameCandidates = {"Content","content","Type","type","EggType","Pet","Plant","Value","Name","ItemType","Contents","Breed","PetType","HatchResult","Result","DisplayName"}

    -- Check the egg itself and its descendants
    for _, n in ipairs(nameCandidates) do
        local found = egg:FindFirstChild(n, true)
        if found then push(found, "descendant by name: " .. n) end
    end

    -- Check direct children that look like value holders
    for _, child in pairs(egg:GetChildren()) do
        if child:IsA("ValueBase") or child:IsA("ObjectValue") or child:IsA("TextLabel") or child:IsA("TextBox") then
            push(child, "direct child")
        end
    end

    -- Check attributes on egg
    for k, v in pairs(egg:GetAttributes()) do
        push(egg, "attribute: " .. tostring(k))
        break
    end

    -- Check parent container (descendants + common names)
    if egg.Parent then
        for _, n in ipairs(nameCandidates) do
            local found = egg.Parent:FindFirstChild(n, true)
            if found then push(found, "parent descendant: " .. n) end
        end
        for _, child in pairs(egg.Parent:GetChildren()) do
            if child:IsA("ValueBase") or child:IsA("ObjectValue") then push(child, "parent child") end
        end
    end

    -- Nearby containers: search in the common Objects_Physical or PhysicalEggs roots
    local workspace = game:GetService("Workspace")
    local nearbyRoots = {workspace:FindFirstChild("Objects_Physical"), workspace:FindFirstChild("PhysicalEggs"), workspace:FindFirstChild("PhysicalEggsShop"), workspace:FindFirstChild("Garden")}
    for _, root in pairs(nearbyRoots) do
        if root and root:IsA("Instance") then
            for _, n in ipairs(nameCandidates) do
                local found = root:FindFirstChild(n, true)
                if found then push(found, "nearby root descendant: " .. (root.Name or "root") .. ":" .. n) end
            end
        end
    end

    -- Deduplicate results by path and return
    local uniq = {}
    local out = {}
    for _, e in ipairs(results) do
        if not uniq[e.path] then
            uniq[e.path] = true
            table.insert(out, e)
        end
    end

    -- Print summary for convenience
    print(string.format("🔎 Found %d candidate content fields for '%s':", #out, tostring(egg.Name)))
    for i, e in ipairs(out) do
        print(string.format("[%d] %s | %s | value=%s | note=%s", i, e.path, e.class, tostring(e.value), tostring(e.note)))
    end

    return out
end

-- ========== SIMPLE EGG ESP ==========
local EggESP = {}
EggESP.UPDATE_INTERVAL = 2
EggESP.READY_COLOR = Color3.fromRGB(0, 255, 0)
EggESP.TIMER_COLOR = Color3.fromRGB(255, 200, 0)

local function _createESP(egg)
    if not egg or not egg:IsA("Instance") then return nil end
    if egg:FindFirstChild("EggESP") then return egg:FindFirstChild("EggESP").Billboard.TextLabel end

    local adornee = nil
    if egg:IsA("BasePart") then adornee = egg elseif egg:IsA("Model") then adornee = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart") end
    if not adornee then return nil end

    local folder = Instance.new("Folder")
    folder.Name = "EggESP"
    folder.Parent = egg

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Billboard"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 140, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = folder

    local text = Instance.new("TextLabel")
    text.Name = "TextLabel"
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0
    text.TextColor3 = EggESP.TIMER_COLOR
    text.Text = "Loading..."
    text.Parent = billboard

    return text
end

local function _updateESPForEgg(egg)
    if not egg then return end
    local label = nil
    if egg:FindFirstChild("EggESP") and egg.EggESP:FindFirstChild("Billboard") then
        label = egg.EggESP.Billboard:FindFirstChild("TextLabel")
    end
    if not label then label = _createESP(egg) end
    if not label then return end

    -- Prefer attribute-based reporting when available
    local ready = egg:GetAttribute("READY") or egg:GetAttribute("IsReady") or egg:GetAttribute("Ready")
    local timeLeft = egg:GetAttribute("TimeToHatch") or egg:GetAttribute("TimeLeft") or egg:GetAttribute("Timer")

    if ready then
        label.Text = "READY"
        label.TextColor3 = EggESP.READY_COLOR
    elseif type(timeLeft) == "number" and timeLeft > 0 then
        label.Text = string.format("⏳ %ds", math.ceil(timeLeft))
        label.TextColor3 = EggESP.TIMER_COLOR
    else
        -- Fallback to EggSystem.getEggInfo for timers/content
        local ok, info = pcall(function() return EggSystem.getEggInfo(egg) end)
        if ok and info and info.timerValue and type(info.timerValue) == "number" then
            if info.timerValue <= 0 then
                label.Text = "READY"
                label.TextColor3 = EggESP.READY_COLOR
            else
                label.Text = string.format("⏳ %ds", math.ceil(info.timerValue))
                label.TextColor3 = EggESP.TIMER_COLOR
            end
        else
            local ok2, info = pcall(function() return EggSystem.getEggInfo(egg) end)
            if ok2 and info then
                local contentText = info.content and tostring(info.content) or nil
                if info.timerValue and type(info.timerValue) == "number" then
                    if info.timerValue <= 0 then
                        label.Text = contentText and ("READY: " .. contentText) or "READY"
                        label.TextColor3 = EggESP.READY_COLOR
                    else
                        label.Text = contentText and (string.format("⏳ %ds | %s", math.ceil(info.timerValue), contentText)) or string.format("⏳ %ds", math.ceil(info.timerValue))
                        label.TextColor3 = EggESP.TIMER_COLOR
                    end
                else
                    label.Text = contentText or "..."
                    label.TextColor3 = EggESP.TIMER_COLOR
                end
            else
                label.Text = "..."
                label.TextColor3 = EggESP.TIMER_COLOR
            end
        end
    end
end

local function _scanAndUpdateESP()
    local eggs = {}

    -- Prefer EggSystem.findEggs (already filters ownership/proximity)
    local ok, res = pcall(function() return EggSystem.findEggs(100) end)
    if ok and type(res) == "table" and #res > 0 then
        eggs = res
    else
        -- Fallback: scan common Objects_Physical container
        local farmObjects = workspace:FindFirstChild("Objects_Physical") or workspace:FindFirstChild("Objects")
        if farmObjects then
            for _, e in ipairs(farmObjects:GetChildren()) do
                if e:GetAttribute("IsEgg") or tostring(e.Name):lower():match("egg") then
                    table.insert(eggs, e)
                end
            end
        end
    end

    local seen = {}
    for _, egg in ipairs(eggs) do
        -- Respect global toggle
        if not Config["ESP Enabled"] then break end

        local owned = nil
        pcall(function() owned = EggSystem.isOwnedByPlayer(egg) end)
        if owned == true then
            pcall(function() _updateESPForEgg(egg) end)
            seen[egg] = true
        end
    end

    -- Remove orphan ESP folders for eggs no longer present/owned
    for _, folder in pairs(workspace:GetDescendants()) do
        if folder.Name == "EggESP" and folder.Parent and not seen[folder.Parent] then
            pcall(function() folder:Destroy() end)
        end
    end
end

-- Start periodic updater
task.spawn(function()
    while true do
        pcall(_scanAndUpdateESP)
        task.wait(EggESP.UPDATE_INTERVAL or 2)
    end
end)


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
    title.Text = string.format("🌱 Control — %s", VERSION)
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
    addToggle("ESP Enabled", "ESP Enabled", 7)
    
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
    
    eb.LayoutOrder = 8
    eb.MouseButton1Click:Connect(function()
        local eggReport = EggSystem.checkAllEggs()
        Log(string.format("🔍 Found %d eggs:", #eggReport))
        for i, egg in pairs(eggReport) do
            Log(string.format("  [%d] %s | Timer: %s | Content: %s", i, egg.name, tostring(egg.timerValue), egg.content or "N/A"))
        end
    end)
    
    -- Console display (in-GUI)
    local consoleFrame = Instance.new("ScrollingFrame")
    consoleFrame.Size = UDim2.new(1, 0, 0, 120)
    consoleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    consoleFrame.BorderSizePixel = 0
    consoleFrame.LayoutOrder = 9
    consoleFrame.Parent = content
    consoleFrame.ScrollBarThickness = 6
    Instance.new("UICorner", consoleFrame).CornerRadius = UDim.new(0, 5)

    local consoleLayout = Instance.new("UIListLayout")
    consoleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    consoleLayout.Padding = UDim.new(0, 4)
    consoleLayout.Parent = consoleFrame

    local function appendConsoleLine(timeStr, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Text = string.format("[%s] %s", timeStr or os.date("%X"), text or "")
        lbl.Parent = consoleFrame
        consoleFrame.CanvasSize = UDim2.new(0, 0, 0, consoleLayout.AbsoluteContentSize.Y + 8)
        consoleFrame.CanvasPosition = Vector2.new(0, math.max(0, consoleLayout.AbsoluteContentSize.Y - consoleFrame.AbsoluteSize.Y))
    end

    -- Populate with existing logs
    for i = 1, #State.console do
        local e = State.console[i]
        pcall(function() appendConsoleLine(e.time, e.text) end)
    end

    -- Expose append function to GUI variable later

    -- Status display
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, 0, 0, 70)
    sf.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sf.BorderSizePixel = 0
    sf.LayoutOrder = 10
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
    sb.LayoutOrder = 10
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
        appendConsole = appendConsoleLine,
        consoleFrame = consoleFrame,
        consoleLayout = consoleLayout,
        version = VERSION,
    }
end

-- ========== MAIN EXECUTION ==========
print("✨ Starting GUI...")
local GUI = buildGUI()

-- Print version to log/GUI
Log(string.format("✓ Grow a Garden loaded — version %s", VERSION))

-- Start egg watcher (checks eggs every second when running)
EggSystem.watchEggs(function(egg, info)
    print(string.format("🎉 Egg hatched: %s -> %s", info.name, info.content or "Unknown"))
end)

print("✓ Grow a Garden loaded!")
print("✓ GUI: Bottom-right corner")
print("✓ Egg system: Active")
print("✓ All systems ready")
