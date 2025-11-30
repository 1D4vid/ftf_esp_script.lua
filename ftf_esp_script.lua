--[[
Script for FTF by David – ESP Flat (futuristic buttons + gray-skin + safe toggleable white brick texture)
Correção: o toggle de textura agora ignora partes de personagens e aplica em lotes para não travar outras features.
]]
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- cleanup old GUI instances
for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- Helper: set visible label text inside our custom button
local function setButtonLabel(btn, text)
    if not btn or not btn:IsA("TextButton") then return end
    local bg = btn:FindFirstChild("BG")
    if not bg then
        -- try children search
        for _,c in ipairs(btn:GetChildren()) do
            if c:IsA("Frame") and c.Name=="BG" then bg = c; break end
        end
    end
    if bg then
        local inner = bg:FindFirstChild("Inner")
        if inner then
            local lbl = inner:FindFirstChildWhichIsA("TextLabel")
            if lbl then lbl.Text = text; return end
            -- fallback by name
            local nameLbl = inner:FindFirstChild("Label")
            if nameLbl and nameLbl:IsA("TextLabel") then nameLbl.Text = text; return end
        end
    end
end

-- ---------- Startup notice (futuristic, bottom center) ----------
local function createStartupNotice(opts)
    opts = opts or {}
    local duration = opts.duration or 6
    local width = opts.width or 380
    local height = opts.height or 68

    local noticeGui = Instance.new("ScreenGui")
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false
    noticeGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "NoticeFrame"
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.92, 6)
    frame.AnchorPoint = Vector2.new(0,0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = noticeGui

    local panel = Instance.new("Frame", frame)
    panel.Name = "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.Position = UDim2.new(0, 0, 0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(10,14,20)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0

    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(55,140,220); stroke.Thickness = 1.2; stroke.Transparency = 0.28
    local grad = Instance.new("UIGradient", panel)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14,18,24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,10,14))
    }
    grad.Rotation = 90

    local accent = Instance.new("Frame", panel)
    accent.Size = UDim2.new(0, 6, 1, -12)
    accent.Position = UDim2.new(0, 8, 0, 6)
    accent.BackgroundColor3 = Color3.fromRGB(49,157,255)
    accent.BorderSizePixel = 0
    local aCorner = Instance.new("UICorner", accent); aCorner.CornerRadius = UDim.new(0, 6)

    local iconBg = Instance.new("Frame", panel)
    iconBg.Size = UDim2.new(0, 36, 0, 36)
    iconBg.Position = UDim2.new(0, 24, 0.5, -18)
    iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26)
    iconBg.BorderSizePixel = 0
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0, 10)
    local iconStroke = Instance.new("UIStroke", iconBg); iconStroke.Color = Color3.fromRGB(90,170,225); iconStroke.Thickness = 1; iconStroke.Transparency = 0.48

    local iconLabel = Instance.new("TextLabel", iconBg)
    iconLabel.Size = UDim2.new(1, -6, 1, -6)
    iconLabel.Position = UDim2.new(0, 3, 0, 3)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.FredokaOne
    iconLabel.Text = "K"
    iconLabel.TextColor3 = Color3.fromRGB(100,170,220)
    iconLabel.TextStrokeTransparency = 0.9
    iconLabel.TextSize = 20

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -96, 1, -8)
    txt.Position = UDim2.new(0, 76, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.TextStrokeTransparency = 0.9
    txt.Text = "Clique na letra \"K\" para ativar o menu"
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Center
    txt.TextWrapped = true

    local hint = Instance.new("TextLabel", panel)
    hint.Size = UDim2.new(1, -96, 0, 16)
    hint.Position = UDim2.new(0, 76, 1, -22)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextColor3 = Color3.fromRGB(120,140,170)
    hint.Text = "Pressione novamente para fechar"
    hint.TextXAlignment = Enum.TextXAlignment.Left

    -- subtle glow (less white, bluish)
    local glow = Instance.new("Frame", frame)
    glow.Name = "Glow2"
    glow.Size = UDim2.new(1.1, 0, 0.5, 0)
    glow.Position = UDim2.new(-0.05, 0, -0.35, 0)
    glow.BackgroundColor3 = Color3.fromRGB(49,157,255)
    glow.BackgroundTransparency = 0.96
    glow.BorderSizePixel = 0
    local glowCorner = Instance.new("UICorner", glow)
    glowCorner.CornerRadius = UDim.new(0, 20)

    -- initial state: invisible and slightly lower
    panel.BackgroundTransparency = 1
    txt.TextTransparency = 1
    hint.TextTransparency = 1
    iconLabel.TextTransparency = 1
    accent.BackgroundTransparency = 1
    stroke.Transparency = 1

    -- tween in
    local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -width/2, 0.90, 0)}):Play()
    TweenService:Create(panel, tweenInfo, {BackgroundTransparency = 0.0}):Play()
    TweenService:Create(txt, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(hint, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(iconLabel, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(accent, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(stroke, tweenInfo, {Transparency = 0.28}):Play()

    local pulse = true
    spawn(function()
        while pulse and panel.Parent do
            local t1 = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            TweenService:Create(stroke, t1, {Thickness = 1.6}):Play()
            TweenService:Create(iconLabel, t1, {TextColor3 = Color3.fromRGB(120,200,255)}):Play()
            wait(1.0)
            local t2 = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            TweenService:Create(stroke, t2, {Thickness = 1.2}):Play()
            TweenService:Create(iconLabel, t2, {TextColor3 = Color3.fromRGB(100,170,220)}):Play()
            wait(1.0)
        end
    end)

    spawn(function()
        wait(duration)
        pulse = false
        local outInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(panel, outInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(txt, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(hint, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(iconLabel, outInfo, {TextTransparency = 1}):Play()
        TweenService:Create(accent, outInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
        TweenService:Create(frame, outInfo, {Position = UDim2.new(0.5, -width/2, 0.96, 20)}):Play()
        wait(0.5)
        if noticeGui and noticeGui.Parent then noticeGui:Destroy() end
    end)

    return noticeGui
end

createStartupNotice({duration = 6, width = 380, height = 68})

-- ---------- Main menu frame (futuristic buttons) ----------
local gWidth, gHeight = 360, 420
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.BackgroundColor3 = Color3.fromRGB(8,10,14)
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
Frame.Position = UDim2.new(0.5, -gWidth//2, 0.17, 0)
Frame.Active = true
Frame.Visible = false
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true

local Accent = Instance.new("Frame", Frame)
Accent.Size = UDim2.new(0, 8, 1, 0)
Accent.Position = UDim2.new(0,4,0,0)
Accent.BackgroundColor3 = Color3.fromRGB(49, 157, 255)
Accent.BorderSizePixel = 0
local aCorner = Instance.new("UICorner", Accent); aCorner.CornerRadius = UDim.new(0,6)

local Title = Instance.new("TextLabel", Frame)
Title.Text = "FTF - David's ESP"
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(170,200,230)
Title.Size = UDim2.new(1, -32, 0, 36)
Title.Position = UDim2.new(0,28,0,8)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local Line = Instance.new("Frame", Frame)
Line.BackgroundColor3 = Color3.fromRGB(20,28,36)
Line.BorderSizePixel = 0
Line.Position = UDim2.new(0,0,0,48)
Line.Size = UDim2.new(1,0,0,2)

-- Futuristic button creator
local function createFuturisticButton(txt, ypos, c1, c2)
    local btnOuter = Instance.new("TextButton", Frame)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1
    btnOuter.BorderSizePixel = 0
    btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -36, 0, 50)
    btnOuter.Position = UDim2.new(0, 18, 0, ypos)
    btnOuter.Text = ""
    btnOuter.ClipsDescendants = true

    local bg = Instance.new("Frame", btnOuter)
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = c1
    bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0, 12)

    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(0.6, c2),
        ColorSequenceKeypoint.new(1, c1)
    }
    grad.Rotation = 45

    local inner = Instance.new("Frame", bg)
    inner.Name = "Inner"
    inner.Size = UDim2.new(1, -8, 1, -10)
    inner.Position = UDim2.new(0, 4, 0, 5)
    inner.BackgroundColor3 = Color3.fromRGB(12,14,18)
    inner.BorderSizePixel = 0
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0, 10)

    local innerStroke = Instance.new("UIStroke", inner)
    innerStroke.Color = Color3.fromRGB(28,36,46)
    innerStroke.Thickness = 1
    innerStroke.Transparency = 0.2

    local shine = Instance.new("Frame", inner)
    shine.Size = UDim2.new(1, 0, 0.28, 0)
    shine.Position = UDim2.new(0, 0, 0, 0)
    shine.BackgroundTransparency = 0.9
    shine.BackgroundColor3 = Color3.fromRGB(30,45,60)
    local shineCorner = Instance.new("UICorner", shine); shineCorner.CornerRadius = UDim.new(0, 10)

    local glow = Instance.new("Frame", bg)
    glow.Size = UDim2.new(1, 14, 1, 14)
    glow.Position = UDim2.new(-0.02, 0, -0.02, 0)
    glow.BackgroundColor3 = c2
    glow.BackgroundTransparency = 0.92
    local glowCorner = Instance.new("UICorner", glow); glowCorner.CornerRadius = UDim.new(0, 14)

    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, -4)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.Text = txt
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(170,195,215)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", inner)
    indicator.Size = UDim2.new(0, 50, 0, 26)
    indicator.Position = UDim2.new(1, -64, 0.5, -13)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14)
    indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,10)
    local indStroke = Instance.new("UIStroke", indicator); indStroke.Color = Color3.fromRGB(24,30,36); indStroke.Thickness = 1

    local indBar = Instance.new("Frame", indicator)
    indBar.Size = UDim2.new(0.38, 0, 0.5, 0)
    indBar.Position = UDim2.new(0.06, 0, 0.25, 0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    indBar.BorderSizePixel = 0
    local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0, 8)

    -- hover / click animations (omitted here for brevity; same as previous)

    return btnOuter, indBar
end

-- Create menu buttons
local PlayerBtn, PlayerIndicator = createFuturisticButton("Ativar ESP Jogadores", 70, Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101))
local CompBtn, CompIndicator   = createFuturisticButton("Ativar Destacar Computadores", 136, Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255))
local DownTimerBtn, DownIndicator = createFuturisticButton("Ativar Contador de Down", 202, Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90))
local GraySkinBtn, GraySkinIndicator = createFuturisticButton("Ativar Skin Cinza", 268, Color3.fromRGB(80,80,90), Color3.fromRGB(130,130,140))
local TextureBtn, TextureIndicator = createFuturisticButton("Ativar Texture Tijolos Brancos", 334, Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245))

