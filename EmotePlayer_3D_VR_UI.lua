--// Emote Player - 3D First Person / VR-style UI
--// Based on the uploaded Emote Player script.
--// The menu is rendered in 3D space in front of the camera and smoothly follows camera direction.

local function missing(t, f, fallback)
    if type(f) == t then
        return f
    end
    return fallback
end

cloneref = missing("function", cloneref, function(...)
    return ...
end)

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
end)

--// Settings
local Settings = {
    ["Stop On Move"] = true,
    ["Fade In"] = 0.1,
    ["Fade Out"] = 0.1,
    ["Weight"] = 1,
    ["Speed"] = 1,
    ["Allow Invisible"] = true,
    ["Time Position"] = 0,

    --// 3D UI settings
    ["Follow Camera"] = true,
    ["UI Distance"] = 5,
    ["UI Height"] = 0.15,
    ["UI Smoothness"] = 0.18,
}

local CurrentTrack
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.zero

--// Extract animation ID from ID / Roblox URL
local function extractIdFromInput(input)
    local num = tonumber(input)
    if num then
        return num
    end

    local assetIdMatch = string.match(input, "rbxassetid://(%d+)")
    if assetIdMatch then
        return tonumber(assetIdMatch)
    end

    local catalogMatch = string.match(input, "roblox%.com/catalog/(%d+)")
    if catalogMatch then
        return tonumber(catalogMatch)
    end

    local libraryMatch = string.match(input, "roblox%.com/library/(%d+)")
    if libraryMatch then
        return tonumber(libraryMatch)
    end

    local assetMatch = string.match(input, "roblox%.com/asset/%?id=(%d+)")
    if assetMatch then
        return tonumber(assetMatch)
    end

    return tonumber(input)
end

local function LoadTrack(id)
    if CurrentTrack then
        pcall(function()
            CurrentTrack:Stop(0)
        end)
        CurrentTrack = nil
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        local anim = result[1]

        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId

    local newTrack
    local loadOk, loadResult = pcall(function()
        return humanoid:LoadAnimation(newAnim)
    end)

    if not loadOk or not loadResult then
        warn("Unable to load animation:", id)
        newAnim:Destroy()
        return nil
    end

    newTrack = loadResult
    newTrack.Priority = Enum.AnimationPriority.Action4

    local weight = Settings["Weight"]
    if weight == 0 then
        weight = 0.001
    end

    newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])

    CurrentTrack = newTrack

    task.defer(function()
        if CurrentTrack == newTrack and CurrentTrack.Length > 0 then
            CurrentTrack.TimePosition =
                math.clamp(Settings["Time Position"], 0, 1) * CurrentTrack.Length
        end
    end)

    return newTrack
end

local function StopTrack()
    if CurrentTrack then
        pcall(function()
            CurrentTrack:Stop(Settings["Fade Out"])
        end)
        CurrentTrack = nil
    end
end

--// =========================================================
--// 3D WORLD UI
--// =========================================================

local oldPart = workspace:FindFirstChild("__EmotePlayer3DUI")
if oldPart then
    oldPart:Destroy()
end

local uiPart = Instance.new("Part")
uiPart.Name = "__EmotePlayer3DUI"
uiPart.Size = Vector3.new(5.6, 3.7, 0.08)
uiPart.Anchored = true
uiPart.CanCollide = false
uiPart.CanTouch = false
uiPart.CanQuery = false
uiPart.Transparency = 1
uiPart.CastShadow = false
uiPart.Parent = workspace

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Name = "EmotePlayer3D"
surfaceGui.Adornee = uiPart
surfaceGui.Face = Enum.NormalId.Front
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surfaceGui.PixelsPerStud = 90
surfaceGui.LightInfluence = 0
surfaceGui.AlwaysOnTop = true
surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
surfaceGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Parent = surfaceGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 22)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Transparency = 0.25
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 38)
title.Position = UDim2.new(0, 15, 0, 10)
title.BackgroundTransparency = 1
title.Text = "EMOTE PLAYER  •  3D"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -30, 0, 22)
subtitle.Position = UDim2.new(0, 15, 0, 43)
subtitle.BackgroundTransparency = 1
subtitle.Text = "FIRST PERSON / VR STYLE"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(180, 185, 195)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = mainFrame

