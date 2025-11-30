-- FTF ESP Script — stable UI (square), working features, Teleport list
-- Notes:
--  - Main menu is SQUARE (no UICorner), positioned bottom-center, draggable by header
--  - Startup animated notice is present
--  - Categories: Visuais, Textures, Timers, Teleporte
--  - Search filters options inside the active category
--  - Teleport category contains dynamic list of players with buttons to teleport to them
--  - Door ESP uses SelectionBox (AlwaysOnTop) and improved primary-part detection
--  - Highlights parented to Workspace; textures/snow use safe batching/backups
-- Usage:
--  - Copy/replace this file in your repo and load as you did before

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Root GUI setup
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
for _,v in pairs(CoreGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- Storage
local buttonLabelMap = {}     -- button -> TextLabel
local buttonCategory = {}     -- button -> category name
local uiButtons = {}          -- list of option buttons
local teleportButtons = {}    -- player -> button

-- Categories
local categories = {"Visuais","Textures","Timers","Teleporte"}
local activeCategory = "Visuais"

-- ---------- Startup animated notice ----------
local function showStartupNotice()
    local noticeGui = Instance.new("ScreenGui", GUI)
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false

    local width, height = 520, 72
    local frame = Instance.new("Frame", noticeGui)
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.88, 0)
    frame.BackgroundColor3 = Color3.fromRGB(8,10,12)
    frame.BorderSizePixel = 0
    local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(40,50,64); stroke.Thickness = 1; stroke.Transparency = 0.3

    local icon = Instance.new("TextLabel", frame)
    icon.Size = UDim2.new(0,40,0,40)
    icon.Position = UDim2.new(0,12,0.5,-20)
    icon.BackgroundColor3 = Color3.fromRGB(14,16,20)
    icon.Font = Enum.Font.FredokaOne
    icon.Text = "K"
    icon.TextColor3 = Color3.fromRGB(100,170,220)
    icon.TextSize = 22
    icon.BorderSizePixel = 0

    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, -84, 1, 0)
    txt.Position = UDim2.new(0, 72, 0, 6)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(200,220,240)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left

    frame.Position = UDim2.new(0.5, -width/2, 0.92, 36)
    TweenService:Create(frame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -width/2, 0.88, 0)}):Play()
    task.delay(4.5, function() if noticeGui and noticeGui.Parent then noticeGui:Destroy() end end)
end
showStartupNotice()

-- ---------- MAIN MENU (square corners) ----------
local W, H = 980, 360
local Main = Instance.new("Frame", GUI)
Main.Name = "FTF_Menu_Frame"
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0.5, -W/2, 1, -H - 24)
Main.BackgroundColor3 = Color3.fromRGB(10,12,16)
Main.BorderSizePixel = 0
-- Intentionally square: no UICorner on this frame
local outline = Instance.new("UIStroke", Main); outline.Color = Color3.fromRGB(36,46,60); outline.Thickness = 1; outline.Transparency = 0.15

-- Header (draggable)
local Header = Instance.new("Frame", Main)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 72)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Text = "FTF - David's ESP"
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(200,220,240)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 16, 0, 18)
Title.Size = UDim2.new(0.5,0,0,36)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", Header)
SearchBox.PlaceholderText = "Pesquisar opções..."
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0, 320, 0, 34)
SearchBox.Position = UDim2.new(1, -356, 0, 18)
SearchBox.BackgroundColor3 = Color3.fromRGB(14,16,20)
SearchBox.TextColor3 = Color3.fromRGB(200,220,240)
local searchStroke = Instance.new("UIStroke", SearchBox); searchStroke.Color = Color3.fromRGB(60,80,110); searchStroke.Thickness = 1; searchStroke.Transparency = 0.6

-- Left categories column
local LeftCol = Instance.new("Frame", Main)
LeftCol.Size = UDim2.new(0, 220, 1, -88)
LeftCol.Position = UDim2.new(0, 16, 0, 78)
LeftCol.BackgroundTransparency = 1
local CatLayout = Instance.new("UIListLayout", LeftCol); CatLayout.SortOrder = Enum.SortOrder.LayoutOrder; CatLayout.Padding = UDim.new(0,12)

