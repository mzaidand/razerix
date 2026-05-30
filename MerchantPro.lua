local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Akses Dunia...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { 
       Enabled = true, 
       FolderName = "ZaylinhoConfigs", 
       FileName = "MerchantProSave" 
   },
})

-- [[ VARIABEL GLOBAL ]]
_G.AutoClaim = true 
_G.StopClaiming = false 

-- Variabel Auto Travel
_G.AutoTravelTrade = true
_G.TravelDelayTrade = 900
_G.AutoTravelMain = false
_G.TravelDelayMain = 900

-- Variabel Auto Rejoin & Teleport Booth
_G.AutoRejoin = false
_G.RejoinDelay = 900
_G.AutoTeleportBooth = false
_G.TeleportBoothDelay = 10

-- Variabel Auto Sprinkler
_G.AutoSprinkler = false
_G.SprinklerDelay = 300 
_G.SelectedSprinklers = {}
local lastSprinklerTick = {} -- DATABASE TIMER INDIVIDUAL BARU

-- Variabel Auto Input Fruit (Fitur Baru)
_G.AutoFruitName = ""
_G.AutoFruitPrice = 3
_G.AutoFruitDelay = 5

local lastTravelTrade = tick()
local lastTravelMain = tick()
local lastRejoin = tick()
local lastTeleportBooth = tick()
local player = game.Players.LocalPlayer

-- Database Inventory
local listPetBawaan = {} 
local listFruitBawaan = {}

-- ==========================================
-- TAB: SMART CLAIM
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function setupDetection()
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if string.find(string.lower(obj.Text), "already have a booth") then
                _G.StopClaiming = true
                Rayfield:Notify({Title = "Sistem", Content = "Booth sudah didapat! Berhenti spam.", Duration = 5})
            end
        end
    end)
end

local function startClaimLoop()
    _G.StopClaiming = false
    task.spawn(function()
        while _G.AutoClaim do
            if not _G.StopClaiming then
                local boothFolder = workspace:FindFirstChild("TradeWorld") and workspace.TradeWorld:FindFirstChild("Booths")
                if boothFolder then
                    for _, booth in pairs(boothFolder:GetChildren()) do
                        if _G.StopClaiming or not _G.AutoClaim then break end
                        
                        if not booth:GetAttribute("Owner") or booth:GetAttribute("Owner") == 0 then
                            pcall(function()
                                game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.ClaimBooth:FireServer(booth)
                            end)
                            task.wait(0.1) 
                        end
                    end
                end
            end
            task.wait(1) 
        end
    end)
end

TabClaim:CreateToggle({
   Name = "Auto Claim Booth (Anti-Spam)",
   CurrentValue = true,
   Flag = "Toggle_AutoClaim", 
   Callback = function(Value)
      _G.AutoClaim = Value
      if Value then startClaimLoop() end
   end,
})

TabClaim:CreateButton({
   Name = "Equip Skin: Default",
   Callback = function()
      pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeBoothSkinService.Equip:FireServer("Default") end)
   end,
})

setupDetection()
startClaimLoop()

-- ==========================================
-- TAB: AUTO SPRINKLER (INDIVIDUAL TIMER)
-- ==========================================
local TabSprinkler = Window:CreateTab("Auto Sprinkler", 4483362458)

local listSprinkler = {"Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Master Sprinkler", "Grandmaster Sprinkler"}

TabSprinkler:CreateDropdown({
   Name = "Pilih Jenis Sprinkler",
   Options = listSprinkler,
   CurrentOption = {},
   MultipleOptions = true,
   Flag = "Dropdown_Sprinkler", 
   Callback = function(Options)
      _G.SelectedSprinklers = Options
      -- Reset timer jika ada perubahan agar langsung naruh ulang
      lastSprinklerTick = {}
   end,
})

