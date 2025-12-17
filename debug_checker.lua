-- Grow a Garden - Debug Checker Script
-- Displays what's being triggered and the game structure

print("=" .. string.rep("=", 68) .. "=")
print("🔍 GROW A GARDEN - DEBUG CHECKER")
print("=" .. string.rep("=", 68) .. "=\n")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")

-- ========== LOGGING HELPER ==========
local function log(level, category, message, data)
    local colors = {
        INFO = "🔵",
        WARN = "🟡",
        ERROR = "🔴",
        SUCCESS = "✅",
        FOUND = "📍",
    }
    local color = colors[level] or "⚪"
    
    if data then
        print(string.format("%s [%s] %s: %s", color, category, message, tostring(data)))
    else
        print(string.format("%s [%s] %s", color, category, message))
    end
end

-- ========== WORKSPACE STRUCTURE ==========
log("INFO", "WORKSPACE", "Scanning game structure...")
print()

local function scanObject(obj, depth, maxDepth)
    if depth > (maxDepth or 3) then return end
    
    local indent = string.rep("  ", depth)
    local objType = obj:IsA("Folder") and "📁" or obj:IsA("Model") and "🏠" or obj:IsA("BasePart") and "🟦" or "❓"
    
    print(indent .. objType .. " " .. obj.Name .. " (" .. obj.ClassName .. ")")
    
    for _, child in pairs(obj:GetChildren()) do
        scanObject(child, depth + 1, maxDepth)
    end
end

log("INFO", "STRUCTURE", "Workspace contents (depth: 2):")
print()
for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name ~= "Terrain" and obj.Name ~= "Camera" then
        scanObject(obj, 0, 2)
    end
end
print()

-- ========== EGGS DETECTION ==========
log("INFO", "EGGS", "Scanning for eggs...")
print()

local function findEggs(parent, results)
    results = results or {}
    
    for _, obj in pairs(parent:GetChildren()) do
        local name = obj.Name:lower()
        
        if name:match("egg") or obj:FindFirstChild("Timer") or obj:FindFirstChild("timer") then
            table.insert(results, obj)
            log("FOUND", "EGGS", "Found egg object", obj.Name)
            
            -- Show egg structure
            print("    └─ Structure:")
            for _, child in pairs(obj:GetChildren()) do
                print(string.format("       ├─ %s (%s)", child.Name, child.ClassName))
                if child:IsA("ValueBase") then
                    print(string.format("       │  └─ Value: %s", tostring(child.Value)))
                end
            end
            print()
        end
        
        if obj:IsA("Model") or obj:IsA("Folder") then
            findEggs(obj, results)
        end
    end
    
    return results
end

