--[[
    Grow a Garden - Clean Implementation
    Based on deobfuscated patterns from original script
    This is a 1:1 recreation of the obfuscated code's core functionality
]]

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ========== REMOTE EVENTS ==========
local Remotes = ReplicatedStorage:WaitForChild("Events")

-- ========== CORE MODULE (_) ==========
local _ = {}

-- ========== API & DATA ==========
_.API = {
    Variant = {
        {'Normal', 1000, 1},
        {'Silver', 20, 5},
        {'Gold', 10, 20},
        {'Rainbow', 1, 50}
    },
    Data = nil -- Will be loaded from Data.json
}

-- Load Data.json
function _.LoadData()
    local success, data = pcall(function()
        -- Try to load from ReplicatedStorage
        local dataModule = ReplicatedStorage:FindFirstChild("Data")
        if dataModule then
            return require(dataModule)
        end
        -- Alternative: Load from HTTP if available
        return nil
    end)
    
    if success and data then
        _.API.Data = data
        return true
    end
    return false
end

-- ========== UTILITY FUNCTIONS ==========

-- Get distance from character to position
function _.GetMagnitude(position)
    if typeof(position) == "CFrame" then
        return player:DistanceFromCharacter(position.Position)
    elseif typeof(position) == "Vector3" then
        return player:DistanceFromCharacter(position)
    end
    return math.huge
end

-- Teleport character to position
function _.GetTo(cframe)
    local char = player.Character
    local hrp = char and char.PrimaryPart
    if hrp then
        hrp.CFrame = cframe
    end
end

