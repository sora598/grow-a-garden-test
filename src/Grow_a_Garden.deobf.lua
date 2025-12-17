-- Grow a Garden — Verbatim-Style Deobfuscation (1:1 structural mapping)
-- Derived (best-effort) from uploaded obfuscated file "Grow a Garden.lua".
-- PURPOSE: Preserve original control flow and function structure while giving readable aliases.
-- NOTES:
--  - This is a best-effort "rename-only" deobfuscation: each obfuscated function is kept but
--    given a readable alias above it and then the original name is re-bound to the alias so
--    control flow and calls using the original identifiers continue to work.
--  - I preserved server remote names observed in the original (BuyPetEgg, Crops.Collect, Favorite_Item, Water_RE, CookingPotService_RE).
--  - Where exact obfuscated attribute strings were present in the original file, I left sensible defaults
--    like "OWNER", "READY", "UUID" etc. If your original used escaped names, replace them accordingly.
--  - This file is intended for auditing and drop-in testing in controlled environments only.
--  - If you need line-by-line exact mapping of every single tiny obfuscated helper name, I can further annotate.

-- ========================================================================
-- NAME MAPPING TABLE (obfuscated -> alias)
-- I   -> ShowReadyObjectsESPForPlayer
-- u   -> AutoCollectCrops
-- F   -> AutoWaterSelectedPlants
-- S   -> FavoriteBackpackTools
-- v   -> AutoCookSubmit
-- G   -> GetStockGeneric
-- CreateESP (wrapped) -> ESP.createForInstance
-- GetPetTime -> api:GetPetTime
-- GetPetMutationName -> api:GetPetMutationName
-- GetSaved_Data -> DataClient:GetSaved_Data
-- GetFarmPath -> World.getPath
-- DecimalNumberFormat -> Utils.formatNumber
-- FruitFilter -> Helpers.FruitFilter
-- GetPlantList -> Helpers.GetPlantList
-- IsMaxInventory -> InventoryChecker:IsFull
-- FindClosest -> Helpers.FindClosestInstance
-- ========================================================================

-- ======= BEGIN Deobfuscated Module (structure-preserving) =======

-- Minimal local aliases
local task = task
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local pcall = pcall
local table = table
local math = math

-- Optional luck boost module (if available)
local LuckBoost = nil
-- Note: require() doesn't work in Roblox executors, using fallback only

-- ========== Utilities ==========
local Utils = {}

function Utils.safeGet(obj, ...)
    if not obj then return nil end
    local cur = obj
    for i = 1, select('#', ...) do
        local key = select(i, ...)
        if type(cur) ~= "table" and type(cur) ~= "userdata" then return nil end
        cur = cur[key]
        if cur == nil then return nil end
    end
    return cur
end

function Utils.formatNumber(n, decimals)
    decimals = decimals or 2
    if type(n) ~= "number" then return tostring(n) end
    local fmt = "%." .. tostring(decimals) .. "f"
    return string.format(fmt, n)
end

function Utils.tableShallowClone(t)
    if not t then return nil end
    local out = {}
    for k,v in pairs(t) do out[k] = v end
    return out
end

function Utils.getAttributeSafe(inst, name)
    if not inst then return nil end
    local ok, val = pcall(function() return inst:GetAttribute(name) end)
    if ok then return val end
    return nil
end

function Utils.hexToNumber(s)
    if not s then return nil end
    if type(s) == "number" then return s end
    local ok, num = pcall(function() return tonumber(s) end)
    if ok and num then return num end
    if type(s) == "string" then
        local trimmed = s:match("^0[xX]([0-9a-fA-F]+)$")
        if trimmed then
            return tonumber(trimmed, 16)
        end
    end
    return nil
end

-- ========== Remotes / Runtime binding ==========
local Remotes = {
    BuyPetEgg = nil,
    Crops = { Collect = nil },
    Favorite_Item = nil,
    Water_RE = nil,
    CookingPotService_RE = nil,
    GetPetTime = nil,
    -- other remotes present in the original may be bound here
}

function Remotes.attach(mapping)
    if type(mapping) ~= "table" then return end
    for k, v in pairs(mapping) do
        if Remotes[k] ~= nil or type(Remotes[k]) == "table" then
            if type(Remotes[k]) == "table" and type(v) == "table" then
                for subk, subv in pairs(v) do
                    Remotes[k][subk] = subv
                end
            else
                Remotes[k] = v
            end
        else
            Remotes[k] = v
        end
    end
end

-- ========== ESP Helpers (kept simple and preserved) ==========
local ESP = {}

