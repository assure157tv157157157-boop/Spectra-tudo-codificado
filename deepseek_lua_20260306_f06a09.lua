--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
end)

--// UI LIB
local Library = loadstring(game:HttpGet("https://pastefy.app/MaVJLHB7/raw"))()

local Window = Library:MakeWindow({
    Title = "Spectra Props • Remastered",
    SubTitle = "by: assure_TV + upgrades",
    LoadText = "Carregando Spectra Ultimate",
    Flags = "Spectrahub_Brookhaven_Ultimate",
    Size = UDim2.new(0, 500, 0, 500) -- maior para caber os sliders
})

Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://123419106595949", BackgroundTransparency = 0 },
    Corner = { CornerRadius = UDim.new(35, 1) }
})

--////////////////////////////////////////////////////
--// UTILITÁRIOS
--////////////////////////////////////////////////////

local function GetMyProps()
    local props = {}
    local workspaceCom = workspace:FindFirstChild("WorkspaceCom")
    if not workspaceCom then return props end
    for _, obj in ipairs(workspaceCom:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(plr.Name) and obj:FindFirstChild("SetCurrentCFrame") then
            table.insert(props, obj)
        end
    end
    return props
end

local function GetHRP()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    return character and character:FindFirstChildOfClass("Humanoid")
end

--////////////////////////////////////////////////////
--// TABS
--////////////////////////////////////////////////////
local TrollTab = Window:MakeTab({
    Title = "Props",
    Icon = "rbxassetid://105645877854135"
})

--////////////////////////////////////////////////////
--// PLAYER SELECTOR (melhorado)
--////////////////////////////////////////////////////
local selectedPlayer = nil

local function updatePlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then table.insert(list, p.Name) end
    end
    return list
end

local playerDropdown = TrollTab:AddDropdown({
    Name = "👤 Escolher Player",
    Options = updatePlayerList(),
    Callback = function(v) selectedPlayer = v end
})

TrollTab:AddButton({
    Name = "🔄 Atualizar Lista",
    Callback = function() playerDropdown:Set(updatePlayerList()) end
})

--////////////////////////////////////////////////////
--// SPECTATE (melhorado)
--////////////////////////////////////////////////////
local spectating = false
local spectateConn, charConn, currentTarget

local function resetCamera()
    if spectateConn then spectateConn:Disconnect() spectateConn = nil end
    if charConn then charConn:Disconnect() charConn = nil end
    currentTarget = nil
    local hum = GetHum()
    if hum then
        workspace.CurrentCamera.CameraSubject = hum
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end

local function spectatePlayer(player)
    if not spectating or not player then return end
    resetCamera()
    currentTarget = player
    spectateConn = RunService.RenderStepped:Connect(function()
        if not spectating or not currentTarget or not currentTarget.Character then return end
        local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    end)
    charConn = player.CharacterAdded:Connect(function()
        task.wait(0.1)
        if spectating and currentTarget == player then spectatePlayer(player) end
    end)
end

Players.PlayerRemoving:Connect(function(p)
    if spectating and currentTarget == p then resetCamera() spectating = false end
end)

TrollTab:AddToggle({
    Name = "👁️ Spectar Jogador",
    Default = false,
    Callback = function(state)
        spectating = state
        if not state then resetCamera() return end
        local target = Players:FindFirstChild(selectedPlayer)
        if target then spectatePlayer(target) else resetCamera() end
    end
})

--////////////////////////////////////////////////////
--// AUTO RGB PROPS (melhorado com Heartbeat suave)
--////////////////////////////////////////////////////
local rgbAtivo = false
local rgbConnection = nil
local propsRGB = {}

TrollTab:AddToggle({
    Name = "🌈 Auto RGB Props",
    Default = false,
    Callback = function(state)
        rgbAtivo = state
        if rgbAtivo then
            propsRGB = GetMyProps()
            rgbConnection = RunService.Heartbeat:Connect(function()
                local hue = (tick() * 0.3) % 1
                local color = Color3.fromHSV(hue, 1, 1)
                for _, prop in ipairs(propsRGB) do
                    if prop and prop.Parent then
                        pcall(function() prop.ChangePropColor:InvokeServer(color) end)
                    end
                end
                -- atualiza lista de props periodicamente
                propsRGB = GetMyProps()
            end)
        else
            if rgbConnection then rgbConnection:Disconnect() rgbConnection = nil end
        end
    end
})

--////////////////////////////////////////////////////
--// ANTI-SIT (melhorado)
--////////////////////////////////////////////////////
local antiSitEnabled = false
local antiSitConn

TrollTab:AddToggle({
    Name = "🪑 Anti-Sit",
    Default = false,
    Callback = function(state)
        antiSitEnabled = state
        local function apply(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            hum.Sit = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if antiSitConn then antiSitConn:Disconnect() end
            antiSitConn = hum.Seated:Connect(function(sit)
                if sit then hum.Sit = false hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end
        if state then
            if character then apply(character) end
            plr.CharacterAdded:Connect(function(char)
                if antiSitEnabled then apply(char) end
            end)
        else
            if antiSitConn then antiSitConn:Disconnect() antiSitConn = nil end
            if character then
                local hum = GetHum()
                if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
            end
        end
    end
})

--////////////////////////////////////////////////////
--// SISTEMA DE MODOS (para não conflitarem)
--////////////////////////////////////////////////////
local activeMode = nil -- nome do modo ativo atualmente

local function stopAllModes()
    if activeMode then
        local stopFunc = _G["Stop" .. activeMode]
        if stopFunc then stopFunc() end
        activeMode = nil
    end
end

local function startMode(modeName, startFunc)
    if activeMode == modeName then
        -- se já está ativo, desliga
        stopAllModes()
    else
        stopAllModes()
        startFunc()
        activeMode = modeName
    end
end

--////////////////////////////////////////////////////
--// CONFIGURAÇÕES GLOBAIS PARA PROPS
--////////////////////////////////////////////////////
local config = {
    Speed = 5,
    Radius = 8,
    Height = 3,
    Chaos = 20,
    Smoothness = 0.3
}

TrollTab:AddSection({"⚙️ Configurações Globais"})
TrollTab:AddSlider({
    Name = "Velocidade",
    Min = 1, Max = 20, Default = 5,
    Callback = function(v) config.Speed = v end
})
TrollTab:AddSlider({
    Name = "Suavidade (Lerp)",
    Min = 0.1, Max = 0.9, Default = 0.3,
    Callback = function(v) config.Smoothness = v end
})

--////////////////////////////////////////////////////
--// PROPS EM MIM (Categoria)
--////////////////////////////////////////////////////
TrollTab:AddSection({"🌀 Props em Mim"})

-- COBRA (melhorada)
local cobraConn = nil
local function StartCobra()
    local t = 0
    cobraConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed
        for i, prop in ipairs(props) do
            local phase = t - i * 1.1
            local backDir = -root.CFrame.LookVector
            local rightDir = root.CFrame.RightVector
            local upDir = Vector3.new(0,1,0)
            local backOffset = backDir * (3.5 * i)
            local sideOffset = rightDir * (math.sin(phase) * 3.2)
            local upOffset = upDir * (math.cos(phase * 0.8) * 1.2)
            local pos = root.Position + backOffset + sideOffset + upOffset
            local cf = CFrame.lookAt(pos, pos + backDir)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopCobra() if cobraConn then cobraConn:Disconnect() cobraConn = nil end end

TrollTab:AddToggle({
    Name = "🐍 Cobra",
    Default = false,
    Callback = function(v) if v then startMode("Cobra", StartCobra) else StopCobra() activeMode = nil end end
})

-- FURACÃO (melhorado)
local furacaoConn = nil
local function StartFuracao()
    local t = 0
    furacaoConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed * 0.8
        for i, prop in ipairs(props) do
            local angle = t + i * 0.7
            local radius = 4 + math.sin(t + i) * 3
            local height = math.cos(t*2 + i) * 4
            local offset = Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            local pos = root.Position + offset
            local cf = CFrame.lookAt(pos, root.Position)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopFuracao() if furacaoConn then furacaoConn:Disconnect() furacaoConn = nil end end

TrollTab:AddToggle({
    Name = "🌪️ Furacão",
    Default = false,
    Callback = function(v) if v then startMode("Furacao", StartFuracao) else StopFuracao() activeMode = nil end end
})

-- CÍRCULO NA CINTURA (maior e mais suave)
local circuloConn = nil
local function StartCirculo()
    local t = 0
    circuloConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed * 0.5
        local radius = 15
        local height = -0.5
        for i, prop in ipairs(props) do
            local angle = ((i-1)/#props) * 2*math.pi + t
            local offset = Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            local pos = root.Position + offset
            local cf = CFrame.new(pos) * CFrame.Angles(0, angle, 0)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness*0.7)) end)
        end
    end)
