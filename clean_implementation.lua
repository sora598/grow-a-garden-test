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

-- ========== GUI SYSTEM ==========
_.GUI = {}

local GUI = {}

function _.GUI.Create()
    local TweenService = game:GetService("TweenService")
    
    -- Create ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "GrowAGardenGUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Safe parent to player GUI or fallback
    local function getGuiParent()
        if player.PlayerGui then
            return player.PlayerGui
        end
        if type(gethui) == "function" then
            local success, result = pcall(gethui)
            if success and result then return result end
        end
        return game:GetService("CoreGui")
    end
    
    sg.Parent = getGuiParent()
    
    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 350, 0, 500)
    main.Position = UDim2.new(1, -360, 0.5, -250)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    main.BorderSizePixel = 0
    main.Parent = sg
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🌱 Grow a Garden"
    title.TextColor3 = Color3.fromRGB(100, 255, 150)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 24
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)
    
    -- Content frame
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -65)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.ScrollBarImageColor3 = Color3.fromRGB(100, 255, 150)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    -- Auto-resize canvas
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Config storage
    GUI.Config = {
        ["Auto Collect Eggs"] = false,
        ["ESP Eggs"] = true,
        ["Show Pet Info"] = true,
        ["Auto Hatch"] = false,
    }
    
    -- Create section function
    local function createSection(name)
        local section = Instance.new("Frame")
        section.Name = name
        section.Size = UDim2.new(1, 0, 0, 35)
        section.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        section.BorderSizePixel = 0
        section.Parent = content
        
        Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = section
        
        return section
    end
    
    -- Create toggle function
    local function createToggle(name, default)
        local toggle = Instance.new("Frame")
        toggle.Name = name
        toggle.Size = UDim2.new(1, 0, 0, 40)
        toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        toggle.BorderSizePixel = 0
        toggle.Parent = content
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 45, 0, 25)
        button.Position = UDim2.new(1, -50, 0.5, -12.5)
        button.BackgroundColor3 = default and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(60, 60, 70)
        button.Text = default and "ON" or "OFF"
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 11
        button.Parent = toggle
        
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
        
        GUI.Config[name] = default
        
        button.MouseButton1Click:Connect(function()
            GUI.Config[name] = not GUI.Config[name]
            button.Text = GUI.Config[name] and "ON" or "OFF"
            button.BackgroundColor3 = GUI.Config[name] and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(60, 60, 70)
        end)
        
        return toggle
    end
    
    -- Create status label
    local function createStatus()
        local status = Instance.new("Frame")
        status.Name = "Status"
        status.Size = UDim2.new(1, 0, 0, 60)
        status.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        status.BorderSizePixel = 0
        status.Parent = content
        
        Instance.new("UICorner", status).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Name = "StatusLabel"
        label.Size = UDim2.new(1, -20, 1, -10)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = "Status: Ready\nEggs: 0 | Ready: 0"
        label.TextColor3 = Color3.fromRGB(150, 150, 150)
        label.Font = Enum.Font.Code
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Parent = status
        
        GUI.StatusLabel = label
        
        return status
    end
    
    -- Build GUI
    createSection("🥚 Egg Settings")
    createToggle("Auto Collect Eggs", false)
    createToggle("ESP Eggs", true)
    createToggle("Show Pet Info", true)
    createToggle("Auto Hatch", false)
    
    createSection("📊 Status")
    createStatus()
    
    -- Make draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    print("✅ GUI created successfully!")
    return GUI
end

-- Update status function
function _.GUI.UpdateStatus(text)
    if GUI.StatusLabel then
        GUI.StatusLabel.Text = text
    end
end

-- ========== EGG ESP SYSTEM ==========
_.EggESP = {}

function _.EggESP.Start()
    print("🔍 Starting Egg ESP...")
    
    task.spawn(function()
        while true do
            if GUI.Config and GUI.Config["ESP Eggs"] then
                local objectsFolder = _.GetFarmPath("Objects_Physical")
                if objectsFolder then
                    local savedData = _.DataClient.GetSaved_Data()
                    
                    for _, obj in ipairs(objectsFolder:GetChildren()) do
                        if obj:GetAttribute("OWNER") == player.Name and obj.Name == "PetEgg" then
                            local uuid = obj:GetAttribute("OBJECT_UUID")
                            local ready = obj:GetAttribute("READY")
                            local timeToHatch = obj:GetAttribute("TimeToHatch")
                            
                            -- Create or update ESP
                            if not obj:FindFirstChild("ESP") then
                                _.ESP.CreateESP(obj, {
                                    Color = Color3.fromRGB(0, 255, 255),
                                    Text = "Loading...",
                                    Enabled = true
                                })
                            end
                            
                            -- Update ESP text
                            local esp = obj:FindFirstChild("ESP")
                            if esp then
                                local billboard = esp:FindFirstChild("ESP")
                                local textLabel = billboard and billboard:FindFirstChildWhichIsA("BillboardGui")
                                textLabel = textLabel and textLabel:FindFirstChild("TextLabel")
                                
                                if textLabel then
                                    local eggName = obj:GetAttribute("EggName") or "Unknown Egg"
                                    
                                    if ready then
                                        -- Show pet info
                                        if savedData and uuid and GUI.Config["Show Pet Info"] then
                                            local eggData = savedData[uuid]
                                            if eggData and eggData.Data then
                                                local petType = eggData.Data.Type or "Unknown"
                                                local baseWeight = eggData.Data.BaseWeight or 1
                                                local weight = _.Calculator.CurrentWeight(baseWeight, 1)
                                                
                                                textLabel.Text = string.format("%s\n%.2f KG", petType, weight)
                                                textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                            else
                                                textLabel.Text = "READY: " .. eggName
                                                textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                            end
                                        else
                                            textLabel.Text = "READY: " .. eggName
                                            textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                        end
                                    elseif timeToHatch and timeToHatch > 0 then
                                        -- Show timer
                                        local mins = math.floor(timeToHatch / 60)
                                        local secs = math.floor(timeToHatch % 60)
                                        textLabel.Text = string.format("%s\n%d:%02d", eggName, mins, secs)
                                        textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
                                    else
                                        textLabel.Text = eggName
                                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait(2)
        end
    end)
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
    
    -- Create GUI
    GUI = _.GUI.Create()
    
    -- Start Egg ESP
    _.EggESP.Start()
    
    print("✅ Initialization complete!")
end

-- Auto-initialize
_.Initialize()

-- Return module
return _
