-- VERIFIED WORKING LOADSTRINGS
-- Repo is public and accessible ✓

-- ========================================
-- QUICK TEST (Run this first to verify)
-- ========================================
loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/tests/mobile_test.lua"))()

-- ========================================
-- LOAD MAIN MODULE (for your script)
-- ========================================
local Deobf = loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/src/Grow_a_Garden.deobf.lua"))()

-- Then use it:
local config = {
    LuckBase = 0.10,
    LuckBoostPercent = 50,
}
local effectiveLuck = Deobf.GetEffectiveLuck(config)
print("Luck:", effectiveLuck * 100 .. "%")

-- ========================================
-- COMMON ISSUES & FIXES
-- ========================================

-- If you get "HttpGet is not available":
-- → Your executor doesn't support HttpGet
-- → Use local files instead: loadstring(readfile("tests/mobile_test.lua"))()

-- If you get "attempt to call a nil value":
-- → The module didn't load properly
-- → Check your executor supports loadstring
-- → Try: local success, result = pcall(loadstring, game:HttpGet("..."))

-- If you get "404: Not Found":
-- → Make sure repo is PUBLIC (not private)
-- → Check URL is correct (no typos)
-- → Try opening the raw URL in browser first

-- ========================================
-- ALTERNATIVE: LOCAL FILES
-- ========================================
-- If HttpGet doesn't work, download files and use:
local Deobf = loadstring(readfile("src/Grow_a_Garden.deobf.lua"))()
loadstring(readfile("tests/mobile_test.lua"))()
