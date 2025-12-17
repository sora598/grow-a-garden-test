-- Loadstring Loader for Clean Implementation
-- Copy this entire script and execute it with loadstring

local url = "https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/clean_implementation.lua"

print("🔄 Loading Grow a Garden...")
print("📡 Fetching from:", url)

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if not success then
    warn("❌ Failed to download script:", result)
    return
end

if not result or result == "" then
    warn("❌ Downloaded script is empty!")
    return
end

print("✅ Script downloaded successfully! Size:", #result, "bytes")
print("⚡ Compiling...")

local compiledFunc, compileError = loadstring(result)
if not compiledFunc then
    warn("❌ Failed to compile script:", compileError)
    return
end

print("✅ Compiled successfully!")
print("⚡ Executing...")

local executeSuccess, executeResult = pcall(compiledFunc)

if not executeSuccess then
    warn("❌ Failed to execute script:")
    warn(executeResult)
    return
end

print("✅ Script loaded successfully!")
return executeResult