-- Ensure Frame size
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)

-- (Other features: ESP, ComputerESP, Ragdoll, GraySkin)...
-- For brevity, assume rest of original implementations remain unchanged here.
-- ======= NEW/UPDATED: Toggleable White Brick Texture (SAFE) =======

-- Storage for original properties so we can restore
local TextureActive = false
local textureBackup = {}         -- [part] = {Color = Color3, Material = Enum.Material}
local textureDescendantConn = nil

-- Helper: detect if part belongs to a player's character (skip player parts)
local function isPartPlayerCharacter(part)
    if not part or not part:IsA("Instance") then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then
        local player = Players:GetPlayerFromCharacter(model)
        if player then return true end
    end
    return false
end

-- Save & apply (skip player characters). Runs quickly in batches to avoid freezing.
local function saveAndApplyWhiteBrick(part)
    if not part or not part:IsA("BasePart") then return end
    if isPartPlayerCharacter(part) then return end -- IMPORTANT: do not change player chars
    if textureBackup[part] then return end -- already saved/applied

    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    textureBackup[part] = {
        Color = (okC and col) or nil,
        Material = (okM and mat) or nil
    }
    pcall(function()
        part.Material = Enum.Material.Brick
        part.Color = Color3.fromRGB(255,255,255)
    end)