local eggs = findEggs(workspace)
log("SUCCESS", "EGGS", "Total eggs found", #eggs)
print()

-- ========== REMOTES DETECTION ==========
log("INFO", "REMOTES", "Scanning for RemoteEvents and RemoteFunctions...")
print()

local function findRemotes(parent, results)
    results = results or {events = {}, functions = {}}
    
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            table.insert(results.events, obj)
            log("FOUND", "REMOTES", "RemoteEvent", obj.Name)
        elseif obj:IsA("RemoteFunction") then
            table.insert(results.functions, obj)
            log("FOUND", "REMOTES", "RemoteFunction", obj.Name)
        end
        
        if obj:IsA("Folder") or obj:IsA("Model") then
            findRemotes(obj, results)
        end
    end
    
    return results
end

local remotes = findRemotes(workspace)
log("SUCCESS", "REMOTES", "Total RemoteEvents found", #remotes.events)
log("SUCCESS", "REMOTES", "Total RemoteFunctions found", #remotes.functions)
print()

-- ========== PLANTS DETECTION ==========
log("INFO", "PLANTS", "Scanning for plants...")
print()

local function findPlants(parent, results)
    results = results or {}
    
    for _, obj in pairs(parent:GetChildren()) do
        local name = obj.Name:lower()
        
        if name:match("plant") or name:match("crop") or name:match("fruit") then
            table.insert(results, obj)
            log("FOUND", "PLANTS", "Found plant", obj.Name)
            
            -- Show attributes
            local attrs = obj:GetAttributes()
            if next(attrs) then
                print("    └─ Attributes:")
                for k, v in pairs(attrs) do
                    print(string.format("       ├─ %s = %s", k, tostring(v)))
                end
            end
            
            -- Show properties
            local hasReady = obj:FindFirstChild("Ready")
            local hasCollect = obj:FindFirstChild("COLLECT")
            if hasReady or hasCollect then
                print("    └─ Properties:")
                if hasReady then print("       ├─ Ready (found)") end
                if hasCollect then print("       ├─ COLLECT (found)") end
            end
            print()
        end
        
        if obj:IsA("Model") or obj:IsA("Folder") then
            findPlants(obj, results)
        end
    end
    
    return results
end

local plants = findPlants(workspace)
log("SUCCESS", "PLANTS", "Total plants found", #plants)
print()

-- ========== PLAYER BACKPACK ==========
log("INFO", "BACKPACK", "Scanning player backpack...")
print()

local backpack = player:FindFirstChild("Backpack")
if backpack then
    local tools = {}
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
            log("FOUND", "BACKPACK", "Tool", item.Name)
            
            local attrs = item:GetAttributes()
            if next(attrs) then
                print("    └─ Attributes:")
                for k, v in pairs(attrs) do
                    print(string.format("       ├─ %s = %s", k, tostring(v)))
                end
            end
            print()
        end
    end
    log("SUCCESS", "BACKPACK", "Total tools found", #tools)
else
    log("WARN", "BACKPACK", "Backpack not found")
end
print()

-- ========== SUMMARY REPORT ==========
print("=" .. string.rep("=", 68) .. "=")
print("📊 SUMMARY")
print("=" .. string.rep("=", 68) .. "=\n")

print(string.format("📍 Eggs detected:          %d", #eggs))
print(string.format("📍 Plants detected:        %d", #plants))
print(string.format("📍 RemoteEvents:           %d", #remotes.events))
print(string.format("📍 RemoteFunctions:        %d", #remotes.functions))
print(string.format("📍 Backpack tools:         %d", backpack and #backpack:GetChildren() or 0))
print()

-- ========== SAFE OPERATION TEST ==========
log("INFO", "TEST", "Testing safe operations on first egg...")
print()

if #eggs > 0 then
    local egg = eggs[1]
    log("INFO", "TEST", "Testing on egg", egg.Name)
    
    -- Test 1: Get basic info
    pcall(function()
        log("INFO", "TEST", "✓ Egg object is valid")
    end)
    
    -- Test 2: Check for PrimaryPart
    local ok1, res1 = pcall(function()
        if egg:IsA("Model") then
            local pp = egg.PrimaryPart
            if pp then
                log("SUCCESS", "TEST", "PrimaryPart found", pp.Name)
            else
                log("WARN", "TEST", "PrimaryPart is nil (Model has no primary part set)")
            end
        elseif egg:IsA("BasePart") then
            log("SUCCESS", "TEST", "Egg is a BasePart, can use Position directly")
        else
            log("WARN", "TEST", "Egg is a " .. egg.ClassName .. " (not Model or BasePart)")
        end
    end)
    if not ok1 then
        log("ERROR", "TEST", "PrimaryPart check failed", tostring(res1))
    end
    
    -- Test 3: Check for Timer
    local timer = egg:FindFirstChild("Timer") or egg:FindFirstChild("timer")
    if timer then
        log("SUCCESS", "TEST", "Timer found", timer.ClassName)
        pcall(function()
            log("INFO", "TEST", "Timer value", timer.Value)
        end)
    else
        log("WARN", "TEST", "No Timer property found on egg")
    end
    
    -- Test 4: Check for Content
    local content = egg:FindFirstChild("Content") or egg:FindFirstChild("content") or egg:FindFirstChild("Type")
    if content then
        log("SUCCESS", "TEST", "Content property found", content.ClassName)
        pcall(function()
            log("INFO", "TEST", "Content value", content.Value or content.Text or "N/A")
        end)
    else
        log("WARN", "TEST", "No Content/Type property found on egg")
    end
    
else
    log("WARN", "TEST", "No eggs found to test")
end

print()
print("=" .. string.rep("=", 68) .. "=")
print("✅ DEBUG CHECK COMPLETE")
print("=" .. string.rep("=", 68) .. "=")
