local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Akses Dunia...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { Enabled = false },
})

-- [[ VARIABEL GLOBAL ASLI ]]
_G.AutoTravel = true
_G.TravelDelay = 900 
_G.AutoClaim = true 
_G.StopClaiming = false 
local lastTravel = tick()
local player = game.Players.LocalPlayer

-- Database Inventory
local listPetBawaan = {} 
local listFruitBawaan = {}

-- ==========================================
-- TAB: SMART CLAIM (SESUAI ASLI)
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function setupDetection()
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if string.find(string.lower(obj.Text), "already have a booth") then
                _G.StopClaiming = true
                Rayfield:Notify({Title = "Sistem", Content = "Booth didapat!", Duration = 5})
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
                        if not _G.AutoClaim or _G.StopClaiming then break end
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
   Name = "Auto Claim Booth",
   CurrentValue = true,
   Callback = function(Value)
      _G.AutoClaim = Value
      if Value then startClaimLoop() end
   end,
})

setupDetection()
startClaimLoop()

-- ==========================================
-- TAB: PET MERCHANT (SESUAI ASLI)
-- ==========================================
local TabPetMerchant = Window:CreateTab("Pet Merchant", 4483362458)

local antreanPetSlots = {}
local isSellingPet = false

TabPetMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Pet)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("ItemType") == "Pet" or item:GetAttribute("PET_UUID") then
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
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabPetMerchant:CreateSection("Urutan Antrean")
      
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
   Callback = function(Value)
      isSellingPet = Value
      if Value then jalankanJualPet() end
   end,
})

-- ==========================================
-- TAB: FRUIT MERCHANT (FITUR BARU)
-- ==========================================
local TabFruitMerchant = Window:CreateTab("Fruit Merchant", 4483362458)

local antreanFruitSlots = {}
local isSellingFruit = false

TabFruitMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Fruit)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            -- Berdasarkan screenshot Bone Blossom, item buah memiliki atribut 'c' sebagai UUID
            -- dan biasanya memiliki atribut 'b' dengan value 'j'
            if item:GetAttribute("b") == "j" or (not item:GetAttribute("PET_UUID") and item:GetAttribute("c")) then
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
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabFruitMerchant:CreateSection("Urutan Antrean")
      
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
                                -- Menggunakan atribut 'c' sesuai screenshot Bone Blossom
                                local uuid = item:GetAttribute("c") 
                                if uuid then
                                    pcall(function()
                                        -- Menggunakan argumen "Fruit" untuk kategori buah
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Fruit", tostring(uuid), tonumber(slot.Price))
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
   Callback = function(Value)
      isSellingFruit = Value
      if Value then jalankanJualFruit() end
   end,
})

-- ==========================================
-- TAB: TELEPORT (SESUAI ASLI)
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

TabTeleport:CreateButton({
   Name = "TRAVEL TO TRADE WORLD",
   Callback = function()
      pcall(function()
         game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer()
      end)
   end,
})

TabTeleport:CreateButton({
   Name = "TRAVEL TO MAIN WORLD",
   Callback = function()
      pcall(function()
         game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer()
      end)
   end,
})

TabTeleport:CreateToggle({
   Name = "Auto Travel (Repeat)",
   CurrentValue = true,
   Callback = function(Value) _G.AutoTravel = Value end,
})

TabTeleport:CreateInput({
   Name = "Travel Delay (Seconds)",
   PlaceholderText = "900",
   NumbersOnly = true,
   Callback = function(Text)
      _G.TravelDelay = tonumber(Text) or 900
      Rayfield:Notify({Title = "Sistem", Content = "Delay travel diubah ke: " .. _G.TravelDelay .. " detik", Duration = 3})
   end,
})

-- [[ LOGIKA BACKGROUND ]]
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            pcall(function()
               game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer()
            end)
            lastTravel = tick()
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
