local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Fitur Pet Merchant...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { Enabled = false },
})

-- Variabel Global
_G.AutoTravel = true
_G.TravelDelay = 900 
_G.AutoClaim = true 
_G.StopClaiming = false 
local lastTravel = tick()
local player = game.Players.LocalPlayer

-- ==========================================
-- TAB: SMART CLAIM
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function setupDetection()
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if string.find(string.lower(obj.Text), "already have a booth") then
                _G.StopClaiming = true
                Rayfield:Notify({Title = "Sistem", Content = "Booth didapat! Auto-claim berhenti.", Duration = 5})
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
-- TAB: AUTO MERCHANT (FIXED FOR PETS)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

local listPetBawaan = {"Refresh Inventory Pet!"}
local antreanSlots = {} 
local antreanCounter = 0
local isSelling = false

TabMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Khusus Pet)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            -- Filter hanya untuk item tipe "Pet" berdasarkan atribut
            local itemType = item:GetAttribute("ItemType") or item:GetAttribute("PetType")
            if itemType == "Pet" then
               if not table.find(temp, item.Name) then 
                  table.insert(temp, item.Name) 
               end
            end
         end
      end
      
      if #temp == 0 then
         Rayfield:Notify({Title = "Sistem", Content = "Tidak ada Pet ditemukan di Backpack!", Duration = 3})
      else
         listPetBawaan = temp
         -- Update semua dropdown yang sudah dibuat
         for _, slot in pairs(antreanSlots) do
            if slot.Dropdown then slot.Dropdown:Refresh(listPetBawaan, true) end
         end
         Rayfield:Notify({Title = "Sistem", Content = #temp .. " Jenis Pet Terdeteksi!", Duration = 3})
      end
   end,
})

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabMerchant:CreateSection("Urutan Antrean #" .. antreanCounter)
      
      -- Dropdown otomatis mendukung fitur Search/Pencarian
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Pet (Bisa Search)",
         Options = listPetBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Flag = "Slot_" .. antreanCounter,
         Callback = function(Options) slotData.Items = Options end,
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
      
      slotData.Dropdown = dd
      table.insert(antreanSlots, slotData)
   end,
})

local function jalankanProsesJual()
    task.spawn(function()
        while isSelling do
            for _, slot in ipairs(antreanSlots) do
                if not isSelling then break end
                for _, petName in ipairs(slot.Items) do
                    if not isSelling then break end
                    local backpack = player:FindFirstChild("Backpack")
                    if not backpack then break end
                    
                    for _, itemObj in pairs(backpack:GetChildren()) do
                        -- Cek nama dan pastikan itu Pet
                        if itemObj.Name == petName and isSelling then
                            -- Mengambil UUID sesuai gambar atribut anda
                            local petUUID = itemObj:GetAttribute("PET_UUID") 
                            
                            if petUUID then
                                local sukses = false
                                pcall(function()
                                    -- Sesuai format SimpleSpy: [1] "Pet", [2] UUID String, [3] Harga
                                    game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Pet", tostring(petUUID), tonumber(slot.Price))
                                    sukses = true
                                end)
                                
                                if sukses then
                                    print("Berhasil memasang pet: " .. petName)
                                    task.wait(slot.Delay)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2) -- Jeda antar putaran antrean
        end
    end)
end

TabMerchant:CreateToggle({
   Name = "🚀 3. MULAI AUTO MERCHANT",
   CurrentValue = false,
   Callback = function(Value)
      isSelling = Value
      if Value then 
         jalankanProsesJual() 
         Rayfield:Notify({Title = "Sistem", Content = "Auto Merchant Aktif!", Duration = 3})
      end
   end,
})

-- ==========================================
-- TAB: TELEPORT
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

TabTeleport:CreateButton({
    Name = "TRAVEL TO TRADE WORLD", 
    Callback = function() 
        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer() 
    end
})

TabTeleport:CreateButton({
    Name = "TRAVEL TO GARDEN", 
    Callback = function() 
        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToMainWorld:FireServer() 
    end
})

TabTeleport:CreateToggle({
   Name = "Auto Travel (Repeat)",
   CurrentValue = true,
   Callback = function(Value) _G.AutoTravel = Value end,
})

-- Background Loop
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer()
            lastTravel = tick()
        end
    end
end)