local emoteBox = Instance.new("TextBox")
emoteBox.Size = UDim2.new(1, -30, 0, 42)
emoteBox.Position = UDim2.new(0, 15, 0, 72)
emoteBox.BackgroundColor3 = Color3.fromRGB(38, 42, 52)
emoteBox.BackgroundTransparency = 0.05
emoteBox.Text = ""
emoteBox.PlaceholderText = "Emote ID or Roblox URL..."
emoteBox.TextColor3 = Color3.new(1, 1, 1)
emoteBox.PlaceholderColor3 = Color3.fromRGB(145, 150, 160)
emoteBox.Font = Enum.Font.Gotham
emoteBox.TextSize = 14
emoteBox.ClearTextOnFocus = false
emoteBox.TextXAlignment = Enum.TextXAlignment.Left
emoteBox.Parent = mainFrame

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 12)
inputPadding.PaddingRight = UDim.new(0, 12)
inputPadding.Parent = emoteBox

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 10)
inputCorner.Parent = emoteBox

local playButton = Instance.new("TextButton")
playButton.Size = UDim2.new(0.48, -5, 0, 40)
playButton.Position = UDim2.new(0, 15, 0, 124)
playButton.BackgroundColor3 = Color3.fromRGB(0, 150, 230)
playButton.Text = "▶  PLAY"
playButton.TextColor3 = Color3.new(1, 1, 1)
playButton.Font = Enum.Font.GothamBold
playButton.TextSize = 14
playButton.AutoButtonColor = true
playButton.Parent = mainFrame

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 10)
playCorner.Parent = playButton

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.48, -5, 0, 40)
stopButton.Position = UDim2.new(0.52, 0, 0, 124)
stopButton.BackgroundColor3 = Color3.fromRGB(205, 65, 75)
stopButton.Text = "■  STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 14
stopButton.AutoButtonColor = true
stopButton.Parent = mainFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 10)
stopCorner.Parent = stopButton

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 24)
status.Position = UDim2.new(0, 15, 0, 173)
status.BackgroundTransparency = 1
status.Text = "READY"
status.Font = Enum.Font.GothamMedium
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(170, 175, 185)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = mainFrame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -30, 0, 20)
hint.Position = UDim2.new(0, 15, 1, -28)
hint.BackgroundTransparency = 1
hint.Text = "Turn your camera • UI follows smoothly"
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextColor3 = Color3.fromRGB(130, 135, 145)
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = mainFrame

--// 3D UI controls
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 105, 0, 26)
toggleButton.Position = UDim2.new(1, -120, 0, 13)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
toggleButton.Text = "FOLLOW: ON"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 10
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local function setStatus(text)
    status.Text = text
end

playButton.MouseButton1Click:Connect(function()
    local input = emoteBox.Text

    if not input or input == "" then
        setStatus("ENTER AN EMOTE ID")
        return
    end

    local id = extractIdFromInput(input)

    if id then
        local track = LoadTrack(id)

        if track then
            setStatus("PLAYING  •  ID " .. tostring(id))
        else
            setStatus("FAILED TO LOAD")
        end
    else
        setStatus("INVALID EMOTE ID / URL")
    end
end)

stopButton.MouseButton1Click:Connect(function()
    StopTrack()
    setStatus("STOPPED")
end)

toggleButton.MouseButton1Click:Connect(function()
    Settings["Follow Camera"] = not Settings["Follow Camera"]

    if Settings["Follow Camera"] then
        toggleButton.Text = "FOLLOW: ON"
        setStatus("CAMERA FOLLOW ON")
    else
        toggleButton.Text = "FOLLOW: OFF"
        setStatus("CAMERA FOLLOW OFF")
    end
end)

--// First-person camera setup
pcall(function()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
end)

--// Smooth 3D UI movement
local currentCFrame = nil

RunService.RenderStepped:Connect(function()
    camera = workspace.CurrentCamera

    if not camera or not uiPart or not uiPart.Parent then
        return
    end

    local targetCFrame =
        camera.CFrame
        * CFrame.new(0, Settings["UI Height"], -Settings["UI Distance"])

    if not currentCFrame then
        currentCFrame = targetCFrame
    end

    local smooth = math.clamp(Settings["UI Smoothness"], 0.01, 1)

    if Settings["Follow Camera"] then
        currentCFrame = currentCFrame:Lerp(targetCFrame, smooth)
        uiPart.CFrame = currentCFrame
    else
        if currentCFrame then
            uiPart.CFrame = currentCFrame
        end
    end
end)

--// Stop emote when player moves / jumps
RunService.RenderStepped:Connect(function()
    if character and character.PrimaryPart then
        if Settings["Stop On Move"] and CurrentTrack and CurrentTrack.IsPlaying then
            local moved =
                (character.PrimaryPart.Position - lastPosition).Magnitude > 0.1

            local jumped =
                humanoid
                and humanoid:GetState() == Enum.HumanoidStateType.Jumping

            if moved or jumped then
                StopTrack()
                setStatus("STOPPED ON MOVE")
            end
        end

        lastPosition = character.PrimaryPart.Position
    end
end)