local function makeCategoryBtn(name, order)
    local b = Instance.new("TextButton", LeftCol)
    b.Size = UDim2.new(1,0,0,56)
    b.LayoutOrder = order
    b.Text = name
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 16
    b.TextColor3 = Color3.fromRGB(180,200,220)
    b.BackgroundColor3 = Color3.fromRGB(12,14,18)
    local stroke = Instance.new("UIStroke", b); stroke.Color = Color3.fromRGB(36,46,60); stroke.Thickness = 1; stroke.Transparency = 0.5
    return b
end

local categoryButtons = {}
for i,c in ipairs(categories) do
    categoryButtons[c] = makeCategoryBtn(c, i)
end

-- Content area
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -260, 1, -88)
Content.Position = UDim2.new(0, 248, 0, 78)
Content.BackgroundTransparency = 1

local Options = Instance.new("ScrollingFrame", Content)
Options.Size = UDim2.new(1, -12, 1, 0)
Options.Position = UDim2.new(0,6,0,0)
Options.BackgroundTransparency = 1
Options.ScrollBarThickness = 8
Options.BorderSizePixel = 0
local OptLayout = Instance.new("UIListLayout", Options); OptLayout.SortOrder = Enum.SortOrder.LayoutOrder; OptLayout.Padding = UDim.new(0,10)
OptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Options.CanvasSize = UDim2.new(0,0,0, OptLayout.AbsoluteContentSize.Y + 12)
end)

-- Option button creator
local function createOption(text, c1, c2)
    local btn = Instance.new("TextButton", Options)
    btn.Name = "Opt_" .. text:gsub("%s+","_")
    btn.Size = UDim2.new(1, -12, 0, 56)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false

    local bg = Instance.new("Frame", btn); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1; bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,10)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation = 45
    local inner = Instance.new("Frame", bg); inner.Size = UDim2.new(1,-8,1,-8); inner.Position = UDim2.new(0,4,0,4); inner.BackgroundColor3 = Color3.fromRGB(8,10,12)
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", inner); label.Size = UDim2.new(1,-24,1,0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = text; label.TextSize = 16; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left
    local ind = Instance.new("Frame", inner); ind.Size = UDim2.new(0,66,0,26); ind.Position = UDim2.new(1,-92,0.5,-13); ind.BackgroundColor3 = Color3.fromRGB(10,12,14)
    local indCorner = Instance.new("UICorner", ind); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", ind); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0); indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    local indBarCorner = Instance.new("UICorner", indBar); indBarCorner.CornerRadius = UDim.new(0,6)

    buttonLabelMap[btn] = label
    table.insert(uiButtons, btn)
    return btn, label
end

