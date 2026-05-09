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
_G.TravelDelay = 3600
_G.AutoClaim = true 
_G.StopClaiming = false -- Variabel kunci untuk stop spam
local lastTravel = tick()
local player = game.Players.LocalPlayer

-- ==========================================
-- TAB 1: SMART CLAIM (IMAGE DETECTOR LOGIC)
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

-- Fungsi untuk mendeteksi notifikasi "You already have a booth"
local function setupDetection()
    -- Mendeteksi UI baru yang muncul di layar
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            -- Cek apakah teksnya mengandung kata kunci dari gambar
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
            -- Jika detektor sudah menemukan teks "Already have a booth", loop berhenti menembak server
            if not _G.StopClaiming then
                local boothFolder = workspace:FindFirstChild("TradeWorld") and workspace.TradeWorld:FindFirstChild("Booths")
                if boothFolder then
                    for _, booth in pairs(boothFolder:GetChildren()) do
                        if _G.StopClaiming or not _G.AutoClaim then break end
                        
                        -- Cek apakah booth kosong
                        if not booth:GetAttribute("Owner") or booth:GetAttribute("Owner") == 0 then
                            pcall(function()
                                game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.ClaimBooth:FireServer(booth)
                            end)
                            task.wait(0.1) -- Delay tipis saat mencari
                        end
                    end
                end
            end
            task.wait(1) -- Cek status setiap detik
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

-- Jalankan sistem deteksi dan loop
setupDetection()
startClaimLoop()

-- ==========================================
-- TAB 2: AUTO MERCHANT
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

TabMerchant:CreateButton({
   Name = "PAJANG SEMUA BONE BLOSSOM (Delay 5s)",
   Callback = function()
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            local itemName = tostring(item:GetAttribute("f"))
            local itemID = item:GetAttribute("c")
            if string.find(itemName, "Bone Blossom") and itemID then
               game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer("Holdable", tostring(itemID), _G.HargaJual)
               task.wait(5)
            end
         end
      end
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
   PlaceholderText = "3600",
   CurrentValue = "3600",
   Callback = function(Text) _G.TravelDelay = tonumber(Text) or 3600 end,
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