--// =========================================================
--// Settings panel: compact 3D controls
--// =========================================================

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(1, -30, 0, 82)
settingsPanel.Position = UDim2.new(0, 15, 0, 205)
settingsPanel.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
settingsPanel.BackgroundTransparency = 0.08
settingsPanel.Parent = mainFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 12)
settingsCorner.Parent = settingsPanel

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.48, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 12, 0, 8)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: " .. string.format("%.2f", Settings["Speed"])
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = settingsPanel

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.38, 0, 0, 24)
speedBox.Position = UDim2.new(0.58, 0, 0, 5)
speedBox.BackgroundColor3 = Color3.fromRGB(48, 53, 64)
speedBox.Text = tostring(Settings["Speed"])
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 11
speedBox.ClearTextOnFocus = false
speedBox.Parent = settingsPanel

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 7)
speedCorner.Parent = speedBox

local distanceLabel = Instance.new("TextLabel")
distanceLabel.Size = UDim2.new(0.48, 0, 0, 20)
distanceLabel.Position = UDim2.new(0, 12, 0, 42)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = "3D Distance: " .. string.format("%.1f", Settings["UI Distance"])
distanceLabel.TextColor3 = Color3.new(1, 1, 1)
distanceLabel.Font = Enum.Font.Gotham
distanceLabel.TextSize = 11
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceLabel.Parent = settingsPanel

local distanceBox = Instance.new("TextBox")
distanceBox.Size = UDim2.new(0.38, 0, 0, 24)
distanceBox.Position = UDim2.new(0.58, 0, 0, 39)
distanceBox.BackgroundColor3 = Color3.fromRGB(48, 53, 64)
distanceBox.Text = tostring(Settings["UI Distance"])
distanceBox.TextColor3 = Color3.new(1, 1, 1)
distanceBox.Font = Enum.Font.Gotham
distanceBox.TextSize = 11
distanceBox.ClearTextOnFocus = false
distanceBox.Parent = settingsPanel

local distanceCorner = Instance.new("UICorner")
distanceCorner.CornerRadius = UDim.new(0, 7)
distanceCorner.Parent = distanceBox

speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(speedBox.Text)

        if value then
            Settings["Speed"] = value

            if CurrentTrack and CurrentTrack.IsPlaying then
                CurrentTrack:AdjustSpeed(value)
            end

            speedLabel.Text = "Speed: " .. string.format("%.2f", value)
        else
            speedBox.Text = tostring(Settings["Speed"])
        end
    end
end)

distanceBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(distanceBox.Text)

        if value then
            Settings["UI Distance"] = math.clamp(value, 2, 15)
            distanceBox.Text = tostring(Settings["UI Distance"])
            distanceLabel.Text =
                "3D Distance: " .. string.format("%.1f", Settings["UI Distance"])
        else
            distanceBox.Text = tostring(Settings["UI Distance"])
        end
    end
end)

--// Optional invisible-body collision behavior retained from original script
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local originalCollisionStates = {}
local lastAllowInvisible = Settings["Allow Invisible"]

local function saveCollisionStates()
    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= humanoidRootPart then
            originalCollisionStates[part] = part.CanCollide
        end
    end
end

local function disableCollisionsExceptRootPart()
    if not Settings["Allow Invisible"] or not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part ~= humanoidRootPart then
            part.CanCollide = false
        end
    end
end

local function restoreCollisionStates()
    for part, canCollide in pairs(originalCollisionStates) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end

    originalCollisionStates = {}
end

saveCollisionStates()

RunService.Stepped:Connect(function()
    if not character or not character.Parent then
        return
    end

    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    local currentValue = Settings["Allow Invisible"]

    if currentValue ~= lastAllowInvisible then
        if currentValue then
            saveCollisionStates()
            disableCollisionsExceptRootPart()
        else
            restoreCollisionStates()
        end

        lastAllowInvisible = currentValue
    elseif currentValue then
        disableCollisionsExceptRootPart()
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    restoreCollisionStates()

    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

    lastPosition = humanoidRootPart.Position

    saveCollisionStates()
    lastAllowInvisible = Settings["Allow Invisible"]
end)

--// Cleanup helper if the player leaves
player.AncestryChanged:Connect(function(_, parent)
    if parent == nil then
        pcall(function()
            StopTrack()
        end)

        if uiPart then
            uiPart:Destroy()
        end
    end
end)
