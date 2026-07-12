local Players = game.Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")


local LocalPlayer = game.Players.LocalPlayer
local Limits = LocalPlayer:WaitForChild("Limits")
local Bricks = LocalPlayer:WaitForChild("Bricks")
local Stones = LocalPlayer:WaitForChild("Stones")


local PlaceRemote = ReplicatedStorage:WaitForChild("Place")
local KickStone = ReplicatedStorage:WaitForChild("KickStone")
local UpgradeRemote = ReplicatedStorage:WaitForChild("Upgrade")


_G.AutoPickaxe = false
_G.AutoSawDistance = false
_G.AutoBuildFloor = false


local shopItemsData = {}
local filepath = "custom_hub_data_" .. tostring(LocalPlayer.UserId) .. ".json"
local savedData = {history = {}, models = {}}


local function loadSavedData()
    local success, content = pcall(function()
        return readfile(filepath)
    end)
    if success and content then
        local decodeSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if decodeSuccess and decoded then
            savedData = decoded
        end
    end
end


local function saveCurrentData()
    pcall(function()
        writefile(filepath, HttpService:JSONEncode(savedData))
    end)
end


loadSavedData()


local function analyzeItem(itemArg)
    local hist = savedData.history[itemArg]
    if not hist or #hist < 4 then return end
   
    local isArithmetic = true
    local isGeometric = true
   
    local diffs = {}
    local ratios = {}
   
    for i = 2, #hist do
        local d = hist[i] - hist[i-1]
        local r = hist[i-1] ~= 0 and (hist[i] / hist[i-1]) or 0
        table.insert(diffs, d)
        table.insert(ratios, r)
    end
   
    local firstDiff = diffs[1]
    for _, d in ipairs(diffs) do
        if math.abs(d - firstDiff) > 2 then
            isArithmetic = false
            break
        end
    end
   
    local firstRatio = ratios[1]
    for _, r in ipairs(ratios) do
        if math.abs(r - firstRatio) > 0.05 then
            isGeometric = false
            break
        end
    end
   
    if isGeometric then
        local sumRatio = 0
        for _, r in ipairs(ratios) do sumRatio = sumRatio + r end
        savedData.models[itemArg] = {
            type = "geometric",
            factor = sumRatio / #ratios
        }
    elseif isArithmetic then
        local sumDiff = 0
        for _, d in ipairs(diffs) do sumDiff = sumDiff + d end
        savedData.models[itemArg] = {
            type = "arithmetic",
            factor = sumDiff / #diffs
        }
    end
    saveCurrentData()
end


local function getCost(upgradeName)
    local upgFolder = LocalPlayer:FindFirstChild("Upgrades")
    local item = upgFolder and upgFolder:FindFirstChild(upgradeName)
    if item and item:FindFirstChild("Cost") then
        return item.Cost.Value
    end
    return nil
end


local function getPredictedCost(itemArg)
    local realCost = getCost(itemArg)
    if realCost and realCost > 0 then
        return realCost
    end
   
    local model = savedData.models[itemArg]
    local hist = savedData.history[itemArg]
    if model and hist and #hist > 0 then
        local lastVal = hist[#hist]
        if model.type == "geometric" then
            return math.round(lastVal * model.factor)
        elseif model.type == "arithmetic" then
            return math.round(lastVal + model.factor)
        end
    end
    return nil
end


local lastKnownCosts = {}
task.spawn(function()
    while task.wait(1) do
        for _, item in ipairs(shopItemsData) do
            local realCost = getCost(item.Arg)
            if realCost and realCost > 0 then
                if not lastKnownCosts[item.Arg] then
                    lastKnownCosts[item.Arg] = realCost
                elseif lastKnownCosts[item.Arg] ~= realCost then
                    if not savedData.history[item.Arg] then
                        savedData.history[item.Arg] = {}
                    end
                    local hist = savedData.history[item.Arg]
                    if hist[#hist] ~= lastKnownCosts[item.Arg] then
                        table.insert(hist, lastKnownCosts[item.Arg])
                    end
                    if hist[#hist] ~= realCost then
                        table.insert(hist, realCost)
                    end
                    if #hist > 15 then
                        table.remove(hist, 1)
                    end
                    lastKnownCosts[item.Arg] = realCost
                    analyzeItem(item.Arg)
                end
            end
        end
    end
end)


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmHub"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")


local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 360)
MainFrame.Position = UDim2.new(0.5, -260, 0.4, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui


local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame


local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame


local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame


local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar


local TopHide = Instance.new("Frame")
TopHide.Size = UDim2.new(1, 0, 0, 10)
TopHide.Position = UDim2.new(0, 0, 1, -10)
TopHide.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TopHide.BorderSizePixel = 0
TopHide.Parent = TopBar


local Title = Instance.new("TextLabel")
Title.Text = " Auto Farm Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar


local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 2)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = TopBar


local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 2)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Parent = TopBar


