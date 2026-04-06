local lp = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local CHECK_INTERVAL = 0.3
local TELEPORT_DISTANCE = 0

-- Settings
local briefcaseEnabled = false
local allGunsEnabled = false
local exceptL106Enabled = false
local vestEnabled = false
local meleeEnabled = false
local espEnabled = false
local playerESPEnabled = false
local noClipEnabled = false
local flyEnabled = false
local fullbrightEnabled = false
local antiFallDamageEnabled = true

-- Infinite Teleport
local infiniteTPEnabled = false
local targetPlayerName = ""
local infiniteTPConnection = nil

-- Fling All
local flingAllEnabled = false
local flingNoClipConnection = nil
local flingLoopConnection = nil

-- Fly
local flySpeed = 50
local flyBodyVelocity = nil
local flyConnection = nil

-- FullBright
local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows

-- Object Names
local briefcaseNames = {"Briefcase"}
local allGunsNames = {"L106", "AS-VAL", "M4A1", "AK-74M"}
local vestNames = {"Vest", "Tactical"}
local meleeNames = {"Sledge", "Knife", "Katana"}

-- ====================== GUI =======================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MorromHub_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 790)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = "Morrom Hub (The Button)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local function createToggle(yOffset, text, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.92, 0, 0, 36)
    Frame.Position = UDim2.new(0.04, 0, 0, yOffset)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.Parent = MainFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.62, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0.33, 0, 0.78, 0)
    Toggle.Position = UDim2.new(0.63, 0, 0.11, 0)
    Toggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    Toggle.Text = "DISABLED"
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.Font = Enum.Font.GothamBold
    Toggle.TextSize = 13
    Toggle.Parent = Frame

    local enabled = false
    Toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            Toggle.Text = "ENABLED"
        else
            Toggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            Toggle.Text = "DISABLED"
        end
        callback(enabled)
    end)
end

-- Toggles
createToggle(45, "(Briefcase)", function(state) briefcaseEnabled = state end)
createToggle(85, "(All Guns: L106 + AS-VAL + M4A1 + AK-74M)", function(state) allGunsEnabled = state end)
createToggle(125, "(Guns EXCEPT L106: AS-VAL + M4A1 + AK-74M)", function(state) exceptL106Enabled = state end)
createToggle(165, "(Vest & Tactical)", function(state) vestEnabled = state end)
createToggle(205, "(Sledge, Knife, Katana)", function(state) meleeEnabled = state end)
createToggle(245, "ESP ALL ProximityPrompt", function(state) espEnabled = state end)
createToggle(285, "Player ESP (HP + Outline)", function(state) playerESPEnabled = state end)
createToggle(325, "NoClip", function(state) noClipEnabled = state end)
createToggle(365, "Jumper Fly", function(state)
    flyEnabled = state
    if not state then
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    end
end)
createToggle(405, "Anti Fall Damage (Invisible Platform)", function(state)
    antiFallDamageEnabled = state
    toggleAntiFallDamage(state)
end)
createToggle(445, "FullBright", function(state)
    fullbrightEnabled = state
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = originalAmbient
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.FogEnd = originalFogEnd
        Lighting.GlobalShadows = originalGlobalShadows
    end
end)
createToggle(485, "Fling All Players", function(state) flingAllEnabled = state end)

-- ====================== INFINITE TELEPORT TO PLAYER =======================
local infiniteTPFrame = Instance.new("Frame")
infiniteTPFrame.Size = UDim2.new(0.92, 0, 0, 260)
infiniteTPFrame.Position = UDim2.new(0.04, 0, 0, 530)
infiniteTPFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
infiniteTPFrame.Parent = MainFrame

