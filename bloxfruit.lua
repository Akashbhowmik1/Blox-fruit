-- ========== AUTO RELOAD ==========
local ScriptURL = "https://raw.githubusercontent.com/Akashbhowmik1/Blox-fruit/main/bloxfruit.lua"
local queue_on_teleport = queue_on_teleport or syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet("' .. ScriptURL .. '"))()')
end

-- ========== SERVICES ==========
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ========== CONFIG ==========
local Running = true
local AutoFarmEnabled = false
local ESPEnabled = false
local ESPObjects = {}
local ConfigFile = "FruitFarm_Settings.json"
local StorageInProgress = false
local FruitsProcessed = 0
local TotalFruits = 0

-- ========== FILE PERSISTENCE ==========
local function SaveSettings()
	if writefile then
		local data = {AutoFarmEnabled = AutoFarmEnabled, ESPEnabled = ESPEnabled}
		pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
	end
end

local function LoadSettings()
	if isfile and readfile and isfile(ConfigFile) then
		local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
		if success and data then return data end
	end
	return nil
end

-- ========== UI CREATION ==========
local gui = Instance.new("ScreenGui")
gui.Name = "FruitFarmGui"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(0, 162, 0, 150)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 10
closeBtn.Parent = gui
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ESP Frame
local espFrame = Instance.new("Frame")
espFrame.Size = UDim2.new(0, 180, 0, 42)
espFrame.Position = UDim2.new(0, 10, 0, 150)
espFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
espFrame.BorderSizePixel = 0
espFrame.Parent = gui
Instance.new("UICorner", espFrame).CornerRadius = UDim.new(0, 8)

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -8, 1, -8)
espBtn.Position = UDim2.new(0, 4, 0, 4)
espBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
espBtn.Text = "Fruit ESP: OFF"
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 14
espBtn.Parent = espFrame
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

-- Farm Frame
local farmFrame = Instance.new("Frame")
farmFrame.Size = UDim2.new(0, 180, 0, 42)
farmFrame.Position = UDim2.new(0, 10, 0, 205)
farmFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
farmFrame.BorderSizePixel = 0
farmFrame.Parent = gui
Instance.new("UICorner", farmFrame).CornerRadius = UDim.new(0, 8)

local farmBtn = Instance.new("TextButton")
farmBtn.Size = UDim2.new(1, -8, 1, -8)
farmBtn.Position = UDim2.new(0, 4, 0, 4)
farmBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
farmBtn.Text = "Start Auto Farm"
farmBtn.TextColor3 = Color3.new(1, 1, 1)
farmBtn.Font = Enum.Font.GothamBold
farmBtn.TextSize = 14
farmBtn.Parent = farmFrame
Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 6)

-- Progress Label
local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(0, 180, 0, 20)
progressLabel.Position = UDim2.new(0, 10, 0, 250)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "Ready"
progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextSize = 12
progressLabel.Parent = gui

-- ========== BUTTON FUNCTIONS ==========
closeBtn.MouseButton1Click:Connect(function()
	Running = false
	AutoFarmEnabled = false
	ESPEnabled = false
	for _, data in pairs(ESPObjects) do
		pcall(function()
			if data.Billboard then data.Billboard:Destroy() end
			if data.Highlight then data.Highlight:Destroy() end
		end)
	end
	table.clear(ESPObjects)
	gui:Destroy()
	if isfile and isfile(ConfigFile) then pcall(function() delfile(ConfigFile) end) end
	print("[Script] Closed")
end)

espBtn.MouseButton1Click:Connect(function()
	if not Running then return end
	ESPEnabled = not ESPEnabled
	SaveSettings()
	if ESPEnabled then
		espBtn.Text = "Fruit ESP: ON"
		espBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 0)
	else
		espBtn.Text = "Fruit ESP: OFF"
		espBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
		for _, data in pairs(ESPObjects) do
			pcall(function()
				if data.Billboard then data.Billboard:Destroy() end
				if data.Highlight then data.Highlight:Destroy() end
			end)
		end
		table.clear(ESPObjects)
	end
end)

farmBtn.MouseButton1Click:Connect(function()
	if not Running then return end
	AutoFarmEnabled = not AutoFarmEnabled
	SaveSettings()
	if AutoFarmEnabled then
		farmBtn.Text = "Stop Auto Farm"
		farmBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 0)
		print("[Auto Farm] Started")
	else
		farmBtn.Text = "Start Auto Farm"
		farmBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
		print("[Auto Farm] Stopped")
	end
end)