-- Get owner's farm
function _.GetOwnerFarm(ownerName)
    local farmsFolder = Workspace:FindFirstChild("Farm")
    if not farmsFolder then return nil end
    
    for _, farm in ipairs(farmsFolder:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        if important then
            local data = important:FindFirstChild("Data")
            if data then
                local owner = data:FindFirstChild("Owner")
                if owner and owner.Value == ownerName then
                    return farm
                end
            end
        end
    end
    return nil
end

-- Get path within player's farm
function _.GetFarmPath(pathName)
    local farm = _.GetOwnerFarm(player.Name)
    if not farm then return nil end
    
    local important = farm:FindFirstChild("Important")
    if not important then return nil end
    
    return important:FindFirstChild(pathName)
end

-- Format number with commas
function _.FormatNumber(number)
    local formatted = tostring(number)
    formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return formatted:gsub("^,", "")
end

-- Format number with suffixes (K, M, B, etc.)
function _.FormatNumber1(number)
    local suffixes = {'K', 'M', 'B', 'T', 'QA', 'QI', 'SX', 'SP', 'OC', 'NO', 'DE', 'UN', 'DU', 'TR', 'QUA', 'QUI', 'SXD', 'SEP', 'OCT', 'NOV', 'VIG', 'CENT'}
    
    if number < 1000 then
        return tostring(number)
    end
    
    local magnitude = math.floor(math.log10(number))
    local index = math.floor(magnitude / 3)
    
    if index > #suffixes then
        index = #suffixes
    end
    
    local divisor = 10 ^ (index * 3)
    local formatted = number / divisor
    
    return string.format("%.2f%s", formatted, suffixes[index])
end

-- Count dictionary entries
function _.CountDictionary(dict)
    local count = 0
    for _ in pairs(dict) do
        count = count + 1
    end
    return count
end

-- Fruit filter based on whitelist/mutations/variants
function _.FruitFilter(filters, fruit)
    local fruitWhitelist = filters[1] or {}
    local mutationWhitelist = filters[2] or {}
    local variantWhitelist = filters[3] or {}
    
    -- Get fruit name
    local fruitName = fruit:FindFirstChild("Item_String") and fruit.Item_String.Value 
                   or fruit:GetAttribute("f")
                   or fruit.Name:gsub("%b[]", ""):gsub("^%s*(.-)%s*$", "%1")
    
    -- Get variant
    local variant = fruit:FindFirstChild("Variant") and fruit.Variant.Value
    
    -- Check fruit whitelist
    local hasFruitFilter = #fruitWhitelist > 1 and not table.find(fruitWhitelist, 'None')
    if hasFruitFilter and not table.find(fruitWhitelist, fruitName) then
        return false
    end
    
    -- Check mutations
    local hasMutationFilter = #mutationWhitelist > 1 and not table.find(mutationWhitelist, 'None')
    if hasMutationFilter then
        local hasMutation = false
        for _, mutation in ipairs(mutationWhitelist) do
            if fruit:GetAttribute(mutation) then
                hasMutation = true
                break
            end
        end
        if not hasMutation then
            return false
        end
    end
    
    -- Check variant
    local hasVariantFilter = #variantWhitelist > 1 and not table.find(variantWhitelist, 'None')
    if hasVariantFilter and variant ~= nil and not table.find(variantWhitelist, variant) then
        return false
    end
    
    return hasFruitFilter or hasMutationFilter or hasVariantFilter
end

-- Pet filter based on attributes
function _.PetFilter(filters, pet)
    local attributes = filters[1] or {}
    local hasFilter = #attributes > 1 and not table.find(attributes, 'None')
    
    if hasFilter then
        local hasAttribute = false
        for _, attr in ipairs(attributes) do
            if pet:GetAttribute(attr) then
                hasAttribute = true
                break
            end
        end
        if not hasAttribute then
            return false
        end
    end
    
    return hasFilter
end

-- ========== CALCULATOR ==========
_.Calculator = {}

-- Strip flavor text from item names
function _.Calculator.StipFlavourText(name)
    if name and name ~= '' then
        return name:gsub("%b[]", ""):gsub("^%s*(.-)%s*$", "%1")
    end
    return nil
end

-- Get fruit data from API
function _.Calculator.GetFruitData(fruitName)
    local stripped = _.Calculator.StipFlavourText(fruitName)
    if _.API.Data and _.API.Data.Fruits then
        return _.API.Data.Fruits[stripped]
    end
    return nil
end

-- Get mutations list
function _.Calculator.GetMutations()
    if _.API.Data and _.API.Data.Mutations then
        return _.API.Data.Mutations
    end
    return {}
end

-- Calculate mutation multiplier
function _.Calculator.CalculatorMutation(fruit)
    local multiplier = 1
    for _, mutation in pairs(_.Calculator.GetMutations()) do
        if fruit:GetAttribute(mutation.Name) then
            multiplier = multiplier + (mutation.ValueMulti - 1)
        end
    end
    return math.max(1, multiplier)
end

-- Calculate variant multiplier
function _.Calculator.CalculatorVariant(variant)
    for _, v in ipairs(_.API.Variant) do
        if v[1] == variant then
            return v[3]
        end
    end
    return 0
end

-- Calculate fruit value
function _.Calculator.CalculatorFruit(fruit)
    local itemString = fruit:FindFirstChild("Item_String")
    local variant = fruit:FindFirstChild("Variant")
    local weight = fruit:FindFirstChild("Weight")
    
    if not variant or not weight then return 0 end
    
    local fruitName = itemString and itemString.Value or _.Calculator.StipFlavourText(fruit.Name)
    local fruitData = _.Calculator.GetFruitData(fruitName)
    
    if not fruitData then return 0 end
    
    local baseValue = fruitData[2]
    local baseWeight = fruitData[1]
    
    if not baseValue or not baseWeight then return 0 end
    
    local variantMultiplier = _.Calculator.CalculatorVariant(variant.Value)
    local mutationMultiplier = _.Calculator.CalculatorMutation(fruit)
    
    local value = baseValue * mutationMultiplier * variantMultiplier
    local weightRatio = weight.Value / baseWeight
    weightRatio = (weightRatio < 0.95) and 0.95 or weightRatio
    
    local finalValue = value * weightRatio * weightRatio
    return math.floor(finalValue + 0.5)
end

-- Calculate weight at level
function _.Calculator.CalculateWeight(baseWeight, level)
    return baseWeight + (baseWeight * 0.1 * level)
end

-- Get current weight
function _.Calculator.CurrentWeight(baseWeight, level)
    local cappedLevel = math.min(level, 100)
    return _.Calculator.CalculateWeight(baseWeight, cappedLevel)
end

-- ========== DATA CLIENT ==========
_.DataClient = {}

-- Storage for cached data
local _cachedData = nil

-- Get player data from DataService
function _.DataClient.GetData()
    if _cachedData then return _cachedData end
    
    local success, dataModule = pcall(function()
        return require(ReplicatedStorage.Modules.DataService)
    end)
    
    if success and dataModule then
        local data = dataModule:GetData()
        _cachedData = data
        return data
    end
    
    return nil
end

-- Get pet data by UUID
function _.DataClient.GetPet_Data(petUUID)
    local data = _.DataClient.GetData()
    if not data then return nil end
    
    local petsData = data.PetsData
    if not petsData then return nil end
    
    local inventory = petsData.PetInventory
    if not inventory or not inventory.Data then return nil end
    
    return inventory.Data[petUUID]
end

-- Get pet boost data
function _.DataClient.GetPet_BoostData(petUUID)
    local petData = _.DataClient.GetPet_Data(petUUID)
    if petData and petData.PetData and petData.PetData.Boosts and #petData.PetData.Boosts > 0 then
        return petData.PetData.Boosts
    end
    return {}
end

-- Get pet level
function _.DataClient.GetLevel(petUUID)
    local petData = _.DataClient.GetPet_Data(petUUID)
    if not petData then return nil end
    return petData.PetData and petData.PetData.Level
end

-- Get saved objects (eggs, crates, etc.)
function _.DataClient.GetSaved_Data()
    local data = _.DataClient.GetData()
    if not data then return nil end
    
    local saveSlots = data.SaveSlots
    if not saveSlots then return nil end
    
    local selectedSlot = saveSlots.SelectedSlot
    local allSlots = saveSlots.AllSlots
    
    if not selectedSlot or not allSlots then return nil end
    
    local slotData = allSlots[selectedSlot]
    if not slotData then return nil end
    
    return slotData.SavedObjects
end

-- ========== ESP SYSTEM ==========
_.ESP = {}

-- Create ESP for an object
function _.ESP.CreateESP(object, options)
    if not object or not options then return end
    if object:FindFirstChild("ESP") then return end
    
    -- Get base part for adornee
    local adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart"))
                 or object
    
    if not adornee then return end
    
    -- Create ESP folder
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP"
    espFolder.Parent = object
    
    -- Create box handle
    local boxHandle = Instance.new("BoxHandleAdornment")
    boxHandle.Name = "ESP"
    boxHandle.Size = Vector3.new(1, 0, 1)
    boxHandle.Transparency = 1
    boxHandle.AlwaysOnTop = false
    boxHandle.ZIndex = 0
    boxHandle.Adornee = adornee
    boxHandle.Parent = espFolder
    
    -- Create billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 100, 0, 150)
    billboard.StudsOffset = Vector3.new(0, 1, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = boxHandle
    billboard.Enabled = options.Enabled ~= false
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 0, 0, -50)
    textLabel.Size = UDim2.new(0, 100, 0, 100)
    textLabel.TextSize = 10
    textLabel.TextColor3 = options.Color or Color3.fromRGB(255, 255, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    textLabel.RichText = true
    textLabel.Text = options.Text or ""
    textLabel.ZIndex = 15
    textLabel.Parent = billboard
end

-- Remove ESP from object
function _.ESP.Removes(object)
    if not object then return end
    task.spawn(function()
        local esp = object:FindFirstChild("ESP")
        if esp then
            esp:Destroy()
        end
    end)
end

-- ========== COLLECTION SYSTEM ==========
_.Collection = {}

-- Get plant list with proximity prompts
function _.Collection.GetPlantList(plantsFolder, resultTable, includeDisabled)
    includeDisabled = includeDisabled or false
    
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        local function addPlant(plantObj, prompt)
            if includeDisabled or (prompt and prompt.Enabled) then
                table.insert(resultTable, plantObj)
            end
        end
        
        -- Check for fruits folder
        local fruits = plant:FindFirstChild("Fruits")
        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    addPlant(fruit, prompt)
                end
            end
        end
        
        -- Check plant itself
        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            addPlant(plant, prompt)
        end
    end
    
    return resultTable
end

-- Get plant list (items only, no prompts)
function _.Collection.GetPlantList1(plantsFolder, resultTable, includeFruits, includeFavorited)
    includeFavorited = includeFavorited or false
    
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        local function addItem(item)
            if item and (includeFavorited or not item:GetAttribute("Favorited")) then
                table.insert(resultTable, item)
            end
        end
        
        if includeFruits then
            local fruits = plant:FindFirstChild("Fruits")
            if fruits then
                for _, fruit in ipairs(fruits:GetChildren()) do
                    addItem(fruit)
                end
            end
        else
            addItem(plant)
        end
    end
    
    return resultTable
end

-- Get count of specific plants
function _.Collection.GetCountPlant(plantNames)
    local plantsFolder = _.GetFarmPath("Plants_Physical")
    if not plantsFolder then return 0 end
    
    local count = 0
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if plant:IsA("Model") and table.find(plantNames, plant.Name) then
            local fruits = plant:FindFirstChild("Fruits")
            if fruits then
                for _, fruit in ipairs(fruits:GetChildren()) do
                    if fruit then
                        count = count + 1
                    end
                end
            end
            if plant then
                count = count + 1
            end
        end
    end
    
    return count
end

-- ========== TOOL FUNCTIONS ==========
_.ToolFunction = {}

-- Type enum for tools
_.ToolFunction.GetTypeEnum = {
    a = 'Seed Pack',
    L = 'Leaf Blower',
    e = "Night Staff",
    f = 'Harvest Tool',
    g = "Pollen Radar",
    h = 'Favorite Tool',
    i = "Lightning Rod",
    u = "Food",
    k = 'Star Caller',
    s = 'SprayBottle',
    y = 'Pet Pouch',
    n = 'Seed',
    m = "FriendshipPot",
    F = 'Fairy Caller',
    b = 'Trowel',
    c = "PetEgg",
    d = "Sprinkler",
    t = "Tranquil Radar",
    j = 'Holdable',
    l = "Pet"
}

-- Equip tool by name
function _.ToolFunction.Equip(toolName, toolType, includeEquipped)
    includeEquipped = includeEquipped or nil
    
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (includeEquipped or not tool:GetAttribute("d")) then
            local typeEnum = _.ToolFunction.GetTypeEnum[tool:GetAttribute("b")]
            
            if not toolType or typeEnum == toolType then
                local itemName = typeEnum == "PetEgg" and tool:GetAttribute('h')
                              or tool:GetAttribute("f")
                              or tool.Name:gsub('%b[]', ""):gsub('^%s*(.-)%s*$', '%1')
                
                if not toolName or ((type(toolName) == "table" and table.find(toolName, itemName)) or itemName == toolName) then
                    humanoid:EquipTool(tool)
                    return tool
                end
            end
        end
    end
end

-- Check if tool is equipped
function _.ToolFunction.IsEquipped(toolName, toolType)
    local char = player.Character
    if not char then return nil end
    
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and not tool:GetAttribute("d") then
            local typeEnum = _.ToolFunction.GetTypeEnum[tool:GetAttribute("b")]
            
            if not toolType or typeEnum == toolType then
                local itemName = typeEnum == "PetEgg" and tool:GetAttribute('h')
                              or tool:GetAttribute("f")
                              or tool.Name:gsub('%b[]', ''):gsub('^%s*(.-)%s*$', '%1')
                
                if not toolName or ((type(toolName) == "table" and table.find(toolName, itemName)) or itemName == toolName) then
                    return tool
                end
            end
        end
    end
    
    return nil
end

-- Get all tools
function _.ToolFunction.GetAllTool()
    local tools = {}
    
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA('Tool') then
            table.insert(tools, tool)
        end
    end
    
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(tools, tool)
        end
    end
    
    return tools
end

-- ========== INITIALIZATION ==========
function _.Initialize()
    print("🌱 Initializing Grow a Garden Clean Implementation...")
    
    -- Load Data.json
    local dataLoaded = _.LoadData()
    if dataLoaded then
        print("✅ Data.json loaded successfully")
    else
        warn("⚠️ Failed to load Data.json")
    end
    
    -- Initialize data client
    local playerData = _.DataClient.GetData()
    if playerData then
        print("✅ Player data loaded successfully")
    else
        warn("⚠️ Failed to load player data")
    end
    
    print("✅ Initialization complete!")
end

-- Auto-initialize
_.Initialize()

-- Return module
return _