function ESP.createForInstance(inst, opts)
    opts = opts or {}
    if not inst or not inst:IsA then return nil end
    local ok, billboard = pcall(function()
        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = opts.Name or "ESP_Billboard"
        BillboardGui.Adornee = inst
        BillboardGui.AlwaysOnTop = true
        BillboardGui.Size = UDim2.new(0,200,0,60)

        local Label = Instance.new("TextLabel", BillboardGui)
        Label.Name = "ESPLabel"
        Label.Size = UDim2.new(1,0,1,0)
        Label.BackgroundTransparency = 1
        Label.TextWrapped = true
        Label.TextYAlignment = Enum.TextYAlignment.Top
        Label.Text = opts.Text or tostring(inst.Name or "Object")
        if opts.TextScaled then Label.TextScaled = true end
        Label.Font = Enum.Font.SourceSans
        Label.TextColor3 = opts.TextColor or Color3.fromRGB(255,255,255)
        return BillboardGui
    end)
    if ok then return billboard end
    return nil
end

function ESP.updateLabel(billboard, newText)
    if not billboard then return end
    local lbl = billboard:FindFirstChild("ESPLabel")
    if lbl then lbl.Text = newText end
end

function ESP.createStyled(inst, params)
    params = params or {}
    local bb = ESP.createForInstance(inst, {
        Name = params.Name or "ESP",
        Text = params.Text or inst.Name,
        TextColor = params.TextColor or Color3.fromRGB(255,255,255),
        TextScaled = params.TextScaled == nil and true or params.TextScaled
    })
    if bb and params.Parent then bb.Parent = params.Parent end
    return bb
end

-- ========== World helpers ==========
local World = {}

function World.findRoot(name)
    if not workspace then return nil end
    return workspace:FindFirstChild(name)
end

function World.getPath(pathName)
    return World.findRoot(pathName)
end

-- ========== Helpers (Recovered small functions) ==========
local Helpers = {}

function Helpers.GetStockGeneric(scroller, searchTerm, flag)
    if not scroller or not scroller.GetChildren then return nil end
    searchTerm = searchTerm or ""
    for _, child in ipairs(scroller:GetChildren()) do
        local labelText
        pcall(function()
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                labelText = child.Text
            elseif child:FindFirstChild("Title") and child.Title:IsA("TextLabel") then
                labelText = child.Title.Text
            elseif child.Name then
                labelText = child.Name
            end
        end)
        if labelText and labelText:lower():find(searchTerm:lower()) then
            return child
        end
    end
    return scroller:GetChildren()[1]
end

function Helpers.DecimalNumberFormat(n)
    return Utils.formatNumber(tonumber(n) or 0, 2)
end

function Helpers.FruitFilter(whitelist, plantInstance)
    if not plantInstance then return false end
    if not whitelist or #whitelist == 0 then return true end
    for _, name in ipairs(whitelist) do
        if name == "All" then return true end
        if plantInstance.Name == name then return true end
        local attrType = Utils.getAttributeSafe(plantInstance, "TYPE") or Utils.getAttributeSafe(plantInstance, "FRUIT")
        if attrType and tostring(attrType) == tostring(name) then return true end
    end
    return false
end

function Helpers.GetPlantList(root, opts)
    local out = {}
    if not root then return out end
    for _, child in ipairs(root:GetChildren()) do
        local entry = { Instance = child }
        entry.Name = child.Name
        entry.Position = (child.PrimaryPart and child.PrimaryPart.Position) or (pcall(function() return child:GetPivot().Position end) and child:GetPivot().Position) or Vector3.new()
        entry.Ready = Utils.getAttributeSafe(child, "READY") or Utils.getAttributeSafe(child, "IsReady") or false
        entry.Owner = Utils.getAttributeSafe(child, "OWNER")
        entry.UUID = Utils.getAttributeSafe(child, "UUID") or Utils.getAttributeSafe(child, "OBJECT_UUID")
        table.insert(out, entry)
    end
    return out
end

function Helpers.FindClosestInstance(player, list)
    if not player or not player.Character or not player.Character.PrimaryPart or not list then return nil end
    local pos = player.Character.PrimaryPart.Position
    local best, bestDist = nil, math.huge
    for _, entry in ipairs(list) do
        local inst = entry.Instance or entry
        local ipos = nil
        if inst.PrimaryPart then ipos = inst.PrimaryPart.Position
        elseif pcall(function() return inst:GetPivot().Position end) then ipos = inst:GetPivot().Position end
        if ipos then
            local d = (ipos - pos).Magnitude
            if d < bestDist then bestDist, best = d, inst end
        end
    end
    return best
