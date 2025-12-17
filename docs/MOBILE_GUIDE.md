# Mobile Executor Instructions

## Quick Start

### Step 1: Transfer Files to Mobile
Use one of these methods:

**Option A - Direct File Copy:**
1. Connect phone to PC via USB
2. Copy these files to your executor's workspace folder:
   - `Grow_a_Garden.deobf.lua`
   - `mobile_test.lua`

**Option B - Pastebin/GitHub:**
1. Upload `mobile_test.lua` to [pastebin.com](https://pastebin.com)
2. In executor, use: `loadstring(game:HttpGet("YOUR_PASTEBIN_RAW_URL"))()`

**Option C - Cloud Storage:**
1. Upload to Google Drive/Dropbox
2. Get direct download link
3. Use `HttpGet` in executor

### Step 2: Run the Test

**In your mobile executor:**

```lua
-- If files are in workspace:
loadstring(readfile("mobile_test.lua"))()

-- OR execute directly (copy entire mobile_test.lua content)
-- Just paste the whole script and run
```

### Step 3: Check Results

✓ **Console output** shows test results  
✓ **GUI window** appears with summary  
✓ If all pass → Luck boost works!

---

## Using Luck Boost In-Game

Once verified, use it with your main script:

```lua
-- Load the module
local Deobf = loadstring(readfile("Grow_a_Garden.deobf.lua"))()

-- Your config
local config = {
    LuckBase = 0.10,           -- 10% base luck
    LuckBoostPercent = 50,      -- +50% boost
    LuckCapMax = 0.80,          -- optional: max 80%
    ["Auto Collect Fruits"] = true,
    -- ... other settings
}

-- Attach remotes (find these in your game)
Deobf.attachRemotes({
    BuyPetEgg = game:GetService("ReplicatedStorage").Remotes.BuyPetEgg,
    Crops = {
        Collect = game:GetService("ReplicatedStorage").Remotes.Crops.Collect
    },
    -- ... etc
})

-- Run the cycle (this will show luck on pet ESP)
local api = {}  -- your API if you have one
local helpers = {
    InventoryChecker = Deobf.InventoryChecker.new(game.Players.LocalPlayer)
}

while true do
    Deobf.runCycle(game.Players.LocalPlayer, config, api, helpers)
    task.wait(1)
end
```

**What you'll see:**
- Pet ESP labels show: `Luck: 15.00%` (for 10% + 50% boost)
- The calculation happens automatically each cycle
- Luck value updates in real-time

---

## Executor-Specific Tips

### Arceus X / Delta X
```lua
-- Use readfile
loadstring(readfile("mobile_test.lua"))()
```

### Fluxus Mobile
```lua
-- Usually supports readfile
loadstring(readfile("mobile_test.lua"))()
```

### Codex
```lua
-- May need full path
loadstring(readfile("workspace/mobile_test.lua"))()
```

### If readfile doesn't work
Copy the entire contents of `mobile_test.lua` and paste directly into the executor's script box, then execute.

---

## Troubleshooting

**"Module not found"**
- Check file is in correct workspace folder
- Try full path: `readfile("workspace/Grow_a_Garden.deobf.lua")`
- Or paste the deobf module content directly into your script

**"No GUI appears"**
- Check console output first (tests still run)
- Some executors block GUI creation
- Results are printed to console anyway

**"Tests fail"**
- Check if `Deobf.GetEffectiveLuck` exists
- Verify the deobf module loaded correctly
- See console for specific errors

**Need remote references?**
Use Remote Spy in your executor to find the correct remote paths for your game.

---

## Files You Need

1. ✅ `Grow_a_Garden.deobf.lua` - Main module with luck integration
2. ✅ `mobile_test.lua` - Quick verification script
3. ✅ `luck_boost.lua` - Optional (module has fallback)

**Minimum:** Just `Grow_a_Garden.deobf.lua` + `mobile_test.lua`
