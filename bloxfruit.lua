local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ========== CONFIG ==========
local Running = true
local AutoFarmEnabled = false
local ESPEnabled = false
local ESPObjects = {}
local ConfigFile = "FruitFarm_Settings.json"
local IsStoring = false -- Flag to prevent teleport during storage

-- ========== FILE PERSISTENCE ==========
local function SaveSettings()
	if writefile then
		local data = {
			AutoFarmEnabled = AutoFarmEnabled,
			ESPEnabled = ESPEnabled
		}
		pcall(function()
			writefile(ConfigFile, HttpService:JSONEncode(data))
		end)
	end
end

local function LoadSettings()
	if isfile and readfile then
		if isfile(ConfigFile) then
			local success, data = pcall(function()
				return HttpService:JSONDecode(readfile(ConfigFile))
			end)
			if success and data then
				return data
			end
		end
	end
	return nil
end

-- ========== UI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "FruitFarmGui"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Close Button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
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

-- ESP Button (Top)
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

-- Auto Farm Button (Bottom)
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

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 180, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 250)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = gui

-- ========== CLOSE BUTTON FUNCTION ==========
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
	
	if isfile and isfile(ConfigFile) then
		pcall(function() delfile(ConfigFile) end)
	end
	
	print("[Script] Permanently closed")
end)

-- ========== ESP BUTTON ==========
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

-- ========== AUTO FARM BUTTON ==========
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

-- ========== AUTO-START CHECK ==========
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

-- ========== FRUIT ESP ==========
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

	ESPObjects[fruit] = {
		Billboard = billboard,
		Highlight = highlight,
		DistLabel = distLabel,
		Handle = handle
	}
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

-- ========== COLLECT WORLD FRUITS ==========
local function flyTo(pos)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for i = 1, 20 do
		if not Running then return end
		hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(pos + Vector3.new(0, 3, 0)), 0.35)
		task.wait()
	end
end

local function collectWorldFruits()
	for _, obj in pairs(workspace:GetChildren()) do
		if not Running or not AutoFarmEnabled then return end
		if IsFruit(obj) then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				statusLabel.Text = "Collecting: " .. obj.Name
				flyTo(handle.Position)
				pcall(function()
					local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
					if hum then 
						hum:EquipTool(obj) 
					end
				end)
				task.wait(0.5)
			end
		end
	end
	statusLabel.Text = "Collection Done"
end

-- ========== SCREEN TAP FUNCTIONS ==========
local function tapScreen(x, y)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
	task.wait(0.05)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function clickNevermind()
	-- Click "Nevermind" button to close menu
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end
	
	-- Search for Nevermind button
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") and gui.Visible then
			local text = string.lower(gui.Text)
			if text:find("nevermind") or text:find("close") or text:find("cancel") then
				pcall(function()
					gui.MouseButton1Click:Fire()
				end)
				return
			end
		end
	end
	
	-- If no button found, tap bottom-center where Nevermind usually is
	local screenSize = workspace.CurrentCamera.ViewportSize
	tapScreen(screenSize.X / 2, screenSize.Y / 2 + 120)
end

local function clickStoreButton()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	
	local screenSize = workspace.CurrentCamera.ViewportSize
	
	-- Method 1: Look for Store button in common paths
	local paths = {
		"Main.FruitMenu.Store",
		"Main.FruitMenu.StoreButton", 
		"FruitMenu.Store",
		"FruitMenu.StoreButton",
		"Main.StoreButton",
		"Menu.Store"
	}
	
	for _, path in pairs(paths) do
		local parts = string.split(path, ".")
		local current = playerGui
		local found = true
		
		for _, part in pairs(parts) do
			current = current:FindFirstChild(part)
			if not current then
				found = false
				break
			end
		end
		
		if found and current:IsA("GuiButton") then
			pcall(function()
				current.MouseButton1Click:Fire()
			end)
			return true
		end
	end
	
	-- Method 2: Search all descendants for visible Store button
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") or gui:IsA("ImageButton") then
			if gui.Visible then
				local name = string.lower(gui.Name)
				if name:find("store") and not name:find("storage") then
					pcall(function()
						gui.MouseButton1Click:Fire()
					end)
					return true
				end
			end
		end
	end
	
	-- Method 3: Tap right side where Store button usually appears (radial menu)
	tapScreen(screenSize.X / 2 + 100, screenSize.Y / 2)
	return true