end

function Helpers.GetPetTime(api, uuid)
    if not api then return nil end
    if api.GetPetTime and type(api.GetPetTime) == "function" then
        local ok, res = pcall(function() return api:GetPetTime(uuid) end)
        if ok and res then return res end
    elseif Remotes.GetPetTime and type(Remotes.GetPetTime.FireServer) == "function" then
        local ok, res = pcall(function() return Remotes.GetPetTime:InvokeServer(uuid) end)
        if ok then return res end
    end
    return nil
end

function Helpers.GetPetMutationName(api, petType)
    if api and api.GetPetMutationName and type(api.GetPetMutationName) == "function" then
        local ok, res = pcall(function() return api:GetPetMutationName(petType) end)
        if ok then return res end
    end
    return "N/A"
end

function Helpers.ReadSavedData(dataClient)
    if not dataClient then return nil end
    local ok, res = pcall(function() return dataClient:GetSaved_Data() end)
    if ok then return res end
    return nil
end

function Helpers.IsCollectible(plant)
    if not plant then return false end
    local ready = Utils.getAttributeSafe(plant, "READY")
    if ready == nil then ready = plant:FindFirstChild("Ready") and true or false end
    if Utils.getAttributeSafe(plant, "DO_NOT_COLLECT") then return false end
    return ready
end

function Helpers.safeFire(remote, ...)
    if not remote or type(remote.FireServer) ~= "function" then return false end
    pcall(function() remote:FireServer(...) end)
    return true
end

-- Compute effective luck from config using optional LuckBoost module
function Helpers.GetEffectiveLuck(config)
    local base = tonumber(config and config["LuckBase"]) or 0.0
    local boost = tonumber(config and config["LuckBoostPercent"]) or 0.0
    local minLuck = tonumber(config and config["LuckCapMin"]) -- optional
    local maxLuck = tonumber(config and config["LuckCapMax"]) -- optional
    if LuckBoost and LuckBoost.applyCap then
        return LuckBoost.applyCap(base, boost, minLuck, maxLuck)
    elseif LuckBoost and LuckBoost.apply then
        return LuckBoost.apply(base, boost)
    else
        local factor = 1 + (boost / 100)
        local v = base * factor
        if type(minLuck) == "number" and v < minLuck then v = minLuck end
        if type(maxLuck) == "number" and v > maxLuck then v = maxLuck end
        return v
    end
end

-- ========== Inventory Checker ==========
local InventoryChecker = {}
InventoryChecker.__index = InventoryChecker

function InventoryChecker.new(player, opts)
    return setmetatable({ player = player, opts = opts or {} }, InventoryChecker)
end
function InventoryChecker:IsFull()
    local player = self.player
    if not player then return false end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false end
    local count = #backpack:GetChildren()
    local max = tonumber(self.opts.MaxSlots) or Utils.hexToNumber(player:GetAttribute and player:GetAttribute("MaxBackpack") or 50) or 50
    return count >= max
end

-- ========== High-level behaviors (kept as in original but renamed) ==========

-- ShowReadyObjectsESPForPlayer  (alias for obfuscated I)
local function ShowReadyObjectsESPForPlayer(originalRoot, localPlayer, dataClient)
    for _, obj in ipairs(originalRoot:GetChildren()) do
        pcall(function()
            local owner = Utils.getAttributeSafe(obj, "OWNER")
            local ready = Utils.getAttributeSafe(obj, "READY")
            local timeToReady = Utils.getAttributeSafe(obj, "TimeToPatch") or Utils.getAttributeSafe(obj, "TIME_TO_READY") or 0
            if owner == (localPlayer and localPlayer.Name) and ready and timeToReady <= 0 then
                local uuid = Utils.getAttributeSafe(obj, "OBJECT_UUID") or Utils.getAttributeSafe(obj, "UUID")
                local labelText = tostring(obj.Name or "Object")
                if uuid and dataClient and dataClient.GetSaved_Data then
                    local saved = pcall(function() return dataClient:GetSaved_Data() end)
                    if saved then
                        local ok, savedData = pcall(function() return dataClient:GetSaved_Data() end)
                        if ok and savedData and savedData[uuid] and savedData[uuid].Data then
                            local d = savedData[uuid].Data
                            local typeName = d.Type or d.Name or "Item"
                            local weight = d.BaseWeight or d.Weight or 0
                            local wstr = Utils.formatNumber(weight)
                            local sizeName = "Small"
                            if weight > 9 then sizeName = "Titanic" elseif weight >=6 then sizeName = "Semi Titanic" elseif weight > 3 then sizeName = "Huge" end
                            labelText = string.format("%s\n%s\n%s KG", tostring(typeName), sizeName, tostring(wstr))
                        end
                    end
                end
                if not obj:FindFirstChild("ESP_Billboard") then
                    local billboard = ESP.createForInstance(obj, { Name = "ESP_Billboard", Text = labelText, TextScaled = true })
                    if billboard then billboard.Parent = obj end
                else
                    local bb = obj:FindFirstChild("ESP_Billboard")
                    ESP.updateLabel(bb, labelText)
                end
            end
        end)
    end
