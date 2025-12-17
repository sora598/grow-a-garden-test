-- INJECTION VERIFICATION SCRIPT
-- This will diagnose any issues with loading the GUI

print("=== Starting Injection Verification ===")
print("Time:", os.date("%H:%M:%S"))
print()

-- Test 1: Check HttpGet availability
print("[1/6] Testing HttpGet availability...")
local httpGetAvailable = false
local httpGetError = nil

local success, result = pcall(function()
    local testData = game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/gui.lua")
    if testData and #testData > 0 then
        httpGetAvailable = true
        print("✓ HttpGet works!")
        print("✓ Downloaded " .. #testData .. " bytes")
        return testData
    end
end)

if not success then
    httpGetError = tostring(result)
    print("✗ HttpGet failed:", httpGetError)
    print()
    print("=== DIAGNOSIS ===")
    print("Your executor doesn't support HttpGet or HttpService is disabled.")
    print()
    print("SOLUTION: Use local files instead:")
    print('  1. Download gui.lua to your executor workspace')
    print('  2. Run: loadstring(readfile("gui.lua"))()')
    return
end

local scriptContent = result

-- Test 2: Syntax validation
print()
print("[2/6] Validating script syntax...")
local syntaxValid = false
local syntaxError = nil

success, result = pcall(function()
    return loadstring(scriptContent)
end)

if success and result then
    syntaxValid = true
    print("✓ Script syntax is valid!")
else
    syntaxError = tostring(result)
    print("✗ Syntax error:", syntaxError)
    return
end

-- Test 3: Check game services
print()
print("[3/6] Checking required game services...")
local services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
}

for name, service in pairs(services) do
    if service then
        print("✓", name, "- Available")
    else
        print("✗", name, "- Missing!")
    end
end

-- Test 4: Check player
print()
print("[4/6] Checking player...")
local player = services.Players.LocalPlayer
if player then
    print("✓ LocalPlayer found:", player.Name)
else
    print("✗ LocalPlayer not found!")
    return
end

-- Test 5: Test deobf module loading
print()
print("[5/6] Testing main module load...")
local deobfSuccess, deobfResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/src/Grow_a_Garden.deobf.lua"))()
end)

if deobfSuccess and deobfResult then
    print("✓ Main module loaded successfully!")
    print("✓ Module type:", type(deobfResult))
    
    -- Check for expected functions
    if deobfResult.GetEffectiveLuck then
        print("✓ GetEffectiveLuck function found")
        
        -- Test luck calculation
        local testConfig = { LuckBase = 0.10, LuckBoostPercent = 50 }
        local luck = deobfResult.GetEffectiveLuck(testConfig)
        print("✓ Test luck calculation: " .. string.format("%.2f%%", luck * 100))
    end
else
    print("✗ Main module failed to load:", tostring(deobfResult))
    return
end

-- Test 6: Execute the full GUI
print()
print("[6/6] Executing full GUI script...")
local guiSuccess, guiError = pcall(function()
    loadstring(scriptContent)()
end)

if guiSuccess then
    print("✓ GUI script executed successfully!")
    print("✓ Check your screen for the GUI window")
    print()
    print("=== GUI CONTROLS ===")
    print("• Drag the title bar to move")
    print("• Click '—' to minimize")
    print("• Click '✕' to close")
    print("• Configure settings with toggles/sliders")
    print("• Press START to begin automation")
else
    print("✗ GUI execution failed:", tostring(guiError))
    print()
    print("=== ERROR DETAILS ===")
    print(tostring(guiError))
end

print()
print("=== VERIFICATION COMPLETE ===")
print()

-- Summary
print("=== SUMMARY ===")
print("HttpGet:", httpGetAvailable and "✓ Working" or "✗ Failed")
print("Syntax:", syntaxValid and "✓ Valid" or "✗ Invalid")
print("Services:", "✓ Available")
print("Module:", deobfSuccess and "✓ Loaded" or "✗ Failed")
print("GUI:", guiSuccess and "✓ Injected" or "✗ Failed")

if httpGetAvailable and syntaxValid and deobfSuccess and guiSuccess then
    print()
    print("✓✓✓ ALL CHECKS PASSED ✓✓✓")
    print("The script is injected properly!")
else
    print()
    print("⚠️ SOME CHECKS FAILED")
    print("See details above for troubleshooting")
end