local TabsFrame = Instance.new("Frame")
TabsFrame.Name = "TabsFrame"
TabsFrame.Size = UDim2.new(0, 130, 1, -40)
TabsFrame.Position = UDim2.new(0, 0, 0, 40)
TabsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TabsFrame.BorderSizePixel = 0
TabsFrame.Parent = MainFrame


local TabsList = Instance.new("UIListLayout")
TabsList.Padding = UDim.new(0, 2)
TabsList.Parent = TabsFrame


local PagesFrame = Instance.new("Frame")
PagesFrame.Name = "PagesFrame"
PagesFrame.Size = UDim2.new(1, -145, 1, -50)
PagesFrame.Position = UDim2.new(0, 140, 0, 50)
PagesFrame.BackgroundTransparency = 1
PagesFrame.Parent = MainFrame


local pages = {}
local tabButtons = {}


local function createTab(name, isDefault)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 2
    Page.Visible = isDefault
    Page.Parent = PagesFrame
   
    local PageList = Instance.new("UIListLayout")
    PageList.Padding = UDim.new(0, 8)
    PageList.Parent = Page
   
    pages[name] = Page


    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 40)
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = name
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 12
    TabBtn.TextColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    TabBtn.Parent = TabsFrame
   
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        for _, b in pairs(tabButtons) do b.TextColor3 = Color3.fromRGB(150, 150, 160) end
        Page.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    table.insert(tabButtons, TabBtn)
   
    return Page
end


local function createToggle(page, text, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -5, 0, 45)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)


    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0, 160, 1, 0)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame


    local SwitchBG = Instance.new("TextButton")
    SwitchBG.Text = ""
    SwitchBG.Size = UDim2.new(0, 40, 0, 20)
    SwitchBG.Position = UDim2.new(1, -55, 0.5, -10)
    SwitchBG.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    SwitchBG.Parent = Frame
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)


    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 14, 0, 14)
    Circle.Position = UDim2.new(0, 3, 0.5, -7)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = SwitchBG
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)


    local state = false
    SwitchBG.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = state and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(45, 45, 55)
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(SwitchBG, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    end)
end


local function createShopRow(page, displayName, remoteArg)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -5, 0, 48)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)


    local Label = Instance.new("TextLabel")
    Label.Text = displayName
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.Position = UDim2.new(0, 8, 0, 4)
    Label.Size = UDim2.new(0, 110, 0, 20)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame


    local PriceLabel = Instance.new("TextLabel")
    PriceLabel.Text = "💰 ..."
    PriceLabel.Font = Enum.Font.Gotham
    PriceLabel.TextSize = 9
    PriceLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
    PriceLabel.Position = UDim2.new(0, 8, 0, 26)
    PriceLabel.Size = UDim2.new(0, 110, 0, 16)
    PriceLabel.TextXAlignment = Enum.TextXAlignment.Left
    PriceLabel.BackgroundTransparency = 1
    PriceLabel.Parent = Frame


    task.spawn(function()
        while task.wait(1) do
            if not Frame.Parent then break end
            local cost = getPredictedCost(remoteArg)
            PriceLabel.Text = cost and ("💰 " .. tostring(cost)) or "💰 —"
        end
    end)


    local PriorityBox = Instance.new("TextBox")
    PriorityBox.Size = UDim2.new(0, 30, 0, 24)
    PriorityBox.Position = UDim2.new(0, 130, 0.5, -12)
    PriorityBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    PriorityBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    PriorityBox.Text = "1"
    PriorityBox.Font = Enum.Font.GothamMedium
    PriorityBox.TextSize = 11
    PriorityBox.Parent = Frame
    Instance.new("UICorner", PriorityBox).CornerRadius = UDim.new(0, 4)


    local AutoSwitch = Instance.new("TextButton")
    AutoSwitch.Text = ""
    AutoSwitch.Size = UDim2.new(0, 34, 0, 18)
    AutoSwitch.Position = UDim2.new(0, 175, 0.5, -9)
    AutoSwitch.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    AutoSwitch.Parent = Frame
    Instance.new("UICorner", AutoSwitch).CornerRadius = UDim.new(1, 0)


    local AutoCircle = Instance.new("Frame")
    AutoCircle.Size = UDim2.new(0, 12, 0, 12)
    AutoCircle.Position = UDim2.new(0, 3, 0.5, -6)
    AutoCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AutoCircle.Parent = AutoSwitch
    Instance.new("UICorner", AutoCircle).CornerRadius = UDim.new(1, 0)


    local BuyBtn = Instance.new("TextButton")
    BuyBtn.Size = UDim2.new(0, 55, 0, 24)
    BuyBtn.Position = UDim2.new(1, -63, 0.5, -12)
    BuyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    BuyBtn.Text = "Купить"
    BuyBtn.Font = Enum.Font.GothamBold
    BuyBtn.TextSize = 10
    BuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BuyBtn.Parent = Frame
    Instance.new("UICorner", BuyBtn).CornerRadius = UDim.new(0, 4)


    local itemState = {
        Arg = remoteArg,
        Auto = false,
        PriorityBox = PriorityBox
    }


    AutoSwitch.MouseButton1Click:Connect(function()
        itemState.Auto = not itemState.Auto
        local targetPos = itemState.Auto and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        local targetColor = itemState.Auto and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(45, 45, 55)
        TweenService:Create(AutoCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(AutoSwitch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    end)


    BuyBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(function() UpgradeRemote:InvokeServer(remoteArg) end)
        end)
    end)


    table.insert(shopItemsData, itemState)
