local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Detecting Claim Status...",
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
-- TAB 1: SMART CLAIM (IMAGE DETECTOR)
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
   Callback = function(Value)
      _G.AutoClaim = Value
      if Value then startClaimLoop() end
   end,
})

TabClaim:CreateButton({
   Name = "Equip Skin: Default",
   Callback = function()
      game:GetService("ReplicatedStorage").GameEvents.TradeBoothSkinService.Equip:FireServer("Default")
   end,
})

setupDetection()
startClaimLoop()

-- ==========================================
-- TAB 2: AUTO MERCHANT (DYNAMIC QUEUE & CROSS-CHECK)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

local listBawaan = {"Klik Refresh Dulu!"}
local antreanSlots = {} -- Menyimpan data menu yang di-generate
local antreanCounter = 0
local isSelling = false

TabMerchant:CreateButton({
   Name = "🔄 1. Refresh Isi Inventory",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            if not table.find(temp, item.Name) then
               table.insert(temp, item.Name)
            end
         end
      end
      
      if #temp == 0 then table.insert(temp, "Kosong") end
      listBawaan = temp
      
      -- Refresh semua dropdown di antrean yang sudah dibuat
      for _, slot in pairs(antreanSlots) do
         if slot.Dropdown then
            slot.Dropdown:Refresh(listBawaan, {})
         end
      end
      Rayfield:Notify({Title = "Sistem", Content = "Daftar inventory telah diperbarui!", Duration = 3})
   end,
})

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Menu Antrean",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 5, Delay = 5 }
      
      TabMerchant:CreateSection("=== Urutan Antrean #" .. antreanCounter .. " ===")
      
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Item (Bisa > 1 & Search)",
         Options = listBawaan,
         CurrentOption = {},
         MultipleOptions = true, -- MENGIZINKAN PILIH BANYAK
         Flag = "DD_" .. antreanCounter,
         Callback = function(Options)
            slotData.Items = Options
         end,
      })
      
      TabMerchant:CreateInput({
         Name = "Harga Token (Per Item)",
         PlaceholderText = "Misal: 5",
         NumbersOnly = true,
         Callback = function(Text)
            slotData.Price = tonumber(Text) or 5
         end,
      })
      
      TabMerchant:CreateInput({
         Name = "Delay Jual (Detik)",
         PlaceholderText = "Misal: 5",
         NumbersOnly = true,
         Callback = function(Text)
            slotData.Delay = tonumber(Text) or 5
         end,
      })
      
      slotData.Dropdown = dd
      table.insert(antreanSlots, slotData)
   end,
})

-- LOGIKA PENJUALAN DENGAN CROSS-CHECK KETAT
local function mulaiJualan()
    task.spawn(function()
        while isSelling do
            local backpack = player:FindFirstChild("Backpack")
            if not backpack then task.wait(1) continue end
            
            -- Eksekusi berdasarkan urutan antrean yang dibuat
            for i, slot in ipairs(antreanSlots) do
                if not isSelling then break end
                if #slot.Items == 0 then continue end
                
                local harga = slot.Price
                local delay = slot.Delay
                
                -- Untuk setiap item yang dipilih di dropdown tersebut
                for _, itemName in ipairs(slot.Items) do
                    if not isSelling then break end
                    
                    -- Cari item fisik di tas
                    local itemsToSell = {}
                    for _, item in pairs(backpack:GetChildren()) do
                        if item.Name == itemName then
                            table.insert(itemsToSell, item)
                        end
                    end
                    
                    -- Jual satu per satu dari jumlah yang ada
                    for _, itemObj in ipairs(itemsToSell) do
                        if not isSelling then break end
                        
                        local itemID = itemObj:GetAttribute("c")
                        if itemID then
                            local success = false
                            
                            -- STRICT CROSS-CHECK LOOP: Tunggu sampai item beneran masuk booth
                            while not success and isSelling do
                                pcall(function()
                                    game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Holdable", tostring(itemID), harga)
                                end)
                                
                                task.wait(1.5) -- Waktu tunggu loading game
                                
                                -- Pengecekan Fisik: Jika item sudah tidak ada di tas, berarti sukses terlisting
                                if not itemObj.Parent or itemObj.Parent ~= player.Backpack then
                                    success = true
                                end
                            end
                            
                            -- Hanya eksekusi delay jika sukses terlisting
                            if success then
                                task.wait(delay)
                            end
                        end
                    end
                end
            end
            task.wait(2) -- Jeda antar pengulangan antrean besar
        end
    end)
end

TabMerchant:CreateToggle({
   Name = "🚀 3. MULAI AUTO MERCHANT",
   CurrentValue = false,
   Callback = function(Value)
      isSelling = Value
      if Value then mulaiJualan() end
   end,
})

-- ==========================================
-- TAB 3: TELEPORT
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

TabTeleport:CreateButton({Name = "TRAVEL TO TRADE WORLD", Callback = function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end})
TabTeleport:CreateButton({Name = "TRAVEL TO GARDEN", Callback = function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToMainWorld:FireServer() end})

TabTeleport:CreateToggle({
   Name = "Auto Travel (Repeat)",
   CurrentValue = true,
   Callback = function(Value) _G.AutoTravel = Value end,
})

TabTeleport:CreateInput({
   Name = "Jeda (Detik)",
   PlaceholderText = "900",
   CurrentValue = "900",
   Callback = function(Text) _G.TravelDelay = tonumber(Text) or 900 end,
})

task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer()
            lastTravel = tick()
        end
    end
end)
