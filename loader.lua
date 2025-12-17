-- Loadstring Loader for Clean Implementation
-- Copy this entire script and execute it with loadstring

local url = "https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/clean_implementation.lua"

print("🔄 Loading Grow a Garden...")
print("📡 Fetching from:", url)

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if success and result then
    print("✅ Script downloaded successfully!")
    print("⚡ Executing...")
    
    local executeSuccess, executeResult = pcall(function()
        return loadstring(result)()
    end)
    
    if executeSuccess then
        print("✅ Script loaded successfully!")
        return executeResult
    else
        warn("❌ Failed to execute script:", executeResult)
    end
else
    warn("❌ Failed to download script:", result)
end
