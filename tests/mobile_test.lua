-- Mobile Executor Luck Boost Test
-- Copy-paste this entire script into your mobile executor
-- Works with: Arceus X, Fluxus, Delta, Codex, etc.

print("=== LUCK BOOST MOBILE TEST ===")
print("Loading module...")

-- Load the deobf module (adjust path based on your executor)
local Deobf
local loadSuccess = pcall(function()
    -- Try readfile first (most common)
    if readfile then
        Deobf = loadstring(readfile("Grow_a_Garden.deobf.lua"))()
    -- Try dofile as fallback
    elseif dofile then
        Deobf = dofile("Grow_a_Garden.deobf.lua")
    else
        error("No file loading function available")
    end
end)

if not loadSuccess or not Deobf then
    print("❌ Failed to load module!")
    print("Make sure Grow_a_Garden.deobf.lua is in your workspace")
    return
end

print("✓ Module loaded!\n")

-- Test cases
local tests = {
    {n="No boost", b=0.10, p=0, e=0.10},
    {n="50% boost", b=0.10, p=50, e=0.15},
    {n="100% boost", b=0.10, p=100, e=0.20},
    {n="200% boost", b=0.25, p=200, e=0.75},
}

local passed = 0
for i, t in ipairs(tests) do
    local cfg = {LuckBase = t.b, LuckBoostPercent = t.p}
    local result = Deobf.GetEffectiveLuck(cfg)
    local ok = math.abs(result - t.e) < 0.001
    
    print(string.format("Test %d: %s", i, t.n))
    print(string.format("  %.2f%% + %d%% boost", t.b*100, t.p))
    print(string.format("  Expected: %.2f%%", t.e*100))
    print(string.format("  Got:      %.2f%%", result*100))
    print(string.format("  %s\n", ok and "✓ PASS" or "✗ FAIL"))
    
    if ok then passed = passed + 1 end
end

-- Summary
print(string.format("=== Results: %d/%d passed ===", passed, #tests))
if passed == #tests then
    print("✓ All tests passed!")
    print("Luck boost is working correctly!")
else
    print("✗ Some tests failed")
end

-- Create simple GUI
print("\nCreating GUI...")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local sg = Instance.new("ScreenGui")
sg.Name = "LuckTest"
sg.ResetOnSpawn = false

local function safeParent()
    pcall(function()
        if player.PlayerGui then
            sg.Parent = player.PlayerGui
        elseif gethui then
            sg.Parent = gethui()
        elseif game.CoreGui then
            sg.Parent = game.CoreGui
        end
    end)
end
safeParent()

local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 280, 0, 180)
f.Position = UDim2.new(0.5, -140, 0.3, 0)
f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
f.BorderSizePixel = 2
f.BorderColor3 = passed == #tests and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 165, 0)

local t = Instance.new("TextLabel", f)
t.Size = UDim2.new(1, 0, 0, 30)
t.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
t.Text = "Luck Boost Test"
t.TextColor3 = Color3.fromRGB(255, 255, 255)
t.Font = Enum.Font.GothamBold
t.TextSize = 14

local r = Instance.new("TextLabel", f)
r.Size = UDim2.new(1, -20, 1, -50)
r.Position = UDim2.new(0, 10, 0, 35)
r.BackgroundTransparency = 1
r.TextColor3 = Color3.fromRGB(255, 255, 255)
r.Font = Enum.Font.Code
r.TextSize = 12
r.TextXAlignment = Enum.TextXAlignment.Left
r.TextYAlignment = Enum.TextYAlignment.Top
r.TextWrapped = true
r.Text = string.format([[Tests Passed: %d/%d

Status: %s

Example:
Base: 10%%
Boost: +50%%
Result: 15%% ✓

Luck boost ready!]], 
    passed, #tests,
    passed == #tests and "✓ ALL PASS" or "⚠ CHECK CONSOLE"
)

local b = Instance.new("TextButton", f)
b.Size = UDim2.new(0, 60, 0, 25)
b.Position = UDim2.new(1, -70, 1, -30)
b.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
b.Text = "Close"
b.TextColor3 = Color3.fromRGB(255, 255, 255)
b.Font = Enum.Font.Gotham
b.TextSize = 12
b.MouseButton1Click:Connect(function() sg:Destroy() end)

print("✓ GUI created! Check your screen.")
print("\n=== TEST COMPLETE ===")
