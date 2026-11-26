local VictorAccess = {}
local state = {
    busy = false,
    selected = nil,
    initialCount = 0,
    currentCount = 0,
    closed = false,
    connections = {}
}

-- 1. INTERFACE (CoreGui para garantir visibilidade)
local gui = Instance.new("ScreenGui")
gui.Name = "VictorAccessDupeUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

local function createUI(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    if children then for _, c in ipairs(children) do c.Parent = obj end end
    return obj
end

local panel = createUI("Frame", {
    Name = "MainPanel",
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(450, 320),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    BorderSizePixel = 0,
    Visible = true
}, {
    createUI("TextLabel", {
        Name = "Title",
        Text = "VICTOR ACCESS: FORCE DUPE ENGINE",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    }),
    createUI("TextLabel", {
        Name = "Status",
        Text = "Pronto.",
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 14
    }),
    createUI("TextLabel", {
        Name = "Stats",
        Text = "Antes: 0 | Agora: 0 | Diff: 0",
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(100, 255, 100),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }),
    createUI("TextButton", {
        Name = "BtnSelect",
        Text = "1. SELECIONAR MARRETA",
        Position = UDim2.new(0, 10, 0, 90),
        Size = UDim2.new(0.45, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(0, 150, 255),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }),
    createUI("TextButton", {
        Name = "BtnBaseline",
        Text = "2. BASELINE (Ler)",
        Position = UDim2.new(0.55, 10, 0, 90),
        Size = UDim2.new(0.45, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(0, 200, 100),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }),
    createUI("TextButton", {
        Name = "BtnForceDupe",
        Text = "3. FORÇAR DUPE",
        Position = UDim2.new(0, 10, 0, 145),
        Size = UDim2.new(1, -20, 0, 55),
        BackgroundColor3 = Color3.fromRGB(255, 50, 50),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    }),
    createUI("TextButton", {
        Name = "BtnCheck",
        Text = "4. VERIFICAR INVENTÁRIO",
        Position = UDim2.new(0, 10, 0, 210),
        Size = UDim2.new(1, -20, 0, 45),
        BackgroundColor3 = Color3.fromRGB(255, 165, 0),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }),
    createUI("TextButton", {
        Name = "BtnClose",
        Text = "FECHAR",
        Position = UDim2.new(0, 10, 0, 270),
        Size = UDim2.new(1, -20, 0, 40),
        BackgroundColor3 = Color3.fromRGB(80, 80, 80),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 12
    })
})
gui.Parent = game:GetService("CoreGui")

local ui = {
    status = panel:WaitForChild("Status"),
    stats = panel:WaitForChild("Stats"),
    btnSelect = panel:WaitForChild("BtnSelect"),
    btnBaseline = panel:WaitForChild("BtnBaseline"),
    btnForce = panel:WaitForChild("BtnForceDupe"),
    btnCheck = panel:WaitForChild("BtnCheck"),
    btnClose = panel:WaitForChild("BtnClose")
}

local function status(msg)
    ui.status.Text = msg
end

local function updateStats(before, after)
    local diff = after - before
    ui.stats.Text = string.format("Antes: %d | Agora: %d | Diff: %s%d", before, after, diff > 0 and "+" or "", diff)
    if diff > 0 then
        ui.stats.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif diff < 0 then
        ui.stats.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        ui.stats.TextColor3 = Color3.fromRGB(255, 255, 100)
    end
end

-- 2. LÓGICA DE INSPEÇÃO
local function countTools(toolName)
    local count = 0
    for _, obj in ipairs(game:GetService("Players").LocalPlayer:Children()) do
        if obj:IsA("Tool") and obj.Name == toolName then
            count += 1
        end
    end
    return count
end

local function findToolInstance(toolName)
    for _, obj in ipairs(game:GetService("Players").LocalPlayer:Children()) do
        if obj:IsA("Tool") and obj.Name == toolName then
            return obj
        end
    end
    return nil
end

local function getTradeRoutine()
    local rf = game:GetService("ReplicatedFirst")
    local names = {"AddToTradeOffer", "Trade", "AddToTrade", "StartTrade"}
    for _, name in ipairs(names) do
        local remote = rf:FindFirstChild(name)
        if remote and remote:IsA("RemoteFunction") then
            return function(...) return remote:InvokeServer(...) end
        end
    end
    if _G.AddToTradeOffer then
        return function(...) return _G.AddToTradeOffer(...) end
    end
    return nil
end

local tradeFunc = getTradeRoutine()
if not tradeFunc then
    status("ERRO: Rotina de trade nao encontrada.")
else
    status("Rotina de trade detectada.")
end

-- 3. AÇÕES
local function selectTool()
    if state.busy then return end
    status("Clique em uma marreta no inventário...")
    ui.btnSelect.Text = "AGUARDANDO..."
    
    local connected = true
    local conn = game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp or not connected then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        
        local selected = findToolInstance("Hammer") or findToolInstance("Marreta")
        if not selected then
            for _, obj in ipairs(game:GetService("Players").LocalPlayer:Children()) do
                if obj:IsA("Tool") then selected = obj break end
            end
        end
        
        if selected then
            state.selected = selected
            status("Selecionado: " .. selected.Name)
            ui.btnSelect.Text = "1. SELECIONAR MARRETA"
            connected = false
        else
            status("Nenhuma ferramenta encontrada.")
            ui.btnSelect.Text = "1. SELECIONAR MARRETA"
            connected = false
        end
    end)
    
    task.delay(5, function()
        if connected then
            connected = false
            ui.btnSelect.Text = "1. SELECIONAR MARRETA"
            status("Timeout de seleção.")
        end
    end)
end

local function setBaseline()
    if not state.selected then
        status("Selecione uma marreta primeiro.")
        return
    end
    state.initialCount = countTools(state.selected.Name)
    state.currentCount = state.initialCount
    updateStats(state.initialCount, state.currentCount)
    status("Baseline: " .. state.initialCount .. " itens.")
end

local function checkInventory()
    if not state.selected then
        status("Selecione uma marreta primeiro.")
        return
    end
    state.currentCount = countTools(state.selected.Name)
    updateStats(state.initialCount, state.currentCount)
    
    local diff = state.currentCount - state.initialCount
    if diff > 0 then
        status(string.rep("🔥", 5) .. " DUPE CONFIRMADO! +" .. diff .. " itens.")
    elseif diff < 0 then
        status("Falha: Itens perdidos (" .. diff .. ").")
    else
        status("Nenhuma alteração detectada.")
    end
end

local function forceDupe()
    if state.busy then return end
    if not state.selected then
        status("Selecione uma marreta primeiro.")
        return
    end
    if not tradeFunc then
        status("Rotina de trade indisponível.")
        return
    end
    
    state.busy = true
    ui.btnForce.Text = "DUPLICANDO..."
    ui.btnForce.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    status("Iniciando Rapid Fire...")
    
    local toolName = state.selected.Name
    local initialCount = countTools(toolName)
    state.initialCount = initialCount
    state.currentCount = initialCount
    updateStats(initialCount, initialCount)
    
    task.spawn(function()
        local attempts = 10
        for i = 1, attempts do
            task.wait(math.random(1, 20) / 1000)
            pcall(tradeFunc, toolName)
        end
        
        status("Enviados " .. attempts .. " pedidos. Aguardando...")
        task.wait(3)
        
        if state.closed then return end
        
        state.currentCount = countTools(toolName)
        updateStats(state.initialCount, state.currentCount)
        
        local diff = state.currentCount - state.initialCount
        if diff > 0 then
            status(string.rep("🔥", 5) .. " DUPE CONFIRMADO! +" .. diff .. " itens.")
        else
            status("Estratégia falhou. Tente novamente.")
        end
        
        state.busy = false
        ui.btnForce.Text = "3. FORÇAR DUPE"
        ui.btnForce.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end)
end

-- 4. CONEXÕES
ui.btnSelect.MouseButton1Click:Connect(selectTool)
ui.btnBaseline.MouseButton1Click:Connect(setBaseline)
ui.btnForce.MouseButton1Click:Connect(forceDupe)
ui.btnCheck.MouseButton1Click:Connect(checkInventory)
ui.btnClose.MouseButton1Click:Connect(function()
    state.closed = true
    for _, conn in ipairs(state.connections) do
        pcall(function() conn:Disconnect() end)
    end
    if gui.Parent then gui:Destroy() end
    if game:GetService("ReplicatedFirst").VictorAccessDupe then
        game:GetService("ReplicatedFirst").VictorAccessDupe = nil
    end
end)

game:GetService("ReplicatedFirst").VictorAccessDupe = {
    close = function() ui.btnClose:Activate() end,
    state = state
}

status("Sistema pronto.")