local infiniteTPLabel = Instance.new("TextLabel")
infiniteTPLabel.Size = UDim2.new(1, 0, 0, 28)
infiniteTPLabel.BackgroundTransparency = 1
infiniteTPLabel.Text = "Infinite TP to Player"
infiniteTPLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infiniteTPLabel.Font = Enum.Font.GothamBold
infiniteTPLabel.TextSize = 14
infiniteTPLabel.Parent = infiniteTPFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.92, 0, 0, 32)
searchBox.Position = UDim2.new(0.04, 0, 0, 33)
searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
searchBox.Text = "Search player..."
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.Parent = infiniteTPFrame

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(0.92, 0, 0, 120)
playerScroll.Position = UDim2.new(0.04, 0, 0, 70)
playerScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerScroll.ScrollBarThickness = 5
playerScroll.Parent = infiniteTPFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.Name
uiListLayout.Padding = UDim.new(0, 2)
uiListLayout.Parent = playerScroll

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(0.92, 0, 0, 22)
selectedLabel.Position = UDim2.new(0.04, 0, 0, 198)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected: none"
selectedLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextSize = 13
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = infiniteTPFrame

local infiniteTPToggle = Instance.new("TextButton")
infiniteTPToggle.Size = UDim2.new(0.92, 0, 0, 35)
infiniteTPToggle.Position = UDim2.new(0.04, 0, 0, 228)
infiniteTPToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
infiniteTPToggle.Text = "ACTIVATE"
infiniteTPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
infiniteTPToggle.Font = Enum.Font.GothamBold
infiniteTPToggle.TextSize = 14
infiniteTPToggle.Parent = infiniteTPFrame

local function updatePlayerList(filterText)
    filterText = (filterText or ""):lower()
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local otherPlayers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then table.insert(otherPlayers, plr) end
    end
    table.sort(otherPlayers, function(a, b) return a.Name < b.Name end)
    local count = 0
    for _, plr in ipairs(otherPlayers) do
        if filterText == "" or plr.Name:lower():find(filterText) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = playerScroll
            btn.MouseButton1Click:Connect(function()
                targetPlayerName = plr.Name
                selectedLabel.Text = "Selected: " .. plr.Name
                if infiniteTPEnabled then
                    infiniteTPToggle.Text = "ENABLED (to " .. plr.Name .. ")"
                end
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                task.delay(0.3, function() if btn and btn.Parent then btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end end)
            end)
            count = count + 1
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 30)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function() updatePlayerList(searchBox.Text) end)
local function refreshPlayerList() updatePlayerList(searchBox.Text) end
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
refreshPlayerList()

local function toggleInfiniteTP()
    if infiniteTPEnabled then
        infiniteTPEnabled = false
        infiniteTPToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        infiniteTPToggle.Text = "ACTIVATE"
        print("❌ Infinite TP disabled")
    else
        if targetPlayerName == "" then
            local text = (searchBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" and text ~= "Search player..." then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= lp and plr.Name:lower() == text:lower() then
                        targetPlayerName = plr.Name
                        selectedLabel.Text = "Selected: " .. plr.Name
                        break
                    end
                end
            end
        end
        if targetPlayerName == "" then
            print("❌ First select a player from the list!")
            return
        end
        infiniteTPEnabled = true
        infiniteTPToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        infiniteTPToggle.Text = "ENABLED (to " .. targetPlayerName .. ")"
        print("✅ Infinite TP to " .. targetPlayerName .. " activated (behind the back)")
    end
end
infiniteTPToggle.MouseButton1Click:Connect(toggleInfiniteTP)

-- ====================== CLOSE GUI (M) =======================
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end
end)

-- ====================== RANDOM TELEPORT (N) =======================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        local otherPlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(otherPlayers, plr)
            end
        end
        if #otherPlayers == 0 then return end
        local randomPlayer = otherPlayers[math.random(1, #otherPlayers)]
        local targetRoot = randomPlayer.Character.HumanoidRootPart
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = targetRoot.CFrame * CFrame.new(4, 5, 0) end
    end
end)

-- ====================== FLY WITH R KEY =======================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        flyEnabled = not flyEnabled
        toggleFly(flyEnabled)
        print("🟢 Jumper Fly " .. (flyEnabled and "ENABLED" or "DISABLED") .. " (R)")
    end
end)