end


local farmPage = createTab("⚔️ Авто фарм", true)
local shop1Page = createTab("🛒 Магазин 1", false)
local shop2Page = createTab("🛒 Магазин 2", false)


createToggle(farmPage, "Авто-Кирка (Камни)", function(val) _G.AutoPickaxe = val end)
createToggle(farmPage, "Авто-Станок (Пилы)", function(val) _G.AutoSawDistance = val end)
createToggle(farmPage, "Авто-Стройка", function(val) _G.AutoBuildFloor = val end)


createShopRow(shop1Page, "Рюкзак", "Backpack")
createShopRow(shop1Page, "Скор. кирки", "PickaxeSpeed")
createShopRow(shop1Page, "Скор. станка", "CutSpeed")


createShopRow(shop2Page, "Множ. распила", "CutterMultiplier")
createShopRow(shop2Page, "Множ. камня", "StoneMultiplier")
createShopRow(shop2Page, "Множ. постройки", "PlaceMultiplier")


local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)


local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 520, 0, 40) or UDim2.new(0, 520, 0, 360)
    TabsFrame.Visible = not minimized
    PagesFrame.Visible = not minimized
    TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = targetSize}):Play()
    MinimizeBtn.Text = minimized and "+" or "—"
end)


local lastPrompt = nil
local savedDistances = {}
local savedLOS = {}
local currentHoldingKey = nil


local function resetAllPrompts()
    for prompt, originalDist in pairs(savedDistances) do
        pcall(function() if prompt and prompt.Parent then prompt.MaxActivationDistance = originalDist end end)
    end
    for prompt, originalLOS in pairs(savedLOS) do
        pcall(function() if prompt and prompt.Parent then prompt.RequiresLineOfSight = originalLOS end end)
    end
    savedDistances = {}
    savedLOS = {}
end


CloseBtn.MouseButton1Click:Connect(function()
    _G.AutoPickaxe = false
    _G.AutoSawDistance = false
    _G.AutoBuildFloor = false
   
    for _, item in pairs(shopItemsData) do
        item.Auto = false
    end
   
    pcall(function() KickStone:InvokeServer(false) end)
   
    if currentHoldingKey then
        pcall(function() VirtualInputManager:SendKeyEvent(false, currentHoldingKey, false, game) end)
        currentHoldingKey = nil
    end
   
    resetAllPrompts()
    ScreenGui:Destroy()
end)


local function getBackpackLimit()
    local val = Limits:GetAttribute("Backpack")
    if not val and Limits:FindFirstChild("Backpack") then
        val = Limits.Backpack.Value
    end
    return val or 50
end


local mineActive = false
local lastKickTime = 0


task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoPickaxe then
            local currentTotal = Bricks.Value + Stones.Value
            local limit = getBackpackLimit()
           
            if currentTotal >= (limit - 2) then
                if mineActive then
                    task.spawn(function() pcall(function() KickStone:InvokeServer(false) end) end)
                    mineActive = false
                end
            else
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    local pickaxe = LocalPlayer.Backpack:FindFirstChild("Pickaxe") or char:FindFirstChild("Pickaxe")
                    if pickaxe and hum and pickaxe.Parent == LocalPlayer.Backpack then
                        hum:EquipTool(pickaxe)
                    end
                end


                if not mineActive or (tick() - lastKickTime >= 2.0) then
                    task.spawn(function() pcall(function() KickStone:InvokeServer(true) end) end)
                    mineActive = true
                    lastKickTime = tick()
                end
            end
        else
            if mineActive then
                task.spawn(function() pcall(function() KickStone:InvokeServer(false) end) end)
                mineActive = false
            end
        end
    end