end
local function StopCirculo() if circuloConn then circuloConn:Disconnect() circuloConn = nil end end

TrollTab:AddToggle({
    Name = "⭕ Círculo (cintura)",
    Default = false,
    Callback = function(v) if v then startMode("Circulo", StartCirculo) else StopCirculo() activeMode = nil end end
})

-- CAÓTICO (agora com sliders)
local caoticoConn = nil
local function StartCaotico()
    local t = 0
    caoticoConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed
        for i, prop in ipairs(props) do
            local phase = t + i
            local side = math.sin(phase * 1.7) * 8
            local forward = math.cos(phase * 1.3) * 8
            local up = math.sin(phase * 2) * config.Height * 5
            local distance = (math.sin(phase * 0.8) + 1)/2 * config.Radius * 2
            local dir = (root.CFrame.LookVector * forward) + (root.CFrame.RightVector * side)
            local offset = dir.Unit * distance
            local pos = root.Position + offset + Vector3.new(0, up, 0)
            local cf = CFrame.new(pos) * CFrame.Angles(math.rad(t*200 + i*40), math.rad(t*180 + i*25), math.rad(math.sin(phase)*180))
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopCaotico() if caoticoConn then caoticoConn:Disconnect() caoticoConn = nil end end

TrollTab:AddToggle({
    Name = "🌀 Caótico",
    Default = false,
    Callback = function(v) if v then startMode("Caotico", StartCaotico) else StopCaotico() activeMode = nil end end
})

