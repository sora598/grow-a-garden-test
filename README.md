# Grow a Garden - Luck Boost Module

Enhanced deobfuscated module for "Grow a Garden" Roblox game with integrated luck boost system.

## 📁 Project Structure

```
grow-a-garden-test/
├── src/                          # Source code
│   ├── Grow_a_Garden.deobf.lua  # Main deobfuscated module
│   └── luck_boost.lua            # Luck calculation utilities
├── tests/                        # Test scripts
│   └── mobile_test.lua           # Mobile executor verification
└── docs/                         # Documentation
    └── MOBILE_GUIDE.md           # Mobile usage instructions
```

## 🚀 Quick Start

### For Mobile Executors

1. **Copy files to your executor's workspace:**
   - `src/Grow_a_Garden.deobf.lua`
   - `tests/mobile_test.lua`

2. **Run verification test:**
   ```lua
   loadstring(readfile("mobile_test.lua"))()
   ```

3. **Use in your script:**
   ```lua
   local Deobf = loadstring(readfile("Grow_a_Garden.deobf.lua"))()
   
   local config = {
       LuckBase = 0.10,           -- 10% base luck
       LuckBoostPercent = 50,      -- +50% boost → 15% total
       ["Auto Collect Fruits"] = true,
       -- ... other settings
   }
   
   -- Attach your game's remotes
   Deobf.attachRemotes({
       Crops = { Collect = game.ReplicatedStorage.Remotes.Crops.Collect },
       -- ... other remotes
   })
   
   -- Run main loop
   local helpers = {
       InventoryChecker = Deobf.InventoryChecker.new(game.Players.LocalPlayer)
   }
   
   while true do
       Deobf.runCycle(game.Players.LocalPlayer, config, {}, helpers)
       task.wait(1)
   end
   ```

## ✨ Features

- **🍀 Luck Boost System**: Configurable luck calculation with optional caps
- **👁️ ESP Integration**: Pet ESP labels display effective luck percentage
- **🌱 Auto Collection**: Automated crop collection with whitelist filtering
- **💧 Auto Watering**: Smart plant watering system
- **⭐ Tool Management**: Auto-favorite backpack items
- **📊 Pet Tracking**: Display pet time, passives, and mutations

## 🧮 Luck Calculation

**Formula:** `EffectiveLuck = Base × (1 + Boost/100)`

**Examples:**
- Base 10% + 50% boost = `0.10 × 1.5 = 15%`
- Base 25% + 200% boost = `0.25 × 3.0 = 75%`

**Optional Caps:**
```lua
config = {
    LuckBase = 0.10,
    LuckBoostPercent = 500,  -- Would give 60%
    LuckCapMax = 0.50,        -- Caps at 50%
    LuckCapMin = 0.05,        -- Minimum 5%
}
```

## 📱 Executor Compatibility

✅ **Tested with:**
- Arceus X
- Fluxus Mobile
- Delta X / Delta Executor
- Codex
- Most Synapse-compatible executors

## 📖 Documentation

- [Mobile Guide](docs/MOBILE_GUIDE.md) - Complete mobile executor instructions
- [Verification](tests/mobile_test.lua) - Test script to verify luck calculations

## 🔧 Configuration Options

```lua
config = {
    -- Luck System
    LuckBase = 0.10,                    -- Base luck value (decimal)
    LuckBoostPercent = 50,               -- Boost percentage (whole number)
    LuckCapMin = nil,                    -- Optional minimum cap
    LuckCapMax = nil,                    -- Optional maximum cap
    
    -- Auto Collection
    ["Auto Collect Fruits"] = true,
    ["Delay To Collect"] = 0.05,
    ["Select Whitlist Fruit"] = {"All"},
    ["Stop Collect If Backpack Is Full Max"] = true,
    
    -- Auto Watering
    ["AutoWater Fruitlist"] = true,
    ["Select Water Fruit"] = {"Tomato", "Wheat"},
    ["DelayToWait"] = 0.1,
    
    -- Tools
    ["Auto Favorite Backpack"] = true,
    
    -- Cooking (optional)
    Cooking = {
        ["Auto Cook Enabled"] = false,
        ["CookingPotUUID"] = "...",
        ["IngredientList"] = {},
    }
}
```

## 🔍 ESP Display

When `runCycle` executes, pet ESP labels show:
```
Pet: Bee
Time: 12:34:56
Passive: Speed Boost
Mutation: Golden
Luck: 15.00% ← Your effective luck
```

## ⚠️ Disclaimer

This is a deobfuscated educational module for learning Lua scripting patterns. Use responsibly and only in private servers or with permission. The authors are not responsible for any consequences of use.

## 📄 License

Educational use only. Original code belongs to the game developers.

---

**Need help?** Check [docs/MOBILE_GUIDE.md](docs/MOBILE_GUIDE.md) for detailed setup instructions.