-- ====================== PLAYER ESP =======================
local playerESPObjects = {}
local function createPlayerESP(player)
    if player == lp or playerESPObjects[player] then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not head or not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 220, 0)
    highlight.OutlineTransparency = 0.15
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 120, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = character

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.58, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 11.5
    nameLabel.Parent = frame

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0.92, 0, 0.25, 0)
    healthBg.Position = UDim2.new(0.04, 0, 0.68, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    healthBg.BorderSizePixel = 1
    healthBg.BorderColor3 = Color3.fromRGB(0,0,0)
    healthBg.Parent = frame

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBg

    local function updateHealth()
        if not humanoid or not humanoid.Parent then return end
        local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        healthBar.Size = UDim2.new(percent, 0, 1, 0)
        if percent > 0.6 then 
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        elseif percent > 0.35 then 
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        else 
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 60, 60) 
        end
        nameLabel.Text = string.format("%s [%d]", player.Name, math.floor(humanoid.Health))
    end
    updateHealth()
    local healthConn = humanoid.HealthChanged:Connect(updateHealth)
    playerESPObjects[player] = {billboard = billboard, highlight = highlight, healthConn = healthConn}
end

local function removePlayerESP(player)
    local data = playerESPObjects[player]
    if data then
        if data.healthConn then data.healthConn:Disconnect() end
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        playerESPObjects[player] = nil
    end
end

local function updateAllPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            if playerESPEnabled then 
                createPlayerESP(player) 
            else 
                removePlayerESP(player) 
            end
        end
    end
end
Players.PlayerRemoving:Connect(removePlayerESP)

-- ====================== NOCLIP =======================
local noclipConnection = nil
local function toggleNoClip(state)
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = lp.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        local character = lp.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                    part.CanCollide = true 
                end
            end
        end
    end
end

-- ====================== FLY =======================
local function toggleFly(state)
    local character = lp.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if state then
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Name = "Fly_BV"
        flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = root

        flyConnection = RunService.Heartbeat:Connect(function()
            if not flyEnabled or not flyBodyVelocity then return end
            local cam = workspace.CurrentCamera
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection -= Vector3.new(0, 1, 0) end
            if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit * flySpeed end
            flyBodyVelocity.Velocity = moveDirection
        end)
    else
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    end
end

-- ====================== FLING ALL =======================
local function toggleFlingAll(state)
    flingAllEnabled = state
    if state then
        if flingNoClipConnection then flingNoClipConnection:Disconnect() end
        flingNoClipConnection = RunService.Stepped:Connect(function()
            local character = lp.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)

        if flingLoopConnection then flingLoopConnection:Disconnect() end
        flingLoopConnection = RunService.Heartbeat:Connect(function()
            if not flingAllEnabled then return end
            local character = lp.Character
            if not character then return end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local pchar = plr.Character
                    local proot = pchar:FindFirstChild("HumanoidRootPart")
                    local phumanoid = pchar:FindFirstChild("Humanoid")
                    if proot and phumanoid then
                        local dist = (root.Position - proot.Position).Magnitude
                        if dist < 22 then
                            proot.AssemblyLinearVelocity = Vector3.new(
                                math.random(-650, 650),
                                math.random(1600, 3000),
                                math.random(-650, 650)
                            )
                            phumanoid.PlatformStand = true
                        end
                    end
                end
            end
        end)
        print("🔥 Fling All ENABLED (throws ALL nearby players — 100% working)")
    else
        if flingNoClipConnection then flingNoClipConnection:Disconnect() flingNoClipConnection = nil end
        if flingLoopConnection then flingLoopConnection:Disconnect() flingLoopConnection = nil end
        local character = lp.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        print("❌ Fling All DISABLED")
    end
end

