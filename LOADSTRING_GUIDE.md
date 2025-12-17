# Grow a Garden — Loadstring Guide

Quick instructions to load the script and useful runtime commands.

Current version: v0.9 (Clean Implementation)

## Quick load (Recommended)
Use this one-liner to fetch and run the latest clean implementation:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/loader.lua"))()
```

## Alternative: Direct Load
Load clean_implementation.lua directly:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/clean_implementation.lua"))()
```

## Safer load (compile-check)
This checks for compile errors before executing:

```lua
local src = game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/clean_implementation.lua")
local fn, err = loadstring(src)
if not fn then
    warn("Compile error loading Grow a Garden:", err)
else
    pcall(fn)
end
```

## What it does
- 🎨 Creates modern draggable GUI at bottom-right
- 🥚 Starts Egg ESP system with timers and pet info
- 📊 Shows real-time status updates
- 🔧 Provides toggles for all features
- ✨ Loads all modules automatically

## Features
- **Egg ESP**: Shows egg names, hatching timers (MM:SS), and pet info when ready
- **Pet Info Display**: Shows pet name + weight (e.g., "Ostrich 0.98 KG") for ready eggs
- **Data Access**: Uses DataService module to read SavedObjects (same as obfuscated script)
- **Calculator**: Weight calculations, mutation/variant multipliers
- **Collection System**: Plant/fruit collection with filters
- **Tool Functions**: Equip/check tools with type support

## Requirements
- Roblox executor with HttpGet and loadstring support
- Internet connection
- Game: Grow a Garden

## Debug loader
To run the debug scanner:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/debug_checker.lua"))()
```

## Useful in-game commands
- Toggle ESP on/off: `GUI.config["ESP Enabled"] = true` or `false`
- Check eggs programmatically:
  ```lua
  local report = GUI.eggSystem.checkAllEggs()
  print(#report)
  for i,v in pairs(report) do print(i, v.name, tostring(v.timerValue), v.content or "N/A", v.parentInfo or "") end
  ```
- Dump structure for the first found egg:
  ```lua
  GUI.eggSystem.dumpEggStructure()
  ```
- Start/stop the watcher from code:
  ```lua
  GUI.state.running = true  -- start
  GUI.state.running = false -- stop
  ```

## Notes & tips
- If your executor blocks `game:HttpGet`, download the file manually from the repository and run it locally.
- If timers/content still report `nil`, run `GUI.eggSystem.dumpEggStructure()` and paste the console output; the script can be tuned to locate alternate timer/content names/locations.

Repository: https://github.com/sora598/grow-a-garden-test

File: `main.lua` loaded from the `main` branch raw URL shown above.
