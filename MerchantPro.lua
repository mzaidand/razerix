local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Detecting Claim Status...",
   LoadingSubtitle = "by Zaylinho",
   ConfigurationSaving = { Enabled = false },
})

-- Variabel Global
_G.HargaJual = 2
_G.AutoTravel = true
_G.TravelDelay = 900
_G.AutoClaim = true 
_G.StopClaiming = false 
local lastTravel = tick()
local player = game.Players.LocalPlayer

-- ==========================================
-- TAB 1: SMART CLAIM (IMAGE DETECTOR LOGIC)
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
-- TAB 2: AUTO MERCHANT (SISTEM ANTREAN DINAMIS)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

local antreanJual = {}
local itemTerpilih = ""
local delayTerpilih = 5
local isSelling = false

local StatusAntrean = TabMerchant:CreateLabel("Daftar Antrean:\nKosong")

local DropdownItem = TabMerchant:CreateDropdown({
   Name = "Pilih Item (Dari Inventory)",
   Options = {"Klik Refresh Dulu!"},
   CurrentOption = {"Klik Refresh Dulu!"},
   MultipleOptions = false,
   Flag = "DropdownItem",
   Callback = function(Options)
      itemTerpilih = Options[1]
   end,
})

TabMerchant:CreateButton({
   Name = "🔄 Refresh Isi Inventory",
   Callback = function()
      local listBawaan = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            local namaItem = item.Name
            -- Hindari memasukkan nama yang sama berkali-kali ke dropdown
            if not table.find(listBawaan, namaItem) then
               table.insert(listBawaan, namaItem)
            end
         end
      end
      
      if #listBawaan == 0 then table.insert(listBawaan, "Inventory Kosong") end
      DropdownItem:Refresh(listBawaan, {listBawaan[1]})
      itemTerpilih = listBawaan[1]
      Rayfield:Notify({Title = "Berhasil", Content = "Daftar inventory telah diperbarui!", Duration = 3})
   end,
})

TabMerchant:CreateInput({
   Name = "Delay Jual (Detik)",
   PlaceholderText = "5",
   CurrentValue = "5",
   Numeric = true,
   Callback = function(Text)
      delayTerpilih = tonumber(Text) or 5
   end,
})

local function perbaruiLabelAntrean()
    if #antreanJual == 0 then
        StatusAntrean:Set("Daftar Antrean:\nKosong")
    else
        local teks = "Daftar Antrean:\n"
        for i, data in ipairs(antreanJual) do
            teks = teks .. i .. ". " .. data.Item .. " (" .. data.Delay .. "s)\n"
        end
        StatusAntrean:Set(teks)
    end
end

TabMerchant:CreateButton({
   Name = "➕ Tambah ke Antrean",
   Callback = function()
      if itemTerpilih ~= "" and itemTerpilih ~= "Klik Refresh Dulu!" and itemTerpilih ~= "Inventory Kosong" then
         table.insert(antreanJual, {Item = itemTerpilih, Delay = delayTerpilih})
         perbaruiLabelAntrean()
      else
         Rayfield:Notify({Title = "Gagal", Content = "Pilih item yang valid dulu!", Duration = 3})
      end
   end,
})

TabMerchant:CreateButton({
   Name = "🗑️ Hapus Semua Antrean",
   Callback = function()
      antreanJual = {}
      perbaruiLabelAntrean()
   end,
})

local function mulaiJualan()
    task.spawn(function()
        while isSelling do
            if #antreanJual > 0 then
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    -- Looping mengecek daftar antrean yang kita buat
                    for _, tugas in ipairs(antreanJual) do
                        if not isSelling then break end
                        
                        local targetNama = tugas.Item
                        local waktuTunggu = tugas.Delay
                        
                        -- Cari item di backpack yang sesuai dengan target antrean
                        for _, item in pairs(backpack:GetChildren()) do
                            if not isSelling then break end
                            
                            if item.Name == targetNama then
                                local itemID = item:GetAttribute("c")
                                if itemID then
                                    pcall(function()
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Holdable", tostring(itemID), _G.HargaJual)
                                    end)
                                    task.wait(waktuTunggu) -- Tunggu sesuai delay yang disetting untuk item ini
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2) -- Jeda loop utama agar game tidak crash
        end
    end)
end

TabMerchant:CreateToggle({
   Name = "Mulai Auto Merchant",
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
