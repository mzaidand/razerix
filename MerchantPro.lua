local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Akses Dunia...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { 
       Enabled = true, -- Fitur Save Diaktifkan
       FolderName = "ZaylinhoConfigs", 
       FileName = "MerchantProSave" 
   },
})

-- [[ VARIABEL GLOBAL ]]
_G.AutoClaim = true 
_G.StopClaiming = false 

-- Variabel Auto Travel (Dipisah jadi 2 untuk Trade dan Main)
_G.AutoTravelTrade = true
_G.TravelDelayTrade = 900
_G.AutoTravelMain = false
_G.TravelDelayMain = 900

-- Variabel Auto Rejoin Baru
_G.AutoRejoin = false
_G.RejoinDelay = 900

local lastTravelTrade = tick()
local lastTravelMain = tick()
local lastRejoin = tick()
local player = game.Players.LocalPlayer

-- Database Inventory
local listPetBawaan = {} 
local listFruitBawaan = {}

-- ==========================================
-- TAB: SMART CLAIM (LOGIKA TERBARU: TELEPORT & CARI TERDEKAT)
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function setupDetection()
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if string.find(string.lower(obj.Text), "already have a booth") then
                _G.StopClaiming = true
                Rayfield:Notify({Title = "Sistem", Content = "Booth berhasil didapat!", Duration = 5})
            end
        end
    end)
end

local function startClaimLoop()
    _G.StopClaiming = false
    task.spawn(function()
        while _G.AutoClaim do
            if not _G.StopClaiming then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local boothFolder = workspace:FindFirstChild("TradeWorld") and workspace.TradeWorld:FindFirstChild("Booths")
                
                if hrp and boothFolder then
                    -- 1. Teleport ke Area Booth (Sesuai SimpleSpy)
                    pcall(function()
                        game:GetService("ReplicatedStorage").GameEvents.PlayerTeleportTriggered:FireServer("Booth")
                    end)
                    
                    task.wait(0.5) -- Tunggu setengah detik agar karakter sampai di lokasi
                    
                    -- 2. Cari Booth Kosong Terdekat
                    local boothTerdekat = nil
                    local jarakTerkecil = math.huge -- Set nilai awal jarak sebesar mungkin
                    
                    for _, booth in pairs(boothFolder:GetChildren()) do
                        if not _G.AutoClaim or _G.StopClaiming then break end
                        
                        -- Cek apakah booth kosong
                        if not booth:GetAttribute("Owner") or booth:GetAttribute("Owner") == 0 then
                            -- Hitung jarak dari badan karakter ke booth
                            local boothPos = booth:GetPivot().Position
                            local jarak = (hrp.Position - boothPos).Magnitude
                            
                            if jarak < jarakTerkecil then
                                jarakTerkecil = jarak
                                boothTerdekat = booth
                            end
                        end
                    end
                    
                    -- 3. Claim Booth yang Paling Dekat
                    if boothTerdekat and not _G.StopClaiming then
                        pcall(function()
                            game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.ClaimBooth:FireServer(boothTerdekat)
                        end)
                    end
                end
            end
            task.wait(1.5) -- Jeda loop agar tidak ngespam teleport
        end
    end)
end

TabClaim:CreateToggle({
   Name = "Auto Claim Booth",
   CurrentValue = true,
   Flag = "Toggle_AutoClaim", -- Flag agar settingan tersave
   Callback = function(Value)
      _G.AutoClaim = Value
      if Value then startClaimLoop() end
   end,
})

setupDetection()
startClaimLoop()

-- ==========================================
-- TAB: PET MERCHANT
-- ==========================================
local TabPetMerchant = Window:CreateTab("Pet Merchant", 4483362458)

local antreanPetSlots = {}
local antreanCounterPet = 0
local isSellingPet = false

TabPetMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Pet)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("PET_UUID") then
               if not table.find(temp, item.Name) then table.insert(temp, item.Name) end
            end
         end
      end
      listPetBawaan = temp
      Rayfield:Notify({Title = "Sistem", Content = #listPetBawaan .. " Pet Terdeteksi!", Duration = 3})
   end,
})

TabPetMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounterPet = antreanCounterPet + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabPetMerchant:CreateSection("Urutan Antrean #" .. antreanCounterPet)
      
      local dd = TabPetMerchant:CreateDropdown({
         Name = "Pilih Pet",
         Options = listPetBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Callback = function(Options) slotData.Items = Options end,
      })

      TabPetMerchant:CreateInput({
         Name = "🔍 Cari Pet",
         PlaceholderText = "Ketik nama...",
         Callback = function(Text)
            if Text == "" then
                dd:Refresh(listPetBawaan, true)
            else
                local query = string.lower(Text)
                local filtered = {}
                for _, name in pairs(listPetBawaan) do
                   if string.find(string.lower(name), query) then table.insert(filtered, name) end
                end
                dd:Refresh(filtered, true)
            end
         end,
      })
      
      TabPetMerchant:CreateInput({Name = "Harga", PlaceholderText = "2", NumbersOnly = true, Callback = function(Text) slotData.Price = tonumber(Text) or 2 end})
      TabPetMerchant:CreateInput({Name = "Jeda", PlaceholderText = "5", NumbersOnly = true, Callback = function(Text) slotData.Delay = tonumber(Text) or 5 end})
      
      table.insert(antreanPetSlots, slotData)
   end,
})

local function jalankanJualPet()
    task.spawn(function()
        while isSellingPet do
            for _, slot in ipairs(antreanPetSlots) do
                if not isSellingPet then break end
                for _, petName in ipairs(slot.Items) do
                    local bp = player:FindFirstChild("Backpack")
                    if bp then
                        for _, item in pairs(bp:GetChildren()) do
                            if item.Name == petName and isSellingPet then
                                local uuid = item:GetAttribute("PET_UUID") 
                                if uuid then
                                    pcall(function()
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Pet", tostring(uuid), tonumber(slot.Price))
                                    end)
                                    task.wait(slot.Delay)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end

TabPetMerchant:CreateToggle({
   Name = "🚀 MULAI AUTO MERCHANT PET",
   CurrentValue = false,
   Flag = "Toggle_MerchantPet", -- Flag agar settingan tersave
   Callback = function(Value)
      isSellingPet = Value
      if Value then jalankanJualPet() end
   end,
})

-- ==========================================
-- TAB: FRUIT MERCHANT
-- ==========================================
local TabFruitMerchant = Window:CreateTab("Fruit Merchant", 4483362458)

local antreanFruitSlots = {}
local antreanCounterFruit = 0
local isSellingFruit = false

TabFruitMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Fruit)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("c") and not item:GetAttribute("PET_UUID") then
               if not table.find(temp, item.Name) then table.insert(temp, item.Name) end
            end
         end
      end
      listFruitBawaan = temp
      Rayfield:Notify({Title = "Sistem", Content = #listFruitBawaan .. " Buah Terdeteksi!", Duration = 3})
   end,
})

TabFruitMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounterFruit = antreanCounterFruit + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabFruitMerchant:CreateSection("Urutan Antrean Buah #" .. antreanCounterFruit)
      
      local dd = TabFruitMerchant:CreateDropdown({
         Name = "Pilih Buah",
         Options = listFruitBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Callback = function(Options) slotData.Items = Options end,
      })

      TabFruitMerchant:CreateInput({
         Name = "🔍 Cari Buah",
         PlaceholderText = "Ketik nama buah...",
         Callback = function(Text)
            if Text == "" then
                dd:Refresh(listFruitBawaan, true) 
            else
                local query = string.lower(Text)
                local filtered = {}
                for _, name in pairs(listFruitBawaan) do
                   if string.find(string.lower(name), query) then table.insert(filtered, name) end
                end
                dd:Refresh(filtered, true)
            end
         end,
      })
      
      TabFruitMerchant:CreateInput({Name = "Harga", PlaceholderText = "2", NumbersOnly = true, Callback = function(Text) slotData.Price = tonumber(Text) or 2 end})
      TabFruitMerchant:CreateInput({Name = "Jeda", PlaceholderText = "5", NumbersOnly = true, Callback = function(Text) slotData.Delay = tonumber(Text) or 5 end})
      
      table.insert(antreanFruitSlots, slotData)
   end,
})