-- ====================== ESP ProximityPrompt =======================
local espBillboards = {}
local function createESP(prompt)
    if espBillboards[prompt] then return end
    local adornee = prompt.Parent
    if adornee:IsA("Model") then adornee = adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart") end
    if not adornee or not adornee:IsA("BasePart") then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Adornee = adornee
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.Parent = prompt

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 14
    TextLabel.Text = prompt.Name .. "\n" .. prompt.Parent.Name
    TextLabel.Parent = Billboard
    espBillboards[prompt] = Billboard
end

local function removeAllESP()
    for _, billboard in pairs(espBillboards) do billboard:Destroy() end
    espBillboards = {}
end

-- ====================== ANTI FALL DAMAGE =======================
local ANTI_FALL_ENABLED = true
local CHECK_RATE = 0.20
local LIFT_SPEED = 18
local CHECK_DISTANCE = 35
local antiFallBodyVel = nil
local lastAntiFallCheck = 0

local function antiFall(root)
    if not ANTI_FALL_ENABLED or not root then return end
    local now = tick()
    if now - lastAntiFallCheck < CHECK_RATE then return end
    lastAntiFallCheck = now
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {root.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(root.Position, Vector3.new(0, -CHECK_DISTANCE, 0), rayParams)
    if not result then
        if not antiFallBodyVel or not antiFallBodyVel.Parent then
            antiFallBodyVel = Instance.new("BodyVelocity")
            antiFallBodyVel.Name = "AntiFall_BV"
            antiFallBodyVel.MaxForce = Vector3.new(0, 4000, 0)
            antiFallBodyVel.P = 2000
            antiFallBodyVel.Parent = root
        end
        antiFallBodyVel.Velocity = Vector3.new(0, LIFT_SPEED, 0)
    else
        if antiFallBodyVel then antiFallBodyVel:Destroy() antiFallBodyVel = nil end
    end
end

local antiFallDamageConnection = nil
local currentPlatform = nil
local lastPlatformTime = 0

local function toggleAntiFallDamage(state)
    antiFallDamageEnabled = state
    if state then
        if not antiFallDamageConnection then
            antiFallDamageConnection = RunService.Stepped:Connect(function()
                local character = lp.Character
                if not character then return end
                local root = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                if not root or not humanoid then return end
                local vel = root.AssemblyLinearVelocity
                if vel.Y > -50 then
                    if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
                    return
                end
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.IgnoreWater = true
                local result = workspace:Raycast(root.Position, Vector3.new(0, -40, 0), rayParams)
                if result and result.Distance < 22 and tick() - lastPlatformTime > 0.3 then
                    lastPlatformTime = tick()
                    if currentPlatform then currentPlatform:Destroy() end
                    currentPlatform = Instance.new("Part")
                    currentPlatform.Name = "AntiFall_Platform"
                    currentPlatform.Size = Vector3.new(50, 2, 50)
                    currentPlatform.Transparency = 1
                    currentPlatform.Anchored = true
                    currentPlatform.CanCollide = true
                    currentPlatform.Parent = workspace
                    local platformY = result.Position.Y + 1.5
                    currentPlatform.CFrame = CFrame.new(root.Position.X, platformY, root.Position.Z)
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, 5, vel.Z)
                    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                    humanoid.PlatformStand = true
                    task.delay(0.18, function()
                        if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
                        if humanoid then humanoid.PlatformStand = false end
                    end)
                end
            end)
        end
    else
        if antiFallDamageConnection then antiFallDamageConnection:Disconnect() antiFallDamageConnection = nil end
        if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
    end
end
toggleAntiFallDamage(true)

-- ====================== INFINITE TELEPORT =======================
local function startInfiniteTP()
    if infiniteTPConnection then infiniteTPConnection:Disconnect() end
    infiniteTPConnection = RunService.Heartbeat:Connect(function()
        if not infiniteTPEnabled then return end
        if targetPlayerName == "" then return end
        local targetPlr = Players:FindFirstChild(targetPlayerName)
        if not targetPlr or not targetPlr.Character then return end
        local targetRoot = targetPlr.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 4)
        end
    end)