end

-- ========== STORE SINGLE FRUIT ==========
local function storeSingleFruit(fruitName)
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return false end
	
	local character = LocalPlayer.Character
	local hum = character and character:FindFirstChild("Humanoid")
	if not hum then return false end
	
	-- Check if fruit exists
	local fruit = backpack:FindFirstChild(fruitName)
	if not fruit then 
		return true -- Already stored or gone
	end
	
	-- Step 1: Equip the fruit
	hum:EquipTool(fruit)
	task.wait(0.6)
	
	-- Step 2: Tap center to open menu
	local screenSize = workspace.CurrentCamera.ViewportSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	
	tapScreen(centerX, centerY)
	task.wait(0.5)
	
	-- Step 3: Click Store
	clickStoreButton()
	task.wait(0.6)
	
	-- Step 4: Click Nevermind to close menu
	clickNevermind()
	task.wait(0.4)
	
	-- Step 5: Check if stored
	local stillThere = backpack:FindFirstChild(fruitName)
	if stillThere then
		-- Try remote method as backup
		pcall(function()
			ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName)
		end)
		task.wait(0.3)
		stillThere = backpack:FindFirstChild(fruitName)
	end
	
	return not stillThere
end

-- ========== STORE ALL FRUITS ==========
local function storeAllFruits()
	IsStoring = true
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then 
		IsStoring = false
		return 
	end

	-- Get all fruits
	local fruits = {}
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and string.lower(item.Name):find("fruit") then
			table.insert(fruits, item)
		end
	end
	
	if #fruits == 0 then
		print("[Storage] No fruits to store")
		IsStoring = false
		return
	end
	
	print("[Storage] Storing " .. #fruits .. " fruits...")
	
	for i, fruit in ipairs(fruits) do
		if not Running or not AutoFarmEnabled then 
			IsStoring = false
			return 
		end
		
		statusLabel.Text = string.format("Storing %d/%d: %s", i, #fruits, fruit.Name)
		local success = storeSingleFruit(fruit.Name)
		
		if success then
			print(string.format("[Storage] ✓ Stored: %s", fruit.Name))
		else
			print(string.format("[Storage] ✗ Failed (Full?): %s", fruit.Name))
		end
		
		task.wait(0.5)
	end
	
	statusLabel.Text = "Storage Complete"
	print("[Storage] All fruits processed")
	IsStoring = false
end

-- ========== MAIN LOOP ==========
task.spawn(function()
	while Running do
		task.wait(3)
		if not Running then break end
		if not AutoFarmEnabled then continue end
		if IsStoring then continue end -- Wait if currently storing

		pcall(function()
			-- 1. Collect all world fruits first
			collectWorldFruits()

			-- 2. Store all fruits from inventory (ONE BY ONE)
			storeAllFruits()

			-- 3. Wait a bit to ensure storage is done
			task.wait(2)

			-- 4. Check if any fruit still exists in world
			local hasWorldFruit = false
			for _, obj in pairs(workspace:GetChildren()) do
				if IsFruit(obj) then
					hasWorldFruit = true
					break
				end
			end

			-- 5. Only teleport if no world fruits AND not currently storing
			if not hasWorldFruit and not IsStoring then
				print("[Auto Farm] No more fruits → Going to First Sea")
				task.wait(1) -- Small delay before teleport
				TeleportService:Teleport(2753915549)
			end
		end)
	end
end)

-- ========== AUTO RELOAD ==========
local ScriptURL = "https://raw.githubusercontent.com/Akashbhowmik1/Blox-fruit/main/bloxfruit.lua"
local queue_on_teleport = queue_on_teleport or syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet("' .. ScriptURL .. '"))()')
end

print("Fruit Farm loaded (Fixed Storage + Nevermind)")