local function jalankanJualFruit()
    task.spawn(function()
        while isSellingFruit do
            for _, slot in ipairs(antreanFruitSlots) do
                if not isSellingFruit then break end
                for _, fruitName in ipairs(slot.Items) do
                    local bp = player:FindFirstChild("Backpack")
                    if bp then
                        for _, item in pairs(bp:GetChildren()) do
                            if item.Name == fruitName and isSellingFruit then
                                local uuid = item:GetAttribute("c") 
                                if uuid then
                                    pcall(function()
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Holdable", tostring(uuid), tonumber(slot.Price))
                                    end)
                                    task.wait(slot.Delay)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end

TabFruitMerchant:CreateToggle({
   Name = "🚀 MULAI AUTO MERCHANT FRUIT",
   CurrentValue = false,
   Flag = "Toggle_MerchantFruit", -- Flag agar settingan tersave
   Callback = function(Value)
      isSellingFruit = Value
      if Value then jalankanJualFruit() end
   end,
})

-- ==========================================
-- TAB: TELEPORT 
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

-- Tombol Manual
TabTeleport:CreateButton({
   Name = "TRAVEL TO TRADE WORLD",
   Callback = function()
      pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end)
   end,
})

TabTeleport:CreateButton({
   Name = "TRAVEL TO MAIN WORLD",
   Callback = function()
      pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer() end)
   end,
})

-- Bagian Server Management 
TabTeleport:CreateSection("Server Management")

TabTeleport:CreateButton({
   Name = "🔄 REJOIN SERVER INI",
   Callback = function()
      Rayfield:Notify({Title = "Sistem", Content = "Mencoba rejoin ke server yang sama...", Duration = 3})
      task.wait(1) 
      local ts = game:GetService("TeleportService")
      local p = game:GetService("Players").LocalPlayer
      pcall(function()
          ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
      end)
   end,
})

TabTeleport:CreateToggle({
   Name = "Auto Rejoin (Repeat)",
   CurrentValue = false,
   Flag = "Toggle_AutoRejoin", -- Flag Save
   Callback = function(Value) _G.AutoRejoin = Value end,
})

TabTeleport:CreateInput({
   Name = "Rejoin Delay (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayRejoin", -- Flag Save
   Callback = function(Text)
      _G.RejoinDelay = tonumber(Text) or 900
   end,
})

-- Bagian Auto Travel Trade World
TabTeleport:CreateSection("Auto Travel: Trade World")

TabTeleport:CreateToggle({
   Name = "Auto Travel (Trade World)",
   CurrentValue = true,
   Flag = "Toggle_TravelTrade", -- Flag Save
   Callback = function(Value) _G.AutoTravelTrade = Value end,
})

TabTeleport:CreateInput({
   Name = "Delay Trade World (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayTrade", -- Flag Save
   Callback = function(Text)
      _G.TravelDelayTrade = tonumber(Text) or 900
   end,
})

-- Bagian Auto Travel Main World
TabTeleport:CreateSection("Auto Travel: Main World")

TabTeleport:CreateToggle({
   Name = "Auto Travel (Main World)",
   CurrentValue = false,
   Flag = "Toggle_TravelMain", -- Flag Save
   Callback = function(Value) _G.AutoTravelMain = Value end,
})

TabTeleport:CreateInput({
   Name = "Delay Main World (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayMain", -- Flag Save
   Callback = function(Text)
      _G.TravelDelayMain = tonumber(Text) or 900
   end
})

-- [[ LOGIKA BACKGROUND ]]
task.spawn(function()
    while true do
        task.wait(1)
        local currentTick = tick()
        
        -- Timer Trade World
        if _G.AutoTravelTrade and currentTick - lastTravelTrade >= _G.TravelDelayTrade then
            pcall(function()
               game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer()
            end)
            lastTravelTrade = tick()
        end
        
        -- Timer Main World
        if _G.AutoTravelMain and currentTick - lastTravelMain >= _G.TravelDelayMain then
            pcall(function()
               game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer()
            end)
            lastTravelMain = tick()
        end

        -- Timer Auto Rejoin
        if _G.AutoRejoin and currentTick - lastRejoin >= _G.RejoinDelay then
            pcall(function()
                local ts = game:GetService("TeleportService")
                local p = game:GetService("Players").LocalPlayer
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
            end)
            lastRejoin = tick()
        end
    end
end)

-- ANTI-AFK
local vu = game:GetService("VirtualUser")
player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- LOAD KONFIGURASI YANG TERSIMPAN
-- ==========================================
Rayfield:LoadConfiguration()