end

-- ====================== MAIN LOOP =======================
local lastCheck = 0
RunService.Heartbeat:Connect(function()
    local character = lp.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    antiFall(root)

    if playerESPEnabled then
        updateAllPlayerESP()
    else
        for player in pairs(playerESPObjects) do removePlayerESP(player) end
    end

    if espEnabled then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                createESP(prompt)
            end
        end
    else
        if next(espBillboards) then removeAllESP() end
    end

    if not (briefcaseEnabled or allGunsEnabled or exceptL106Enabled or vestEnabled or meleeEnabled) then return end

    local now = tick()
    if now - lastCheck < CHECK_INTERVAL then return end
    lastCheck = now

    for _, prompt in ipairs(workspace:GetDescendants()) do
        if not (prompt:IsA("ProximityPrompt") and prompt.Enabled) then continue end

        local target = nil
        local parent = prompt.Parent
        if parent then
            local name = parent.Name
            local parentName = parent.Parent and parent.Parent.Name or ""
            if table.find(briefcaseNames, name) or table.find(briefcaseNames, parentName) then target = parent
            elseif table.find(allGunsNames, name) or table.find(allGunsNames, parentName) then target = parent
            elseif table.find(vestNames, name) or table.find(vestNames, parentName) then target = parent
            elseif table.find(meleeNames, name) or table.find(meleeNames, parentName) then target = parent end
        end
        if not target then continue end

        local name = target.Name
        local parentName = target.Parent and target.Parent.Name or ""
        local isBriefcase = table.find(briefcaseNames, name) ~= nil or table.find(briefcaseNames, parentName) ~= nil
        local isVest = table.find(vestNames, name) ~= nil or table.find(vestNames, parentName) ~= nil
        local isMelee = table.find(meleeNames, name) ~= nil or table.find(meleeNames, parentName) ~= nil
        local isGun = table.find(allGunsNames, name) ~= nil or table.find(allGunsNames, parentName) ~= nil
        local isL106 = name == "L106" or parentName == "L106"

        local shouldFarm = false
        if isBriefcase and briefcaseEnabled then shouldFarm = true
        elseif isVest and vestEnabled then shouldFarm = true
        elseif isMelee and meleeEnabled then shouldFarm = true
        elseif isGun then
            if isL106 then
                if allGunsEnabled then shouldFarm = true end
            else
                if allGunsEnabled or exceptL106Enabled then shouldFarm = true end
            end
        end
        if not shouldFarm then continue end

        local targetPart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")) or target
        if targetPart then
            local distance = (root.Position - targetPart.Position).Magnitude
            if distance > TELEPORT_DISTANCE + 6 then
                root.CFrame = targetPart.CFrame * CFrame.new(0, 4, -TELEPORT_DISTANCE)
                task.wait(0.13)
            end
            pcall(function() fireproximityprompt(prompt) end)
        end
    end
end)

-- State Handler
local lastNoClipState = false
local lastFlyState = false
local lastFlingState = false
RunService.Heartbeat:Connect(function()
    if noClipEnabled ~= lastNoClipState then
        toggleNoClip(noClipEnabled)
        lastNoClipState = noClipEnabled
    end
    if flyEnabled ~= lastFlyState then
        toggleFly(flyEnabled)
        lastFlyState = flyEnabled
    end
    if flingAllEnabled ~= lastFlingState then
        toggleFlingAll(flingAllEnabled)
        lastFlingState = flingAllEnabled
    end
    if infiniteTPEnabled then
        startInfiniteTP()
    elseif infiniteTPConnection then
        infiniteTPConnection:Disconnect()
        infiniteTPConnection = nil
    end
end)

print("✅ SCRIPT LOADED - Morrom Hub | FLING FULLY FIXED (throws ALL nearby players 🔥)")