local function jalankanAutoSprinkler()
    task.spawn(function()
        while _G.AutoSprinkler do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local backpack = player:FindFirstChild("Backpack")

            if hrp and backpack and #_G.SelectedSprinklers > 0 then
                local currentTick = tick()
                local dipasangSekarang = {}
                local placeCFrame = nil -- Dihitung sekali saja kalau ada yang butuh ditanam

                for _, namaDicari in ipairs(_G.SelectedSprinklers) do
                    if not _G.AutoSprinkler then break end

                    -- Tentukan delay spesifik untuk item ini
                    local thisDelay = _G.SprinklerDelay
                    if string.find(namaDicari, "Master") or string.find(namaDicari, "Grandmaster") then
                        thisDelay = 600
                    elseif string.find(namaDicari, "Basic") or string.find(namaDicari, "Advanced") or string.find(namaDicari, "Godly") then
                        thisDelay = 300
                    end

                    local lastTick = lastSprinklerTick[namaDicari] or 0

                    -- Cek apakah sudah waktunya (atau belum pernah dipasang sama sekali)
                    if currentTick - lastTick >= thisDelay or lastTick == 0 then
                        
                        local sprinklerToUse = nil
                        
                        -- Cari barangnya
                        for _, item in pairs(backpack:GetChildren()) do
                            local namaAsli = item.Name
                            local namaAtribut = tostring(item:GetAttribute("f") or "")
                            if string.find(namaAsli, namaDicari) or string.find(namaAtribut, namaDicari) then
                                sprinklerToUse = item
                                break
                            end
                        end
                        if not sprinklerToUse then
                            for _, item in pairs(char:GetChildren()) do
                                local namaAsli = item.Name
                                local namaAtribut = tostring(item:GetAttribute("f") or "")
                                if string.find(namaAsli, namaDicari) or string.find(namaAtribut, namaDicari) then
                                    sprinklerToUse = item
                                    break
                                end
                            end
                        end

                        -- Kalau stoknya ada, pasang!
                        if sprinklerToUse then
                            -- Hitung koordinat (Raycast) hanya jika belum dihitung di loop ini
                            if not placeCFrame then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterDescendantsInstances = {char}
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude

                                local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), rayParams)
                                if rayResult then
                                    placeCFrame = CFrame.new(rayResult.Position)
                                else
                                    placeCFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.5, hrp.Position.Z)
                                end
                            end

                            pcall(function()
                                local humanoid = char:FindFirstChild("Humanoid")
                                if humanoid and sprinklerToUse.Parent == backpack then
                                    humanoid:EquipTool(sprinklerToUse)
                                    task.wait(0.3)
                                end

                                game:GetService("ReplicatedStorage").GameEvents.SprinklerService:FireServer("Create", placeCFrame)

                                local inputChar = char:FindFirstChild("InputGateway")
                                local inputScript = player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("InputGateway")

                                if inputChar and inputChar:FindFirstChild("Activation") then
                                    inputChar.Activation:FireServer(true, placeCFrame)
                                    task.wait(0.1)
                                    inputChar.Activation:FireServer(false, placeCFrame)
                                end

                                if inputScript and inputScript:FindFirstChild("Activation") then
                                    inputScript.Activation:FireServer(true, placeCFrame)
                                    task.wait(0.1)
                                    inputScript.Activation:FireServer(false, placeCFrame)
                                end
                            end)

                            -- Catat waktu penanaman untuk jenis ini
                            lastSprinklerTick[namaDicari] = tick()
                            table.insert(dipasangSekarang, namaDicari)
                            task.wait(0.5) -- Jeda animasi antar sprinkler
                        end
                    end
                end

                if #dipasangSekarang > 0 then
                    local namaGabungan = table.concat(dipasangSekarang, ", ")
                    Rayfield:Notify({
                        Title = "Auto Sprinkler", 
                        Content = "Berhasil menaruh: " .. namaGabungan, 
                        Duration = 4
                    })
                end
            end
            
            -- Loop akan mengecek setiap 5 detik (Tidak bikin server berat, dan sangat responsif)
            task.wait(5)
        end
    end)
end

TabSprinkler:CreateToggle({
   Name = "🚀 MULAI AUTO SPRINKLER",
   CurrentValue = false,
   Flag = "Toggle_AutoSprinkler",
   Callback = function(Value)
      _G.AutoSprinkler = Value
      if Value then 
          lastSprinklerTick = {} -- Reset timer saat dinyalakan
          jalankanAutoSprinkler() 
      end
   end,
})

TabSprinkler:CreateInput({
   Name = "Jeda Fallback/Lainnya (Detik)",
   PlaceholderText = "300",
   NumbersOnly = true,
   Flag = "Input_SprinklerDelay",
   Callback = function(Text)
      _G.SprinklerDelay = tonumber(Text) or 300
   end
})

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
   Flag = "Toggle_MerchantPet", 
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

-- [[ FITUR BARU: AUTO INPUT VIA PENULISAN NAMA (AUTO-SAVE) ]]
TabFruitMerchant:CreateSection("Auto Input Fruit (Berdasarkan Nama)")

TabFruitMerchant:CreateInput({
   Name = "Nama Buah Spesifik",
   PlaceholderText = "Contoh: Bone Blossom",
   Flag = "Input_AutoFruitName",
   Callback = function(Text)
      _G.AutoFruitName = Text
   end,
})

TabFruitMerchant:CreateInput({
   Name = "Harga Jual Otomatis",
   PlaceholderText = "3",
   NumbersOnly = true,
   Flag = "Input_AutoFruitPrice",
   Callback = function(Text)
      _G.AutoFruitPrice = tonumber(Text) or 3
   end,
})

TabFruitMerchant:CreateInput({
   Name = "Jeda Otomatis (Detik)",
   PlaceholderText = "5",
   NumbersOnly = true,
   Flag = "Input_AutoFruitDelay",
   Callback = function(Text)
      _G.AutoFruitDelay = tonumber(Text) or 5
   end,
})