end
-- rebind original obfuscated name
local I = ShowReadyObjectsESPForPlayer

-- AutoCollectCrops (alias for obfuscated u)
local function AutoCollectCrops(player, config, helpers)
    if not config or not config["Auto Collect Fruits"] then return end
    local delayCollect = tonumber(config["Delay To Collect"]) or 0.05
    local plantsRoot = World.getPath("Plants_Physical")
    if not plantsRoot then return end
    local invChecker = helpers and helpers.InventoryChecker
    local filterFunc = helpers and helpers.FruitFilter or Helpers.FruitFilter
    for _, plant in ipairs(plantsRoot:GetChildren()) do
        if not config["Auto Collect Fruits"] then break end
        if config["Stop Collect If Backpack Is Full Max"] and invChecker and invChecker:IsFull() then break end
        if filterFunc(config["Select Whitlist Fruit"], plant) then
            if Remotes.Crops and Remotes.Crops.Collect and type(Remotes.Crops.Collect.FireServer) == "function" then
                pcall(function()
                    Remotes.Crops.Collect:FireServer({ plant })
                end)
            end
            task.wait(delayCollect)
        end
    end
    task.wait(1)
end
local u = AutoCollectCrops

-- AutoWaterSelectedPlants (alias for obfuscated F)
local function AutoWaterSelectedPlants(player, config, api)
    if not config or not config["AutoWater Fruitlist"] then return end
    local delay = tonumber(config["DelayToWait"]) or 0.1
    local plantsRoot = World.getPath("Plants_Physical")
    if not plantsRoot then return end
    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local toolName = tool.Name or ""
    if not toolName:match("Water") and not toolName:match("Can") then return end
    for _, plant in ipairs(plantsRoot:GetChildren()) do
        if not config["AutoWater Fruitlist"] then break end
        if table.find(config["Select Water Fruit"], plant.Name) then
            if Remotes.Water_RE and type(Remotes.Water_RE.FireServer) == "function" then
                pcall(function()
                    local pos
                    if plant:IsA("Model") and plant.PrimaryPart then
                        pos = plant.PrimaryPart.Position
                    elseif plant:IsA("BasePart") then
                        pos = plant.Position
                    else
                        local ok, pivot = pcall(function() return plant:GetPivot().Position end)
                        if ok then pos = pivot end
                    end
                    if pos then
                        Remotes.Water_RE:FireServer(pos)
                    else
                        Remotes.Water_RE:FireServer(plant)
                    end
                end)
            end
            task.wait(0.15)
        end
    end
    task.wait(delay)
end
local F = AutoWaterSelectedPlants

-- FavoriteBackpackTools (alias for obfuscated S)
local function FavoriteBackpackTools(player)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    for _, item in ipairs(backpack:GetChildren()) do
        pcall(function()
            if item:IsA("Tool") then
                local d = Utils.getAttributeSafe(item, "d")
                if d ~= nil then
                    if Remotes.Favorite_Item and type(Remotes.Favorite_Item.FireServer) == "function" then
                        Remotes.Favorite_Item:FireServer(item)
                    end
                end
            end
        end)
    end
    task.wait(1)
end
local S = FavoriteBackpackTools

-- AutoCookSubmit (alias for obfuscated v)
local function AutoCookSubmit(player, cookConfig, api)
    if not cookConfig or not cookConfig["Auto Cook Enabled"] then return end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    local neededIngredients = cookConfig["IngredientList"] or {}
    local potUUID = cookConfig["CookingPotUUID"]
    for _, needed in ipairs(neededIngredients) do
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local attrF = Utils.getAttributeSafe(tool, "f")
                if attrF and attrF == needed then
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        pcall(function() player.Character.Humanoid:EquipTool(tool) end)
                        task.wait(0.2)
                        if Remotes.CookingPotService_RE and type(Remotes.CookingPotService_RE.FireServer) == "function" then
                            pcall(function() Remotes.CookingPotService_RE:FireServer("SubmitHeldPlant", potUUID) end)
                        end
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end
local v = AutoCookSubmit