end

local function applyWhiteBrickToAll()
    local desc = Workspace:GetDescendants()
    -- process in chunks to avoid blocking
    local batch = 0
    for i = 1, #desc do
        local part = desc[i]
        if part and part:IsA("BasePart") then
            saveAndApplyWhiteBrick(part)
            batch = batch + 1
            if batch >= 200 then
                batch = 0
                RunService.Heartbeat:Wait() -- yield to keep game responsive
            end
        end
    end
end

local function onWorkspaceDescendantAdded(desc)
    if not TextureActive then return end
    if desc and desc:IsA("BasePart") then
        -- apply in next heartbeat to avoid race
        task.defer(function() saveAndApplyWhiteBrick(desc) end)
    end
end

local function restoreTextures()
    -- restore in batches
    local parts = {}
    for part, props in pairs(textureBackup) do
        parts[#parts+1] = {part=part, props=props}
    end
    local batch = 0
    for _, entry in ipairs(parts) do
        local part = entry.part
        local props = entry.props
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
        batch = batch + 1
        if batch >= 200 then
            batch = 0
            RunService.Heartbeat:Wait()
        end
    end
    textureBackup = {}
end

local function enableTextureToggle()
    if TextureActive then return end
    TextureActive = true
    -- visual indicator
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(245,245,245)
    TweenService:Create(TextureIndicator, TweenInfo.new(0.18), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
    -- apply in background
    task.spawn(applyWhiteBrickToAll)
    -- connect to new parts
    textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
    -- update visible label
    setButtonLabel(TextureBtn, "Desativar Texture Tijolos Brancos")
end

local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescendantConn then
        pcall(function() textureDescendantConn:Disconnect() end)
        textureDescendantConn = nil
    end
    -- restore in background
    task.spawn(restoreTextures)
    -- visual indicator reset
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
    TweenService:Create(TextureIndicator, TweenInfo.new(0.22), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
    setButtonLabel(TextureBtn, "Ativar Texture Tijolos Brancos")
end

-- Wire toggle to the UI button
TextureBtn.MouseButton1Click:Connect(function()
    if not TextureActive then
        enableTextureToggle()
    else
        disableTextureToggle()
    end
end)

-- Restore textures on player leaving or script unload
Players.PlayerRemoving:Connect(function(p)
    -- nothing specific here; textures are environment-only
end)

-- Safety cleanup function
local function cleanupAll()
    if TextureActive then
        disableTextureToggle()
    end
    -- restore other features if needed (gray skin)
end

-- End of file
