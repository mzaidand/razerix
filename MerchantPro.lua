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

local lastTravelTrade = tick()
local lastTravelMain = tick()
local lastRejoin = tick()
local lastTeleportBooth = tick()
local player = game.Players.LocalPlayer

-- Database Inventory
local listPetBawaan = {} 
local listFruitBawaan = {}

-- [[ FUNGSI AUTO REFRESH INVENTORY ]]
local function autoRefreshInventory()
    -- Refresh Pet
    local tempPet = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("PET_UUID") then
               if not table.find(tempPet, item.Name) then table.insert(tempPet, item.Name) end
            end
        end
    end
    listPetBawaan = tempPet

    -- Refresh Fruit
    local tempFruit = {}
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("c") and not item:GetAttribute("PET_UUID") then
               if not table.find(tempFruit, item.Name) then table.insert(tempFruit, item.Name) end
            end
        end
    end
    listFruitBawaan = tempFruit
end

-- Jalankan refresh otomatis di awal agar data tas langsung siap
autoRefreshInventory()

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
                local placeCFrame = nil 

                for _, namaDicari in ipairs(_G.SelectedSprinklers) do
                    if not _G.AutoSprinkler then break end

                    local thisDelay = _G.SprinklerDelay
                    if string.find(namaDicari, "Master") or string.find(namaDicari, "Grandmaster") then
                        thisDelay = 600
                    elseif string.find(namaDicari, "Basic") or string.find(namaDicari, "Advanced") or string.find(namaDicari, "Godly") then
                        thisDelay = 300
                    end

                    local lastTick = lastSprinklerTick[namaDicari] or 0

                    if currentTick - lastTick >= thisDelay or lastTick == 0 then
                        local sprinklerToUse = nil
                        
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

                        if sprinklerToUse then
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

                            lastSprinklerTick[namaDicari] = tick()
                            table.insert(dipasangSekarang, namaDicari)
                            task.wait(0.5) 
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
          lastSprinklerTick = {} 
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
      autoRefreshInventory()
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
       GreenwoodPet = Value
      if Value then jalankanJualPet() end
   end,
})

-- ==========================================
-- TAB: FRUIT MERCHANT (WITH AUTO SAVE/LOAD)
-- ==========================================
local TabFruitMerchant = Window:CreateTab("Fruit Merchant", 4483362458)

local antreanFruitSlots = {}
local antreanCounterFruit = 0
local isSellingFruit = false
local fileCacheName = "Zaylinho_FruitQueue.json"

-- Fungsi Simpan Antrean Manual ke berkas eksternal
local function simpanAntreanFruitEksternal()
    local sukses, hasil = pcall(function()
        local dataFormat = {}
        for _, slot in ipairs(antreanFruitSlots) do
            table.insert(dataFormat, {
                Items = slot.Items,
                Price = slot.Price,
                Delay = slot.Delay
            })
        end
        writefile(fileCacheName, game:GetService("HttpService"):JSONEncode(dataFormat))
    end)
end

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

TabFruitMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Fruit)",
   Callback = function()
      autoRefreshInventory()
      Rayfield:Notify({Title = "Sistem", Content = #listFruitBawaan .. " Buah Terdeteksi!", Duration = 3})
   end,
})

-- Membuat fungsi pembangun UI Slot agar bisa dipanggil berulang (saat klik atau saat auto-load)
local function buatSlotAntreanFruitUI(dataAwal)
    antreanCounterFruit = antreanCounterFruit + 1
    
    local slotData = dataAwal or { Items = {}, Price = 3, Delay = 5 }
    if not dataAwal then
        table.insert(antreanFruitSlots, slotData)
    end

    TabFruitMerchant:CreateSection("Urutan Antrean Buah #" .. antreanCounterFruit)
    
    local dd = TabFruitMerchant:CreateDropdown({
       Name = "Pilih Buah",
       Options = listFruitBawaan,
       CurrentOption = slotData.Items,
       MultipleOptions = true,
       Callback = function(Options) 
           slotData.Items = Options 
           simpanAntreanFruitEksternal()
       end,
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
    
    TabFruitMerchant:CreateInput({
        Name = "Harga", 
        PlaceholderText = tostring(slotData.Price), 
        NumbersOnly = true, 
        Callback = function(Text) 
            slotData.Price = tonumber(Text) or 3 
            simpanAntreanFruitEksternal()
        end
    })
    
    TabFruitMerchant:CreateInput({
        Name = "Jeda", 
        PlaceholderText = tostring(slotData.Delay), 
        NumbersOnly = true, 
        Callback = function(Text) 
            slotData.Delay = tonumber(Text) or 5 
            simpanAntreanFruitEksternal()
        end
    })
    
    if not dataAwal then
        simpanAntreanFruitEksternal()
    end
end

TabFruitMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      buatSlotAntreanFruitUI(nil)
   end,
})

TabFruitMerchant:CreateToggle({
   Name = "🚀 MULAI AUTO MERCHANT FRUIT",
   CurrentValue = false,
   Flag = "Toggle_MerchantFruit",
   Callback = function(Value)
      isSellingFruit = Value
      if Value then jalankanJualFruit() end
   end,
})

-- [[ SISTEM AUTOMATIC LOAD UNTUK FRUIT QUEUE ]]
local function muatAntreanFruitEksternal()
    if isfile and readfile and isfile(fileCacheName) then
        local sukses, isi = pcall(function() return readfile(fileCacheName) end)
        if sukses and isi then
            local dataTerurai = game:GetService("HttpService"):JSONDecode(isi)
            if dataTerurai and type(dataTerurai) == "table" then
                for _, dataSlot in ipairs(dataTerurai) do
                    local slotBaru = {
                        Items = dataSlot.Items or {},
                        Price = dataSlot.Price or 3,
                        Delay = dataSlot.Delay or 5
                    }
                    table.insert(antreanFruitSlots, slotBaru)
                    buatSlotAntreanFruitUI(slotBaru)
                end
            end
        end
    end
end

-- Panggil sistem loading otomatis setelah UI Tab Fruit dibuat
muatAntreanFruitEksternal()

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
   Callback = function(Text) _G.TravelDelayBooth = tonumber(Text) or 10 end
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
