-- Decompiler Test Script for Grow a Garden
-- This script attempts to decompile the obfuscated code using plusgiant5 API

local API = "http://api.plusgiant5.com"

-- Get the obfuscated script URL or content
local OBFUSCATED_URL = "https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/Grow%20a%20Garden.lua"

print("🔍 Starting decompilation process...")
print("⏳ This may take a while due to API rate limits...")

local last_call = 0
local function call(konstantType, bytecode)
    local time_elapsed = os.clock() - last_call
    if time_elapsed <= 0.5 then
        task.wait(0.5 - time_elapsed)
    end
    
    local success, httpResult = pcall(function()
        return request({
            Url = API .. konstantType,
            Body = bytecode,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "text/plain"
            },
        })
    end)
    
    last_call = os.clock()
    
    if not success then
        return `-- Error making HTTP request:\n\n--[[\n{httpResult}\n--]]`
    end
    
    if httpResult.StatusCode ~= 200 then
        return `-- API error (Status {httpResult.StatusCode}):\n\n--[[\n{httpResult.Body}\n--]]`
    else
        return httpResult.Body
    end
end

-- Method 1: Try to decompile from URL
local function decompileFromURL()
    print("📥 Downloading obfuscated code...")
    local success, obfuscatedCode = pcall(function()
        return game:HttpGet(OBFUSCATED_URL)
    end)
    
    if not success then
        warn("❌ Failed to download:", obfuscatedCode)
        return nil
    end
    
    print("✅ Downloaded successfully")
    print("📦 Code size:", #obfuscatedCode, "bytes")
    
    -- Try to get bytecode by loading the script
    print("🔄 Converting to bytecode...")
    local func, loadErr = loadstring(obfuscatedCode)
    if not func then
        warn("❌ Failed to load code:", loadErr)
        return nil
    end
    
    -- Try to get bytecode using debug functions
    local bytecode = nil
    if getscriptbytecode then
        print("🔍 Attempting to get bytecode using getscriptbytecode...")
        
        -- Create a temporary LocalScript
        local tempScript = Instance.new("LocalScript")
        tempScript.Name = "TempDecompileScript"
        tempScript.Source = obfuscatedCode
        tempScript.Parent = game:GetService("CoreGui")
        
        local success, result = pcall(getscriptbytecode, tempScript)
        if success then
            bytecode = result
            print("✅ Got bytecode:", #bytecode, "bytes")
        else
            warn("❌ getscriptbytecode failed:", result)
        end
        
        tempScript:Destroy()
    else
        warn("⚠️ getscriptbytecode not available in this executor")
    end
    
    if not bytecode then
        print("⚠️ Trying direct decompilation with source code...")
        bytecode = obfuscatedCode
    end
    
    print("🌐 Sending to decompiler API...")
    local result = call("/konstant/decompile", bytecode)
    
    return result
end

-- Method 2: Try to find and decompile existing script in workspace
local function decompileFromWorkspace()
    print("🔍 Searching for script in workspace...")
    
    for _, script in ipairs(game:GetDescendants()) do
        if script:IsA("LocalScript") or script:IsA("Script") or script:IsA("ModuleScript") then
            if script.Name:find("Garden") or script.Name:find("GAG") then
                print("📜 Found potential script:", script:GetFullName())
                
                if getscriptbytecode then
                    local success, bytecode = pcall(getscriptbytecode, script)
                    if success then
                        print("✅ Got bytecode from:", script.Name)
                        print("🌐 Sending to API...")
                        local result = call("/konstant/decompile", bytecode)
                        return result, script.Name
                    end
                end
            end
        end
    end
    
    return nil, "No matching script found"
end

-- Main execution
print("\n" .. string.rep("=", 60))
print("METHOD 1: Decompiling from URL")
print(string.rep("=", 60))

local result = decompileFromURL()

if result and not result:find("Error") then
    print("\n✅ DECOMPILATION SUCCESSFUL!")
    print("📄 Result length:", #result, "characters")
    print("\n" .. string.rep("-", 60))
    print("DECOMPILED CODE (first 500 chars):")
    print(string.rep("-", 60))
    print(result:sub(1, 500))
    print("...")
    print(string.rep("-", 60))
    
    -- Try to save to clipboard if available
    if setclipboard then
        setclipboard(result)
        print("📋 Full result copied to clipboard!")
    end
    
    -- Try to save to file if available
    if writefile then
        local filename = "decompiled_grow_a_garden_" .. os.time() .. ".lua"
        writefile(filename, result)
        print("💾 Saved to:", filename)
    end
else
    print("\n❌ METHOD 1 FAILED")
    print(result or "Unknown error")
    
    print("\n" .. string.rep("=", 60))
    print("METHOD 2: Trying to find script in workspace")
    print(string.rep("=", 60))
    
    local result2, scriptName = decompileFromWorkspace()
    if result2 and not result2:find("Error") then
        print("\n✅ DECOMPILATION SUCCESSFUL from:", scriptName)
        print("📄 Result length:", #result2, "characters")
        
        if setclipboard then
            setclipboard(result2)
            print("📋 Result copied to clipboard!")
        end
        
        if writefile then
            local filename = "decompiled_" .. scriptName:gsub("%W", "_") .. "_" .. os.time() .. ".lua"
            writefile(filename, result2)
            print("💾 Saved to:", filename)
        end
    else
        print("\n❌ METHOD 2 ALSO FAILED")
        print(result2 or "Unknown error")
        
        print("\n" .. string.rep("=", 60))
        print("📝 TROUBLESHOOTING:")
        print(string.rep("=", 60))
        print("1. Make sure you have an active internet connection")
        print("2. Check if API is online: http://api.plusgiant5.com")
        print("3. Your executor must support: request, getscriptbytecode")
        print("4. Try running the obfuscated script first, then run this")
        print("5. API may have rate limits or be temporarily down")
    end
end

print("\n✅ Decompiler test completed")