-- ========== AUTO-START ==========
task.spawn(function()
	task.wait(2)
	local saved = LoadSettings()
	if saved then
		if saved.AutoFarmEnabled then
			AutoFarmEnabled = true
			farmBtn.Text = "Stop Auto Farm"
			farmBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 0)
		end
		if saved.ESPEnabled then
			ESPEnabled = true
			espBtn.Text = "Fruit ESP: ON"
			espBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 0)
		end
	end
end)

-- ========== ESP FUNCTIONS ==========
local function IsFruit(obj)
	if not obj:IsA("Tool") then return false end
	if obj.Parent ~= workspace then return false end
	if not obj:FindFirstChild("Handle") then return false end
	if not obj:FindFirstChild("Fruit") then return false end
	return true
end

local function CreateESP(fruit)
	if ESPObjects[fruit] then return end
	local handle = fruit:FindFirstChild("Handle")
	if not handle then return end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = fruit
	highlight.FillColor = Color3.fromRGB(255, 170, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = fruit
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = handle
	billboard.Size = UDim2.new(0, 250, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = gui
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = fruit.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.Parent = billboard
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0.45, 0)
	distLabel.Position = UDim2.new(0, 0, 0.55, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = ""
	distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	distLabel.TextStrokeTransparency = 0.3
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 15
	distLabel.Parent = billboard
	ESPObjects[fruit] = {Billboard = billboard, Highlight = highlight, DistLabel = distLabel, Handle = handle}
end

local function RemoveESP(fruit)
	local data = ESPObjects[fruit]
	if data then
		if data.Billboard then data.Billboard:Destroy() end
		if data.Highlight then data.Highlight:Destroy() end
		ESPObjects[fruit] = nil
	end
end

RunService.RenderStepped:Connect(function()
	if not Running or not ESPEnabled then return end
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local found = {}
	for _, obj in pairs(workspace:GetChildren()) do
		if IsFruit(obj) then
			found[obj] = true
			CreateESP(obj)
		end
	end
	for fruit, data in pairs(ESPObjects) do
		if not found[fruit] or not fruit.Parent then
			RemoveESP(fruit)
		elseif hrp and data.Handle and data.DistLabel then
			local dist = (hrp.Position - data.Handle.Position).Magnitude
			data.DistLabel.Text = string.format("%.0f studs away", dist)
		end
	end
end)

-- ========== COLLECTION & STORAGE ==========
local function flyTo(pos)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for i = 1, 20 do
		if not Running then return end
		hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(pos + Vector3.new(0, 3, 0)), 0.35)
		task.wait()
	end
end

local function tap(x, y)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
	task.wait(0.1)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ========== MACRO-STYLE STORAGE ==========
local function getScreenCenter()
	local size = workspace.CurrentCamera.ViewportSize
	return size.X / 2, size.Y / 2
end

local function clickButtonByText(textToFind)
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") and gui.Visible then
			if string.lower(gui.Text) == string.lower(textToFind) then
				local pos = gui.AbsolutePosition
				local size = gui.AbsoluteSize
				local clickX = pos.X + size.X/2
				local clickY = pos.Y + size.Y/2
				tap(clickX, clickY)
				return true
			end
		end
	end
	return false
end

local function isMenuOpen()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	
	-- Check for menu text
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") and gui.Visible then
			local text = string.lower(gui.Text)
			if text:find("what do you wish") or text:find("blox fruit") then
				return true
			end
		end
	end
	return false
end

local function isStorageFullDialog()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") and gui.Visible then
			local text = string.lower(gui.Text)
			if text:find("storage full") or text:find("would you like to purchase") then
				return true
			end
		end
	end
	return false
end

local function storeFruitMacro(fruitName)
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if not backpack or not hum then return false end
	
	local fruit = backpack:FindFirstChild(fruitName)
	if not fruit then return true end -- Already stored
	
	print("[Macro] Step 1: Equipping " .. fruitName)
	progressLabel.Text = string.format("Step 1/5: Equipping %s", fruitName)
	hum:EquipTool(fruit)
	task.wait(1)
	
	-- Step 2: Open menu (tap center)
	print("[Macro] Step 2: Opening menu")
	progressLabel.Text = "Step 2/5: Opening menu"
	local cx, cy = getScreenCenter()
	tap(cx, cy)
	task.wait(0.8)
	
	-- Step 3: Click Store button (based on your screenshot, Store is the 3rd option)
	-- In Blox Fruits radial menu: Eat(top), Drop(right), Store(bottom), Nevermind(left)
	-- Actually from screenshot: Eat, Drop, Store, Nevermind - Store appears to be below center
	print("[Macro] Step 3: Clicking Store")
	progressLabel.Text = "Step 3/5: Clicking Store"
	
	-- Try clicking by text first
	if not clickButtonByText("Store") then
		-- Store appears to be below center based on screenshot
		tap(cx, cy + 80)
	end
	task.wait(1)
	
	-- Step 4: Check if Storage Full dialog appeared
	if isStorageFullDialog() then
		print("[Macro] Storage full dialog detected")
		progressLabel.Text = "Step 4/5: Storage full, clicking Nevermind"
		clickButtonByText("Nevermind")
		task.wait(0.5)
		return false -- Failed to store
	end
	
	-- Step 5: Verify storage by checking if fruit is gone
	task.wait(0.5)
	local stillThere = backpack:FindFirstChild(fruitName)
	
	if stillThere then
		-- Try remote method
		print("[Macro] Trying remote method...")
		pcall(function()
			ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName)
		end)
		task.wait(0.8)
		stillThere = backpack:FindFirstChild(fruitName)
		
		if stillThere then
			-- Close menu and return fail
			tap(cx, cy)
			task.wait(0.3)
			clickButtonByText("Nevermind")
			return false
		end
	end
	
	print("[Macro] Successfully stored " .. fruitName)
	progressLabel.Text = "Step 5/5: Stored!"
	return true