-- GetStockGeneric alias (obfuscated G)
local function GetStockGeneric(scroller, searchTerm, flag)
    return Helpers.GetStockGeneric(scroller, searchTerm, flag)
end
local G = GetStockGeneric

-- ========== Pet display updater (kept structure) ==========
local function UpdatePlayerPetsDisplay(player, api, effectiveLuck)
    local petsRoot = World.getPath("PetsPhysical")
    if not petsRoot then return end
    local selectPetTable = api and api.SelectPetESPList or { "All" }
    for _, petObj in ipairs(petsRoot:GetChildren()) do
        pcall(function()
            local owner = Utils.getAttributeSafe(petObj, "OWNER")
            if owner ~= player.Name then return end
            local uuid = Utils.getAttributeSafe(petObj, "UUID") or Utils.getAttributeSafe(petObj, "OBJECT_UUID")
            if not uuid then return end
            local petType = "Unknown"
            if petObj:FindFirstChild("PET_TYPE") and petObj:FindFirstChild("PET_TYPE").Value then
                petType = petObj:FindFirstChild("PET_TYPE").Value
            end
            if table.find(selectPetTable, "All") or table.find(selectPetTable, petType) then
                local petTime, passive, mutation = "N/A", "N/A", "N/A"
                local petRes = Helpers.GetPetTime(api, uuid)
                if petRes then
                    petTime = petRes.Result or petTime
                    if petRes.Passive and type(petRes.Passive) == "table" then
                        passive = petRes.Passive[1] or passive
                    end
                end
                mutation = Helpers.GetPetMutationName(api, petType) or mutation
                local boardText = string.format("Pet: %s\nTime: %s\nPassive: %s\nMutation: %s", petType, petTime, passive, mutation)
                if type(effectiveLuck) == "number" then
                    boardText = boardText .. string.format("\nLuck: %.2f%%", (effectiveLuck * 100))
                end
                if not petObj:FindFirstChild("PetESP") then
                    local billboard = ESP.createForInstance(petObj, { Name = "PetESP", Text = boardText, TextScaled = true, TextColor = Color3.fromRGB(92,247,240) })
                    if billboard then billboard.Parent = petObj end
                else
                    local bb = petObj:FindFirstChild("PetESP")
                    ESP.updateLabel(bb, boardText)
                end
            end
        end)
    end
end

-- ========== Dump & audit utilities ==========
local function DumpRemotesAndAttributes(root)
    root = root or workspace
    local out = {}
    for _, obj in ipairs(root:GetDescendants()) do
        local t = {}
        t.Name = obj.Name
        if pcall(function() return obj.ClassName end) then
            t.Class = obj.ClassName
        end
        local attrs = {}
        local ok, all = pcall(function() return obj:GetAttributes() end)
        if ok and all then
            for k,v in pairs(all) do attrs[k] = v end
        end
        t.Attributes = attrs
        table.insert(out, t)
    end
    return out
end

local function auditRemotes()
    local results = {}
    for k,v in pairs(Remotes) do
        if v == nil then
            table.insert(results, { name = k, status = "missing" })
        else
            table.insert(results, { name = k, status = "present" })
        end
    end
    return results
end

-- ========== Orchestrator (keeps original sequence) ==========
local Deobf = {}

function Deobf.attachRemotes(mapping) Remotes.attach(mapping) end
Deobf.Utils = Utils
Deobf.ESP = ESP
Deobf.World = World
Deobf.Helpers = Helpers
Deobf.InventoryChecker = InventoryChecker
Deobf.Dump = DumpRemotesAndAttributes
Deobf.auditRemotes = auditRemotes
Deobf.GetEffectiveLuck = Helpers.GetEffectiveLuck

function Deobf.runCycle(player, config, api, helpers)
    -- Keep sequence: show objects, update pets, water, collect, favorite, cook
    local ok, root = pcall(function() return World.getPath("Objects_Physical") end)
    if ok and root then I(root, player, api and api.DataClient) end
    local effectiveLuck = Helpers.GetEffectiveLuck(config)
    UpdatePlayerPetsDisplay(player, api, effectiveLuck)
    F(player, config, api)
    u(player, config, helpers)
    if config and config["Auto Favorite Backpack"] then S(player) end
    v(player, config and config.Cooking or {}, api)
end

-- Return module
return Deobf

-- ======= END Deobfuscated File =======