-- ESTRELA (props no ar espalhados)
local estrelaConn = nil
local function StartEstrela()
    local t = 0
    estrelaConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed * 0.7
        for i, prop in ipairs(props) do
            local height = 25 + math.sin(t + i) * 5
            local angle = i * 2.5 + t
            local radius = 12 + i * 1.5
            local offset = Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            local pos = root.Position + offset
            local cf = CFrame.new(pos) * CFrame.Angles(math.rad(t*50 + i*30), math.rad(t*35 + i*20), 0)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopEstrela() if estrelaConn then estrelaConn:Disconnect() estrelaConn = nil end end

TrollTab:AddToggle({
    Name = "✨ Estrela",
    Default = false,
    Callback = function(v) if v then startMode("Estrela", StartEstrela) else StopEstrela() activeMode = nil end end
})

-- PORTAL (círculo vertical na frente)
local portalConn = nil
local function StartPortal()
    local t = 0
    portalConn = RunService.Heartbeat:Connect(function(dt)
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed * 0.6
        local center = root.Position + root.CFrame.LookVector * 8 + Vector3.new(0,2,0)
        for i, prop in ipairs(props) do
            local angle = ((i-1)/#props) * 2*math.pi + t
            local side = math.cos(angle) * 6
            local up = math.sin(angle) * 6
            local pos = center + root.CFrame.RightVector * side + Vector3.new(0, up, 0)
            local cf = CFrame.new(pos) * CFrame.Angles(math.rad(up*5), angle, 0)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopPortal() if portalConn then portalConn:Disconnect() portalConn = nil end end

TrollTab:AddToggle({
    Name = "🚪 Portal",
    Default = false,
    Callback = function(v) if v then startMode("Portal", StartPortal) else StopPortal() activeMode = nil end end
})

-- TUDO JUNTO (gruda todos atrás)
local tudoJuntoConn = nil
local function StartTudoJunto()
    tudoJuntoConn = RunService.Heartbeat:Connect(function()
        local root = GetHRP()
        if not root then return end
        local props = GetMyProps()
        for _, prop in ipairs(props) do
            local cf = root.CFrame * CFrame.new(0, -1, -10) * CFrame.Angles(0, math.rad(-70), math.rad(59))
            pcall(function() prop.SetCurrentCFrame:InvokeServer(cf) end)
        end
    end)
end
local function StopTudoJunto() if tudoJuntoConn then tudoJuntoConn:Disconnect() tudoJuntoConn = nil end end

TrollTab:AddToggle({
    Name = "📦 Tudo Junto",
    Default = false,
    Callback = function(v) if v then startMode("TudoJunto", StartTudoJunto) else StopTudoJunto() activeMode = nil end end
})

--////////////////////////////////////////////////////
--// PROPS NO PLAYER SELECIONADO
--////////////////////////////////////////////////////
TrollTab:AddSection({"🎯 Props no Player Selecionado"})

-- FLING (movimento maluco)
local flingConn = nil
local sentFling = {}
local function StartFling()
    local t = 0
    flingConn = RunService.Heartbeat:Connect(function(dt)
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed
        for i, prop in ipairs(props) do
            if hum.Sit then
                if not sentFling[prop] then
                    sentFling[prop] = true
                    local upPos = Vector3.new(root.Position.X, 1000000, root.Position.Z)
                    pcall(function() prop.SetCurrentCFrame:InvokeServer(CFrame.new(upPos)) end)
                end
            else
                if sentFling[prop] then sentFling[prop] = nil end
                local move = Vector3.new(math.cos(t + i)*3, math.sin(t*2 + i)*2, math.sin(t + i*2)*3)
                local cf = root.CFrame * CFrame.new(move) * CFrame.Angles(math.rad(math.sin(t*4+i)*180), math.rad(t*200), math.rad(math.cos(t*3+i)*180))
                pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
            end
        end
    end)
end
local function StopFling() if flingConn then flingConn:Disconnect() flingConn = nil end sentFling = {} end

TrollTab:AddToggle({
    Name = "💥 Fling Player",
    Default = false,
    Callback = function(v) if v then startMode("Fling", StartFling) else StopFling() activeMode = nil end end
})

-- KILL (manda pro chão quando senta)
local killConn = nil
local sentKill = {}
local function StartKill()
    local t = 0
    killConn = RunService.Heartbeat:Connect(function(dt)
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed
        for i, prop in ipairs(props) do
            if hum.Sit then
                if not sentKill[prop] then
                    sentKill[prop] = true
                    pcall(function() prop.SetCurrentCFrame:InvokeServer(CFrame.new(root.Position.X, -460, root.Position.Z)) end)
                end
            else
                if sentKill[prop] then sentKill[prop] = nil end
                local move = Vector3.new(math.cos(t + i)*3, math.sin(t*2 + i)*2, math.sin(t + i*2)*3)
                local cf = root.CFrame * CFrame.new(move) * CFrame.Angles(math.rad(math.sin(t*4+i)*180), math.rad(t*200), math.rad(math.cos(t*3+i)*180))
                pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
            end
        end
    end)
end
local function StopKill() if killConn then killConn:Disconnect() killConn = nil end sentKill = {} end

TrollTab:AddToggle({
    Name = "☠️ Kill Player",
    Default = false,
    Callback = function(v) if v then startMode("Kill", StartKill) else StopKill() activeMode = nil end end
})

-- CÍRCULO NO CHÃO (com buraco)
local ringConn = nil
local function StartRing()
    local t = 0
    ringConn = RunService.Heartbeat:Connect(function(dt)
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed * 0.4
        local radius = 8
        local gap = math.rad(70)
        local usable = 2*math.pi - gap
        for i, prop in ipairs(props) do
            local angle = ((i-1)/#props) * usable + t
            local pos = root.Position + Vector3.new(math.cos(angle)*radius, -2.7, math.sin(angle)*radius)
            local cf = CFrame.new(pos) * CFrame.Angles(0, angle, 0)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopRing() if ringConn then ringConn:Disconnect() ringConn = nil end end

TrollTab:AddToggle({
    Name = "⭕ Círculo no Chão",
    Default = false,
    Callback = function(v) if v then startMode("Ring", StartRing) else StopRing() activeMode = nil end end
})

-- COBRA NO PLAYER
local cobraTargetConn = nil
local function StartCobraTarget()
    local t = 0
    cobraTargetConn = RunService.Heartbeat:Connect(function(dt)
        local target = Players:FindFirstChild(selectedPlayer)
        if not target or not target.Character then return end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local props = GetMyProps()
        if #props == 0 then return end
        t += dt * config.Speed
        for i, prop in ipairs(props) do
            local phase = t - i * 1.1
            local backDir = -root.CFrame.LookVector
            local rightDir = root.CFrame.RightVector
            local upDir = Vector3.new(0,1,0)
            local backOffset = backDir * (3.5 * i)
            local sideOffset = rightDir * (math.sin(phase) * 3.2)
            local upOffset = upDir * (math.cos(phase * 0.8) * 1.2)
            local pos = root.Position + backOffset + sideOffset + upOffset
            local cf = CFrame.lookAt(pos, pos + backDir)
            pcall(function() prop.SetCurrentCFrame:InvokeServer(prop:GetPivot():Lerp(cf, config.Smoothness)) end)
        end
    end)
end
local function StopCobraTarget() if cobraTargetConn then cobraTargetConn:Disconnect() cobraTargetConn = nil end end

TrollTab:AddToggle({
    Name = "🐍 Cobra no Player",
    Default = false,
    Callback = function(v) if v then startMode("CobraTarget", StartCobraTarget) else StopCobraTarget() activeMode = nil end end
})

--////////////////////////////////////////////////////
--// INICIALIZAÇÃO
--////////////////////////////////////////////////////
pcall(function()
    ReplicatedStorage.RE["1Too1l"]:InvokeServer("PickingTools", "PropMaker")
end)
task.wait(0.3)
pcall(function()
    ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("RequestingPropName", "FurnitureBleachers", "Furniture")
end)

print("✅ Spectra Props Remastered carregado!")