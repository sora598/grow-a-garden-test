-- MINIMAL TEST - Copy and paste this entire block into your executor
-- This will verify loadstring is working

print("=== Testing GitHub LoadString ===")

-- Test 1: Check if HttpGet works
local httpGetWorks = false
local httpGetError = nil
pcall(function()
    local test = game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/tests/mobile_test.lua")
    if test and #test > 0 then
        httpGetWorks = true
    end
end)

if httpGetWorks then
    print("✓ HttpGet works!")
    print("✓ Repository is accessible!")
    print("\nLoading module...")
    
    -- Test 2: Load and execute
    local success, result = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/tests/mobile_test.lua"))()
    end)
    
    if success then
        print("✓ Script executed successfully!")
    else
        print("✗ Script failed to execute:")
        print(tostring(result))
    end
else
    print("✗ HttpGet failed or is not available")
    print("Error:", tostring(httpGetError))
    print("\n=== Alternative Method ===")
    print("Download files to your executor's workspace, then use:")
    print('loadstring(readfile("tests/mobile_test.lua"))()')
end
