local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Akses Ekosistem...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { Enabled = false },
})

-- [[ VARIABEL GLOBAL ]]
_G.AutoTravel = false
_G.TravelDelay = 900 
_G.AutoClaim = false 
_G.StopClaiming = false 
_G.AutoFarm = false -- Untuk toggle auto merchant
local lastTravel = tick()
local player = game.Players.LocalPlayer
local listPetBawaan = {} -- Database nama pet

-- ==========================================
-- TAB: SMART CLAIM
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function startClaimLoop()
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
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoClaim = Value
      if Value then startClaimLoop() end
   end,
})

TabClaim:CreateSection("Info")
TabClaim:CreateLabel("Otomatis mencari booth kosong di Trade World.")

-- ==========================================
-- TAB: AUTO MERCHANT (FIXED & SEARCHABLE)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

local antreanSlots = {}
local antreanCounter = 0
local isSelling = false

TabMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Pet Only)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            -- Filter berdasarkan atribut ItemType atau PetType
            local isPet = item:GetAttribute("ItemType") == "Pet" or item:GetAttribute("PetType") == "Pet"
            if isPet then
               if not table.find(temp, item.Name) then 
                  table.insert(temp, item.Name) 
               end
            end
         end
      end
      listPetBawaan = temp
      Rayfield:Notify({Title = "Sistem", Content = #listPetBawaan .. " Jenis Pet Terdeteksi!", Duration = 3})
   end,
})

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabMerchant:CreateSection("Urutan Antrean #" .. antreanCounter)
      
      -- DROPDOWN
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Pet",
         Options = listPetBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Flag = "Slot_" .. antreanCounter,
         Callback = function(Options) slotData.Items = Options end,
      })

      -- MANUAL SEARCH FILTER
      TabMerchant:CreateInput({
         Name = "🔍 Search Pet (Ketik Nama)",
         PlaceholderText = "Cari pet di sini...",
         NumbersOnly = false,
         Callback = function(Text)
            local query = string.lower(Text)
            local filtered = {}
            for _, name in pairs(listPetBawaan) do
               if string.find(string.lower(name), query) then
                  table.insert(filtered, name)
               end
            end
            if #filtered > 0 then
               dd:Refresh(filtered, true)
            elseif Text == "" then
               dd:Refresh(listPetBawaan, true)
            else
               dd:Refresh({"Tidak ditemukan!"}, true)
            end
         end,
      })
      
      TabMerchant:CreateInput({
         Name = "Harga (Token)",
         PlaceholderText = "2",
         NumbersOnly = true,
         Callback = function(Text) slotData.Price = tonumber(Text) or 2 end,
      })
      
      TabMerchant:CreateInput({
         Name = "Jeda Pasang (Detik)",
         PlaceholderText = "5",
         NumbersOnly = true,
         Callback = function(Text) slotData.Delay = tonumber(Text) or 5 end,
      })
      
      table.insert(antreanSlots, slotData)
   end,
})

local function prosesJual()
    task.spawn(function()
        while isSelling do
            for _, slot in ipairs(antreanSlots) do
                if not isSelling then break end
                for _, petName in ipairs(slot.Items) do
                    if not isSelling then break end
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        for _, itemObj in pairs(backpack:GetChildren()) do
                            if itemObj.Name == petName and isSelling then
                                -- MENGGUNAKAN UUID DARI ATRIBUT
                                local petUUID = itemObj:GetAttribute("PET_UUID") 
                                if petUUID then
                                    pcall(function()
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer(
                                            "Pet", 
                                            tostring(petUUID), 
                                            tonumber(slot.Price)
                                        )
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

TabMerchant:CreateToggle({
   Name = "🚀 3. MULAI AUTO MERCHANT",
   CurrentValue = false,
   Callback = function(Value)
      isSelling = Value
      if Value then 
         prosesJual() 
         Rayfield:Notify({Title = "Sistem", Content = "Auto Merchant Aktif!", Duration = 3})
      end
   end,
})

-- ==========================================
-- TAB: TELEPORT
-- ==========================================
local TabTele = Window:CreateTab("Teleport", 4483362458)

TabTele:CreateButton({
   Name = "TRAVEL TO TRADE WORLD",
   Callback = function()
      game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer()
   end,
})

TabTele:CreateButton({
   Name = "TRAVEL TO MAIN WORLD (GARDEN)",
   Callback = function()
      game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToMainWorld:FireServer()
   end,
})

TabTele:CreateToggle({
   Name = "Auto Travel (Repeat)",
   CurrentValue = false,
   Callback = function(Value) _G.AutoTravel = Value end,
})

-- ==========================================
-- BACKLOG LOGIC (TRAVEL & ANTI-AFK)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer()
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

Rayfield:Notify({Title = "Zaylinho Pro", Content = "Script Siap Digunakan!", Duration = 5})