-- Create primary options and assign categories
local btnPlayer, lblPlayer = createOption("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101)); buttonCategory[btnPlayer] = "Visuais"
local btnComputer, lblComputer = createOption("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255)); buttonCategory[btnComputer] = "Visuais"
local btnDoor, lblDoor = createOption("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100)); buttonCategory[btnDoor] = "Visuais"
local btnFreeze, lblFreeze = createOption("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80)); buttonCategory[btnFreeze] = "Visuais"

local btnRemoveTex, lblRemoveTex = createOption("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140)); buttonCategory[btnRemoveTex] = "Textures"
local btnWhiteBrick, lblWhiteBrick = createOption("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245)); buttonCategory[btnWhiteBrick] = "Textures"
local btnSnow, lblSnow = createOption("Snow texture", Color3.fromRGB(235,245,255), Color3.fromRGB(245,250,255)); buttonCategory[btnSnow] = "Textures"

local btnDown, lblDown = createOption("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90)); buttonCategory[btnDown] = "Timers"

-- Teleport category: header + dynamic players
local btnTeleportHeader, lblTeleportHeader = createOption("Teleporte — selecione jogador abaixo", Color3.fromRGB(120,120,140), Color3.fromRGB(160,160,180)); buttonCategory[btnTeleportHeader] = "Teleporte"

-- refresh visibility helper
local function refreshVisibility()
    local q = string.lower(tostring(SearchBox.Text or ""))
    for _,btn in ipairs(uiButtons) do
        local cat = buttonCategory[btn] or "Visuais"
        local text = (buttonLabelMap[btn] and buttonLabelMap[btn].Text) or (btn.Text or "")
        local visible = (cat == activeCategory)
        if visible and q ~= "" then
            if not string.find(string.lower(text), q, 1, true) then visible = false end
        end
        btn.Visible = visible
    end
    -- teleport buttons are created separately and included in uiButtons when created
    Options.CanvasSize = UDim2.new(0,0,0, OptLayout.AbsoluteContentSize.Y + 12)
end

-- category buttons binding
for name,btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function()
        activeCategory = name
        for k,v in pairs(categoryButtons) do
            if k == name then v.BackgroundColor3 = Color3.fromRGB(22,32,44); v.TextColor3 = Color3.fromRGB(250,250,250)
            else v.BackgroundColor3 = Color3.fromRGB(12,14,18); v.TextColor3 = Color3.fromRGB(180,200,220) end
        end
        refreshVisibility()
    end)
end
-- initial
categoryButtons[activeCategory].BackgroundColor3 = Color3.fromRGB(22,32,44); categoryButtons[activeCategory].TextColor3 = Color3.fromRGB(250,250,250)
refreshVisibility()

SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshVisibility)

-- ---------- FEATURE IMPLEMENTATIONS ----------
-- Player ESP
local PlayerESPActive = false
local playerHighlights = {}
local nameTags = {}
local function isBeast(pl) return pl.Character and pl.Character:FindFirstChild("BeastPowers") ~= nil end
local function addPlayerESP(pl)
    if pl == LocalPlayer then return end
    if not pl.Character then return end
    if playerHighlights[pl] then pcall(function() playerHighlights[pl]:Destroy() end); playerHighlights[pl] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_Player_ESP]"; h.Adornee = pl.Character; h.Parent = Workspace
    if isBeast(pl) then h.FillColor = Color3.fromRGB(240,28,80); h.OutlineColor = Color3.fromRGB(255,188,188)
    else h.FillColor = Color3.fromRGB(52,215,101); h.OutlineColor = Color3.fromRGB(170,255,200) end
    h.FillTransparency = 0.12; h.OutlineTransparency = 0.04; h.Enabled = true
    playerHighlights[pl] = h
end
local function removePlayerESP(pl) if playerHighlights[pl] then pcall(function() playerHighlights[pl]:Destroy() end); playerHighlights[pl] = nil end end
local function refreshPlayerESPAll()
    for _,pl in ipairs(Players:GetPlayers()) do
        if PlayerESPActive then addPlayerESP(pl) else removePlayerESP(pl) end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.08); if PlayerESPActive then addPlayerESP(p) end end) end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

-- Computer ESP
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(m) return m and m:IsA("Model") and (m.Name:lower():find("computer") or m.Name:lower():find("pc")) end
local function getScreenPart(m)
    for _,n in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        local part = m:FindFirstChild(n, true)
        if part and part:IsA("BasePart") then return part end
    end
    local biggest
    for _,c in ipairs(m:GetDescendants()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function addComputerESP(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end
    local h = Instance.new("Highlight"); h.Name = "[FTF_Computer_ESP]"; h.Adornee = model; h.Parent = Workspace
    local s = getScreenPart(model)
    h.FillColor = (s and s.Color) or Color3.fromRGB(77,164,255); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    compHighlights[model] = h
end
local function removeComputerESP(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end end
Workspace.DescendantAdded:Connect(function(d) if ComputerESPActive and isComputerModel(d) then task.delay(0.05, function() addComputerESP(d) end) end end)
Workspace.DescendantRemoving:Connect(removeComputerESP)

-- Door ESP (SelectionBox) - improved detection & visibility
local DoorESPActive = false
local doorBoxes = {} -- key: model or part -> SelectionBox
local function isDoorCandidate(obj)
    if not obj then return false end
    if obj:IsA("Model") then
        local n = obj.Name:lower()
        return n:find("door") or n:find("exit")
    elseif obj:IsA("BasePart") then
        local n = obj.Name:lower()
        return n:find("door") or n:find("doorboard") or n:find("exitdoor")
    end
    return false
end
local function getDoorPrimary(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then return obj.PrimaryPart end
    local candidates = {"DoorBoard","Door","Part","ExitDoorTrigger","DoorL","DoorR","BasePart","Main","Panel"}
    for _,n in ipairs(candidates) do
        local v = obj:FindFirstChild(n, true)
        if v and v:IsA("BasePart") then return v end
    end
    local biggest
    for _,c in ipairs(obj:GetDescendants()) do
        if c:IsA("BasePart") then
            if not biggest or c.Size.Magnitude > biggest.Size.Magnitude then biggest = c end
        end
    end
    return biggest
end
local function createDoorBox(key, targetPart)
    if not targetPart then return end
    if doorBoxes[key] then pcall(function() doorBoxes[key]:Destroy() end); doorBoxes[key] = nil end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_DoorBox]"
    box.Adornee = targetPart
    box.Color3 = Color3.fromRGB(255,220,120)
    pcall(function() box.LineThickness = 0.18 end)
    pcall(function() box.SurfaceTransparency = 1 end)
    pcall(function() box.DepthMode = Enum.SelectionBoxDepthMode.AlwaysOnTop end)
    box.Parent = Workspace
    doorBoxes[key] = box
end
local function addDoorCandidate(obj)
    if not obj then return end
    local key = obj
    local part = getDoorPrimary(obj)
    if part then createDoorBox(key, part) end
end
local function removeDoorCandidate(obj)
    if not obj then return end
    if doorBoxes[obj] then pcall(function() doorBoxes[obj]:Destroy() end); doorBoxes[obj] = nil end
    if obj:IsA("BasePart") then
        local mdl = obj:FindFirstAncestorWhichIsA("Model")
        if mdl and doorBoxes[mdl] then pcall(function() doorBoxes[mdl]:Destroy() end); doorBoxes[mdl] = nil end
    end
end
Workspace.DescendantAdded:Connect(function(d) if DoorESPActive and isDoorCandidate(d) then task.delay(0.05, function() addDoorCandidate(d) end) end end)
Workspace.DescendantRemoving:Connect(function(d) if isDoorCandidate(d) then removeDoorCandidate(d) end end)

-- Freeze Pods (Highlight)
local FreezeActive = false
local podHighlights = {}
local function isPod(m)
    if not m then return false end
    if m:IsA("Model") then
        local n = m.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod")) or n:find("capsule")
    elseif m:IsA("BasePart") then
        local n = m.Name:lower()
        return n:find("freezepod") or (n:find("freeze") and n:find("pod"))
    end
    return false
end
local function addPod(m)
    if podHighlights[m] then pcall(function() podHighlights[m]:Destroy() end); podHighlights[m] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_PodHighlight]"; h.Adornee = m; h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[m] = h
end
local function removePod(m) if podHighlights[m] then pcall(function() podHighlights[m]:Destroy() end); podHighlights[m] = nil end end
Workspace.DescendantAdded:Connect(function(d) if FreezeActive and isPod(d) then task.delay(0.05, function() addPod(d) end) end end)
Workspace.DescendantRemoving:Connect(function(d) if isPod(d) then removePod(d) end end)

-- Textures: White brick (safe) and Snow (safe)
local TextureActive = false
local textureBackup = {}
local textureConn = nil
local function isPlayerCharacterPart(part)
    if not part then return false end
    local mdl = part:FindFirstAncestorWhichIsA("Model")
    if mdl then return Players:GetPlayerFromCharacter(mdl) ~= nil end
    return false
end
local function saveAndWhite(part)
    if not part or not part:IsA("BasePart") then return end
    if isPlayerCharacterPart(part) then return end
    if textureBackup[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    textureBackup[part] = {Color = (okC and col) or nil, Material = (okM and mat) or nil}
    pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end)
end
local function enableWhite()
    if TextureActive then return end
    TextureActive = true
    task.spawn(function()
        local desc = Workspace:GetDescendants(); local batch = 0
        for i=1,#desc do
            local d = desc[i]
            if d and d:IsA("BasePart") then
                saveAndWhite(d)
                batch = batch + 1
                if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
            end
        end
    end)
    textureConn = Workspace.DescendantAdded:Connect(function(d) if d and d:IsA("BasePart") and not isPlayerCharacterPart(d) then task.defer(function() saveAndWhite(d) end) end end)
end
local function restoreWhite()
    for part,props in pairs(textureBackup) do
        if part and part.Parent then
            pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end)
        end
    end
    textureBackup = {}
end
local function disableWhite()
    if not TextureActive then return end
    TextureActive = false
    if textureConn then pcall(function() textureConn:Disconnect() end); textureConn = nil end
    task.spawn(restoreWhite)
end

-- Snow texture toggle (user script integrated, safe backup)
local SnowActive = false
local snowBackup = {parts = {}, lighting = {}, skies = {}, createdSky = nil}
local function enableSnow()
    if SnowActive then return end
    SnowActive = true
    -- lighting backup
    snowBackup.lighting = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale }
    -- save skies and remove
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then table.insert(snowBackup.skies, v:Clone()); v:Destroy() end end
    local sky = Instance.new("Sky"); sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""; sky.Parent = Lighting
    snowBackup.createdSky = sky
    -- set lighting
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogColor = Color3.new(1,1,1)
    Lighting.FogEnd = 100000; Lighting.Brightness = 2; Lighting.ClockTime = 12
    Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    -- change parts (batched)
    task.spawn(function()
        local desc = Workspace:GetDescendants(); local batch = 0
        for i=1,#desc do
            local obj = desc[i]
            if obj and obj:IsA("BasePart") then
                local mdl = obj:FindFirstAncestorWhichIsA("Model")
                local skip = (mdl and Players:GetPlayerFromCharacter(mdl) ~= nil)
                if not skip then
                    if not snowBackup.parts[obj] then
                        local okC, col = pcall(function() return obj.Color end)
                        local okM, mat = pcall(function() return obj.Material end)
                        snowBackup.parts[obj] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
                    end
                    pcall(function() obj.Color = Color3.new(1,1,1); obj.Material = Enum.Material.SmoothPlastic end)
                end
                batch = batch + 1
                if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
            end
        end
    end)
end
local function disableSnow()
    if not SnowActive then return end
    SnowActive = false
    task.spawn(function()
        local entries = {}
        for p,props in pairs(snowBackup.parts) do entries[#entries+1] = {p=p, props=props} end
        local batch = 0
        for _,e in ipairs(entries) do
            local part = e.p; local props = e.props
            if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end) end
            batch = batch + 1
            if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
        end
        snowBackup.parts = {}
    end)
    -- restore lighting
    local L = snowBackup.lighting
    if L then
        Lighting.Ambient = L.Ambient or Lighting.Ambient
        Lighting.OutdoorAmbient = L.OutdoorAmbient or Lighting.OutdoorAmbient
        Lighting.FogColor = L.FogColor or Lighting.FogColor
        Lighting.FogEnd = L.FogEnd or Lighting.FogEnd
        Lighting.Brightness = L.Brightness or Lighting.Brightness
        Lighting.ClockTime = L.ClockTime or Lighting.ClockTime
        Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale or Lighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale or Lighting.EnvironmentSpecularScale
    end
    if snowBackup.createdSky and snowBackup.createdSky.Parent then snowBackup.createdSky:Destroy() end
    for _,cl in ipairs(snowBackup.skies) do local ok,new = pcall(function() return cl:Clone() end) if ok and new then new.Parent = Lighting end end
    snowBackup.skies = {}
    snowBackup.lighting = {}
    snowBackup.createdSky = nil
end

-- Ragdoll/Down timer: minimal working indicator (uses earlier billboards)
local DownActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}
local function createRagdollBillboard(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head") if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI); billboard.Name = "[FTF_Ragdoll]"; billboard.Adornee = head
    billboard.Size = UDim2.new(0,160,0,48); billboard.StudsOffset = Vector3.new(0,3.2,0); billboard.AlwaysOnTop = true
    local bg = Instance.new("Frame", billboard); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(24,24,28)
    local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1,-16,1,-16); txt.Position = UDim2.new(0,8,0,6); txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold; txt.TextSize = 18; txt.TextColor3 = Color3.fromRGB(220,220,230); txt.Text = tostring(DOWN_TIME) .. "s"
    local info = { gui = billboard, label = txt, endTime = tick() + DOWN_TIME }
    ragdollBillboards[player] = info
    return info
end
local function removeRagdoll(player) if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then ragdollBillboards[player].gui:Destroy() end ragdollBillboards[player] = nil end end
local function attachRagdollListener(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
    task.spawn(function()
        local ok, temp = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not temp then return end
        local ok2, rag = pcall(function() return temp:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not rag then return end
        if rag.Value then local info = createRagdollBillboard(player); if info then info.endTime = tick() + DOWN_TIME end end
        local conn = rag.Changed:Connect(function()
            pcall(function()
                if rag.Value then local info = createRagdollBillboard(player); if info then info.endTime = tick() + DOWN_TIME end else removeRagdoll(player) end
            end)
        end)
        ragdollConnects[player] = conn
    end)
end
for _,p in ipairs(Players:GetPlayers()) do attachRagdollListener(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListener(p) end)
RunService.Heartbeat:Connect(function()
    if not DownActive then return end
    local now = tick()
    for player,info in pairs(ragdollBillboards) do
        if not info or not info.gui or not player or not player.Parent then removeRagdoll(player)
        else
            local rem = info.endTime - now
            if rem <= 0 then removeRagdoll(player) else pcall(function() if info.label then info.label.Text = string.format("%.2f", rem) end end) end
        end
    end
end)

-- ---------- Teleport buttons: dynamic ----------
local function clearTeleportButtons()
    for p,btn in pairs(teleportButtons) do
        if btn and btn.Parent then pcall(function() btn:Destroy() end) end
    end
    teleportButtons = {}
    -- rebuild visibility after clearing
    refreshVisibility()
end

local function buildTeleportButtons()
    clearTeleportButtons()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local btn, lbl = createOption("Teleport to " .. (pl.DisplayName or pl.Name), Color3.fromRGB(100,110,140), Color3.fromRGB(140,150,180))
            buttonCategory[btn] = "Teleporte"
            teleportButtons[pl] = btn
            btn.MouseButton1Click:Connect(function()
                local myChar = LocalPlayer.Character
                local targetChar = pl.Character
                if not myChar or not targetChar then return end
                local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                if not hrp or not thrp then return end
                pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
            end)
        end
    end
    refreshVisibility()
end

Players.PlayerAdded:Connect(function() task.wait(0.12); buildTeleportButtons() end)
Players.PlayerRemoving:Connect(function() task.wait(0.12); buildTeleportButtons() end)
-- initial
buildTeleportButtons()

-- ---------- Option wiring ----------
btnPlayer.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive
    if PlayerESPActive then lblPlayer.Text = "Player ESP (ON)" else lblPlayer.Text = "Player ESP" end
    refreshPlayerESPAll()
end)

btnComputer.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive
    if ComputerESPActive then lblComputer.Text = "Computer ESP (ON)"; refreshComputerESP() else lblComputer.Text = "Computer ESP" end
end)

btnDoor.MouseButton1Click:Connect(function()
    DoorESPActive = not DoorESPActive
    if DoorESPActive then lblDoor.Text = "ESP Doors (ON)"; refreshDoorESPAll() else lblDoor.Text = "ESP Doors"; for k,_ in pairs(doorBoxes) do pcall(function() doorBoxes[k]:Destroy() end); doorBoxes[k] = nil end end
end)

btnFreeze.MouseButton1Click:Connect(function()
    FreezeActive = not FreezeActive
    if FreezeActive then lblFreeze.Text = "Freeze Pods ESP (ON)"; refreshFreezePodsAll() else lblFreeze.Text = "Freeze Pods ESP"; for k,_ in pairs(podHighlights) do pcall(function() podHighlights[k]:Destroy() end); podHighlights[k] = nil end end
end)

btnWhiteBrick.MouseButton1Click:Connect(function()
    if not TextureActive then enableWhite(); lblWhiteBrick.Text = "Ativar Textures Tijolos Brancos (ON)" else disableWhite(); lblWhiteBrick.Text = "Ativar Textures Tijolos Brancos" end
end)

btnSnow.MouseButton1Click:Connect(function()
    if not SnowActive then enableSnow(); lblSnow.Text = "Snow texture (ON)" else disableSnow(); lblSnow.Text = "Snow texture" end
end)

btnDown.MouseButton1Click:Connect(function()
    DownActive = not DownActive
    if DownActive then lblDown.Text = "Ativar Contador de Down (ON)" else lblDown.Text = "Ativar Contador de Down" end
end)

-- btnRemoveTex: simple apply gray to players (best-effort; restoration not tracked here)
btnRemoveTex.MouseButton1Click:Connect(function()
    if not btnRemoveTex._active then
        btnRemoveTex._active = true; lblRemoveTex.Text = "Remove players Textures (ON)"
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _,d in ipairs(p.Character:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("MeshPart") then
                        pcall(function() d.Color = Color3.fromRGB(128,128,132); d.Material = Enum.Material.SmoothPlastic end)
                    end
                end
            end
        end
    else
        btnRemoveTex._active = false; lblRemoveTex.Text = "Remove players Textures"
    end
end)

-- search & visibility already handled

-- ---------- Draggable header ----------
do
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- toggle menu with K
local menuOpen = false
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        Main.Visible = menuOpen
    end
end)

-- cleanup function
local function cleanupAll()
    if GUI and GUI.Parent then GUI:Destroy() end
    for k,v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(compHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(doorBoxes) do pcall(function() v:Destroy() end) end
    for k,v in pairs(podHighlights) do pcall(function() v:Destroy() end) end
end

print("[FTF_ESP] Loaded: square menu bottom, startup notice, Teleporte category, Door ESP fixed")
