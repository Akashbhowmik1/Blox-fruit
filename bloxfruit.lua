-- ========== AUTO EXECUTE SETUP ==========
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

local function tapScreen(x, y)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
	task.wait(0.05)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ========== FIXED STORE FUNCTIONS ==========
local function findAndClickButton(buttonName, searchText)
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	
	-- Search by name first
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") or gui:IsA("ImageButton") then
			if gui.Visible then
				local name = string.lower(gui.Name)
				if name:find(string.lower(buttonName)) then
					pcall(function()
						gui.MouseButton1Click:Fire()
					end)
					return true
				end
			end
		end
	end
	
	-- Search by text content
	if searchText then
		for _, gui in pairs(playerGui:GetDescendants()) do
			if gui:IsA("TextButton") and gui.Visible then
				local text = string.lower(gui.Text)
				if text:find(string.lower(searchText)) then
					pcall(function()
						gui.MouseButton1Click:Fire()
					end)
					return true
				end
			end
		end
	end
	
	return false
end

local function closeFruitMenu()
	-- Try to find Nevermind/Close button
	if findAndClickButton("nevermind", "nevermind") then return true end
	if findAndClickButton("close", "close") then return true end
	if findAndClickButton("cancel", "cancel") then return true end
	
	-- Tap center to close menu
	local screenSize = workspace.CurrentCamera.ViewportSize
	tapScreen(screenSize.X / 2, screenSize.Y / 2)
	return true
end

local function attemptStoreFruit(fruitName)
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = LocalPlayer.Character
	local hum = character and character:FindFirstChild("Humanoid")
	
	if not backpack or not hum then return false end
	
	-- Check if fruit exists
	local fruit = backpack:FindFirstChild(fruitName)
	if not fruit then return true end -- Already stored
	
	print("[Storage] Storing: " .. fruitName)
	
	-- Step 1: Equip the fruit
	hum:EquipTool(fruit)
	task.wait(0.8)
	
	-- Step 2: Open radial menu (tap center)
	local screenSize = workspace.CurrentCamera.ViewportSize
	local cx, cy = screenSize.X / 2, screenSize.Y / 2
	tapScreen(cx, cy)
	task.wait(0.7)
	
	-- Step 3: Try to click Store button (multiple methods)
	local storeClicked = false
	
	-- Method 1: Find by name
	if findAndClickButton("store", nil) then
		storeClicked = true
	elseif findAndClickButton("storebutton", nil) then
		storeClicked = true
	else
		-- Method 2: Tap right side where Store usually is (3 o'clock position)
		tapScreen(cx + 120, cy)
		storeClicked = true
	end
	
	task.wait(0.8) -- Wait for storage to process
	
	-- Step 4: Close the menu
	closeFruitMenu()
	task.wait(0.4)
	
	-- Step 5: VERIFY - Check if fruit is still in backpack
	local stillInBackpack = backpack:FindFirstChild(fruitName)
	
	if stillInBackpack then
		-- UI method failed, try remote method
		print("[Storage] UI failed, trying remote...")
		local success = pcall(function()
			-- Try the Blox Fruits store remote
			ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName)
		end)
		
		task.wait(0.6)
		
		-- Check again
		stillInBackpack = backpack:FindFirstChild(fruitName)
		
		if stillInBackpack then
			print("[Storage] FAILED: " .. fruitName .. " (Storage Full or Error)")
			return false
		else
			print("[Storage] SUCCESS (Remote): " .. fruitName)
			return true
		end
	else
		print("[Storage] SUCCESS (UI): " .. fruitName)
		return true
	end
end

local function storeAllFruits()
	StorageInProgress = true
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
	
	if #fruits == 0 then
		print("[Storage] No fruits to store")
		StorageInProgress = false
		return
	end
	
	print("[Storage] Found " .. #fruits .. " fruits")
	
	local stored = 0
	local failed = 0
	
	for i, fruit in ipairs(fruits) do
		if not Running or not AutoFarmEnabled then 
			StorageInProgress = false
			return 
		end
		
		statusLabel.Text = string.format("Storing %d/%d: %s", i, #fruits, fruit.Name)
		
		local success = attemptStoreFruit(fruit.Name)
		if success then
			stored = stored + 1
		else
			failed = failed + 1
		end
		
		task.wait(0.8) -- Delay between fruits
	end
	
	-- Final count
	local remaining = 0
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and string.lower(item.Name):find("fruit") then
			remaining = remaining + 1
		end
	end
	
	statusLabel.Text = string.format("Done! Stored:%d Failed:%d", stored, failed)
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
				statusLabel.Text = "Collecting: " .. obj.Name
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
		task.wait(3)
		if not Running then break end
		if not AutoFarmEnabled then continue end
		if StorageInProgress then continue end
		
		-- Step 1: Collect all world fruits
		collectWorldFruits()
		
		-- Step 2: Store all fruits (this blocks until done)
		storeAllFruits()
		
		-- Step 3: Extra wait to ensure storage fully completes
		task.wait(2)
		
		-- Step 4: Check if any fruits still in world
		local hasWorldFruit = false
		for _, obj in pairs(workspace:GetChildren()) do
			if IsFruit(obj) then
				hasWorldFruit = true
				break
			end
		end
		
		-- Step 5: Only teleport if world is clear AND storage is done
		if not hasWorldFruit and not StorageInProgress then
			print("[Auto Farm] All done! Teleporting to First Sea...")
			task.wait(2)
			TeleportService:Teleport(2753915549)
		end
	end
end)

print("[Script] Loaded - Fruit Storage Fixed")