end)


local function getClosestSawPrompt()
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end


    local closestPrompt = nil
    local shortestDistance = math.huge


    local folder1 = workspace:FindFirstChild("Saws")
    local folder2 = folder1 and folder1:FindFirstChild("Saws")
    local searchArea = folder2 or folder1 or workspace


    for _, saw in pairs(searchArea:GetChildren()) do
        if saw.Name == "Saw" and saw:IsA("Model") then
            local base = saw:FindFirstChild("Base") or saw:FindFirstChildOfClass("BasePart")
            if base then
                local distance = (rootPart.Position - base.Position).Magnitude
                if distance < shortestDistance then
                    local use = saw:FindFirstChild("Use")
                    local prompt = use and use:FindFirstChild("UsePP")
                    if prompt then
                        shortestDistance = distance
                        closestPrompt = prompt
                    end
                end
            end
        end
    end
    return closestPrompt
end


local holdingPrompt = nil
local lastSawHoldTime = 0


task.spawn(function()
    while task.wait(0.1) do
        local currentPrompt = getClosestSawPrompt()
       
        if lastPrompt and lastPrompt ~= currentPrompt then
            pcall(function()
                if savedDistances[lastPrompt] then
                    lastPrompt.MaxActivationDistance = savedDistances[lastPrompt]
                end
                if savedLOS[lastPrompt] ~= nil then
                    lastPrompt.RequiresLineOfSight = savedLOS[lastPrompt]
                end
            end)
        end
       
        if _G.AutoSawDistance and Stones.Value > 2 then
            if currentPrompt then
                if currentPrompt.MaxActivationDistance ~= 9999 then
                    savedDistances[currentPrompt] = currentPrompt.MaxActivationDistance
                    currentPrompt.MaxActivationDistance = 9999
                end
                if currentPrompt.RequiresLineOfSight ~= false then
                    savedLOS[currentPrompt] = currentPrompt.RequiresLineOfSight
                    currentPrompt.RequiresLineOfSight = false
                end
               
                local keyCode = currentPrompt.KeyboardKeyCode
               
                if holdingPrompt ~= currentPrompt or currentHoldingKey ~= keyCode then
                    if currentHoldingKey then
                        VirtualInputManager:SendKeyEvent(false, currentHoldingKey, false, game)
                    end
                    holdingPrompt = currentPrompt
                    currentHoldingKey = keyCode
                    lastSawHoldTime = 0
                end


                if tick() - lastSawHoldTime >= 2.0 then
                    VirtualInputManager:SendKeyEvent(true, currentHoldingKey, false, game)
                    lastSawHoldTime = tick()
                end
                lastPrompt = currentPrompt
            else
                if currentHoldingKey then
                    VirtualInputManager:SendKeyEvent(false, currentHoldingKey, false, game)
                    currentHoldingKey = nil
                    holdingPrompt = nil
                end
            end
        else
            if currentHoldingKey then
                VirtualInputManager:SendKeyEvent(false, currentHoldingKey, false, game)
                currentHoldingKey = nil
                holdingPrompt = nil
            end
        end
    end
end)


task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoBuildFloor and Bricks.Value >= 1 then
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local floorsFolder = workspace:FindFirstChild("Floors")
                if floorsFolder then
                    for _, obj in pairs(floorsFolder:GetDescendants()) do
                        if not _G.AutoBuildFloor or Bricks.Value < 1 then break end
                        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
                            local distance = (rootPart.Position - obj.Position).Magnitude
                            if distance <= 999999 then
                                task.spawn(function()
                                    pcall(function() PlaceRemote:InvokeServer(obj) end)
                                end)
                                task.wait(0.01)
                            end
                        end
                    end
                end
            end
        end
    end
end)


task.spawn(function()
    while task.wait(0.5) do
        local activeShopItems = {}
       
        for _, item in ipairs(shopItemsData) do
            if item.Auto then
                table.insert(activeShopItems, item)
            end
        end
       
        if #activeShopItems > 0 then
            table.sort(activeShopItems, function(a, b)
                local prioA = tonumber(a.PriorityBox.Text) or 999
                local prioB = tonumber(b.PriorityBox.Text) or 999
                if prioA == prioB then
                    local costA = getPredictedCost(a.Arg) or 999999
                    local costB = getPredictedCost(b.Arg) or 999999
                    return costA < costB
                end
                return prioA < prioB
            end)
           
            for _, item in ipairs(activeShopItems) do
                if item.Auto then
                    task.spawn(function()
                        pcall(function() UpgradeRemote:InvokeServer(item.Arg) end)
                    end)
                    task.wait(0.1)
                end
            end
        end
    end
end)