local function jalankanJualFruit()
    task.spawn(function()
        while isSellingFruit do
            -- 1. Jalankan Antrean Manual (Dari Tombol Tambah Antrean)
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

            -- 2. Jalankan Antrean Otomatis Berdasarkan Penulisan Nama (Fitur Baru)
            if _G.AutoFruitName and _G.AutoFruitName ~= "" and isSellingFruit then
                local bp = player:FindFirstChild("Backpack")
                if bp then
                    for _, item in pairs(bp:GetChildren()) do
                        if not isSellingFruit then break end
                        
                        -- Cek apakah nama item mengandung teks yang dicari (Case Insensitive)
                        if string.find(string.lower(item.Name), string.lower(_G.AutoFruitName)) then
                            local uuid = item:GetAttribute("c")
                            if uuid and not item:GetAttribute("PET_UUID") then
                                pcall(function()
                                    game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Holdable", tostring(uuid), tonumber(_G.AutoFruitPrice))
                                end)
                                task.wait(_G.AutoFruitDelay)
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
   Flag = "Toggle_MerchantFruit",
   Callback = function(Value)
      isSellingFruit = Value
      if Value then jalankanJualFruit() end
   end,
})

-- ==========================================
-- TAB: TELEPORT 
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

TabTeleport:CreateButton({
   Name = "TRAVEL TO TRADE WORLD",
   Callback = function() pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end) end,
})

TabTeleport:CreateButton({
   Name = "TRAVEL TO MAIN WORLD",
   Callback = function() pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer() end) end,
})

TabTeleport:CreateButton({
   Name = "TELEPORT TO BOOTH AREA",
   Callback = function() pcall(function() game:GetService("ReplicatedStorage").GameEvents.PlayerTeleportTriggered:FireServer("Booth") end) end,
})

TabTeleport:CreateSection("Server Management")

TabTeleport:CreateButton({
   Name = "🔄 REJOIN SERVER INI",
   Callback = function()
      Rayfield:Notify({Title = "Sistem", Content = "Mencoba rejoin ke server yang sama...", Duration = 3})
      task.wait(1) 
      local ts = game:GetService("TeleportService")
      local p = game:GetService("Players").LocalPlayer
      pcall(function() ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p) end)
   end,
})

TabTeleport:CreateToggle({
   Name = "Auto Rejoin (Repeat)",
   CurrentValue = false,
   Flag = "Toggle_AutoRejoin", 
   Callback = function(Value) _G.AutoRejoin = Value end,
})

TabTeleport:CreateInput({
   Name = "Rejoin Delay (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayRejoin",
   Callback = function(Text) _G.RejoinDelay = tonumber(Text) or 900 end,
})

TabTeleport:CreateSection("Auto Travel: Trade World")

TabTeleport:CreateToggle({
   Name = "Auto Travel (Trade World)",
   CurrentValue = true,
   Flag = "Toggle_TravelTrade",
   Callback = function(Value) _G.AutoTravelTrade = Value end,
})

TabTeleport:CreateInput({
   Name = "Delay Trade World (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayTrade",
   Callback = function(Text) _G.TravelDelayTrade = tonumber(Text) or 900 end,
})

TabTeleport:CreateSection("Auto Travel: Main World")

TabTeleport:CreateToggle({
   Name = "Auto Travel (Main World)",
   CurrentValue = false,
   Flag = "Toggle_TravelMain",
   Callback = function(Value) _G.AutoTravelMain = Value end,
})

TabTeleport:CreateInput({
   Name = "Delay Main World (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Flag = "Input_DelayMain",
   Callback = function(Text) _G.TravelDelayMain = tonumber(Text) or 900 end
})

TabTeleport:CreateSection("Auto Travel: Booth Area")

TabTeleport:CreateToggle({
   Name = "Auto Teleport (Booth Area)",
   CurrentValue = false,
   Flag = "Toggle_TeleportBooth",
   Callback = function(Value) _G.AutoTeleportBooth = Value end,
})

TabTeleport:CreateInput({
   Name = "Delay Teleport Booth (Seconds)",
   PlaceholderText = "10",
   NumbersOnly = true,
   Flag = "Input_DelayTeleportBooth",
   Callback = function(Text) _G.TeleportBoothDelay = tonumber(Text) or 10 end
})

-- [[ LOGIKA BACKGROUND ]]
task.spawn(function()
    while true do
        task.wait(1)
        local currentTick = tick()
        
        if _G.AutoTravelTrade and currentTick - lastTravelTrade >= _G.TravelDelayTrade then
            pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end)
            lastTravelTrade = tick()
        end
        
        if _G.AutoTravelMain and currentTick - lastTravelMain >= _G.TravelDelayMain then
            pcall(function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer() end)
            lastTravelMain = tick()
        end

        if _G.AutoRejoin and currentTick - lastRejoin >= _G.RejoinDelay then
            pcall(function()
                local ts = game:GetService("TeleportService")
                local p = game:GetService("Players").LocalPlayer
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
            end)
            lastRejoin = tick()
        end
        
        if _G.AutoTeleportBooth and currentTick - lastTeleportBooth >= _G.TeleportBoothDelay then
            pcall(function() game:GetService("ReplicatedStorage").GameEvents.PlayerTeleportTriggered:FireServer("Booth") end)
            lastTeleportBooth = tick()
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

Rayfield:LoadConfiguration()