end

local function storeAllFruits()
	StorageInProgress = true
	FruitsProcessed = 0
	
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then 
		StorageInProgress = false
		return 
	end
	
	-- Get all fruits
	local fruits = {}
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and string.lower(item.Name):find("fruit") then
			table.insert(fruits, item)
		end
	end
	
	TotalFruits = #fruits
	if TotalFruits == 0 then
		print("[Storage] No fruits to store")
		StorageInProgress = false
		return
	end
	
	print(string.format("[Storage] Starting macro for %d fruits", TotalFruits))
	
	local stored = 0
	local failed = 0
	
	for i, fruit in ipairs(fruits) do
		if not Running or not AutoFarmEnabled then 
			StorageInProgress = false
			return 
		end
		
		FruitsProcessed = i
		print(string.format("[Storage] Processing %d/%d: %s", i, TotalFruits, fruit.Name))
		
		local success = storeFruitMacro(fruit.Name)
		if success then
			stored = stored + 1
		else
			failed = failed + 1
			print(string.format("[Storage] Failed to store %s (storage full or error)", fruit.Name))
		end
		
		task.wait(1) -- Delay between fruits
	end
	
	-- Final verification
	local remaining = 0
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and string.lower(item.Name):find("fruit") then
			remaining = remaining + 1
		end
	end
	
	progressLabel.Text = string.format("Done! Stored:%d Failed:%d", stored, failed)
	print(string.format("[Storage] Complete! Stored:%d Failed:%d Remaining:%d", stored, failed, remaining))
	StorageInProgress = false
end

-- ========== MAIN LOGIC ==========
local function collectWorldFruits()
	for _, obj in pairs(workspace:GetChildren()) do
		if not Running or not AutoFarmEnabled then return end
		if IsFruit(obj) then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				progressLabel.Text = "Collecting: " .. obj.Name
				flyTo(handle.Position)
				pcall(function()
					local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
					if hum then hum:EquipTool(obj) end
				end)
				task.wait(0.5)
			end
		end
	end
end

-- ========== MAIN LOOP ==========
task.spawn(function()
	while Running do
		task.wait(2)
		if not Running then break end
		if not AutoFarmEnabled then continue end
		if StorageInProgress then 
			progressLabel.Text = string.format("Storing... %d/%d", FruitsProcessed, TotalFruits)
			continue 
		end
		
		-- Step 1: Collect
		collectWorldFruits()
		
		-- Step 2: Store all
		storeAllFruits()
		
		-- Step 3: Wait for completion
		while StorageInProgress do
			task.wait(0.5)
		end
		
		task.wait(1)
		
		-- Step 4: Check world fruits
		local hasWorldFruit = false
		for _, obj in pairs(workspace:GetChildren()) do
			if IsFruit(obj) then
				hasWorldFruit = true
				break
			end
		end
		
		-- Step 5: Teleport if done
		if not hasWorldFruit and not StorageInProgress then
			print("[Auto Farm] Complete! Teleporting...")
			progressLabel.Text = "Teleporting..."
			task.wait(2)
			TeleportService:Teleport(2753915549)
		end
	end
end)

print("[Script] Loaded - Macro Style Storage")
