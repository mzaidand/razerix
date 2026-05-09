local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Mengintegrasikan Data SimpleSpy...",
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
-- TAB 1: SMART CLAIM
-- ==========================================
local TabClaim = Window:CreateTab("Smart Claim", 4483362458)

local function setupDetection()
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if string.find(string.lower(obj.Text), "already have a booth") then
                _G.StopClaiming = true
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
-- TAB 2: AUTO MERCHANT (FIXED BY SIMPLESPY)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

local listBawaan = {"Refresh Dulu!"}
local antreanSlots = {} 
local antreanCounter = 0
local isSelling = false

TabMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory",
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
      listBawaan = temp
      for _, slot in pairs(antreanSlots) do
         if slot.Dropdown then slot.Dropdown:Refresh(listBawaan, {}) end
      end
      Rayfield:Notify({Title = "Sistem", Content = "Inventory Terbaca!", Duration = 3})
   end,
})

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Baru",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      
      TabMerchant:CreateSection("Urutan Antrean #" .. antreanCounter)
      
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Item (Search & Multi)",
         Options = listBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Flag = "Slot_" .. antreanCounter,
         Callback = function(Options) slotData.Items = Options end,
      })
      
      TabMerchant:CreateInput({
         Name = "Harga Token",
         PlaceholderText = "Default: 2",
         NumbersOnly = true,
         Callback = function(Text) slotData.Price = tonumber(Text) or 2 end,
      })
      
      TabMerchant:CreateInput({
         Name = "Jeda Jual (Detik)",
         PlaceholderText = "Default: 5",
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
                
                for _, itemName in ipairs(slot.Items) do
                    if not isSelling then break end
                    
                    local backpack = player:FindFirstChild("Backpack")
                    if not backpack then break end
                    
                    for _, itemObj in pairs(backpack:GetChildren()) do
                        if itemObj.Name == itemName and isSelling then
                            -- MENGAMBIL ID UUID SESUAI SIMPLESPY (Contoh: {0918d8ef...})
                            local itemID = itemObj:GetAttribute("c") or itemObj:GetAttribute("ID")
                            
                            if itemID then
                                local terpasang = false
                                
                                while not terpasang and isSelling do
                                    pcall(function()
                                        -- FORMAT BARU SESUAI LOG SIMPLESPY
                                        game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer(
                                            "Pet", 
                                            tostring(itemID), 
                                            tonumber(slot.Price)
                                        )
                                    end)
                                    
                                    task.wait(2) -- Memberi waktu server memproses
                                    
                                    -- Cross-check fisik
                                    if not itemObj.Parent or itemObj.Parent ~= player.Backpack then
                                        terpasang = true
                                        Rayfield:Notify({Title = "Sukses", Content = itemName .. " Terpasang!", Duration = 2})
                                    end
                                end
                                
                                if terpasang then task.wait(slot.Delay) end
                            end
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

TabMerchant:CreateToggle({
   Name = "🚀 3. MULAI AUTO MERCHANT",
   CurrentValue = false,
   Callback = function(Value)
      isSelling = Value
      if Value then jalankanProsesJual() end
   end,
})

-- ==========================================
-- TAB 3: TELEPORT
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)
TabTeleport:CreateButton({Name = "TRAVEL TO TRADE WORLD", Callback = function() game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer() end})

task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            game:GetService("ReplicatedStorage").GameEvents.TradeWorld.TravelToTradeWorld:FireServer()
            lastTravel = tick()
        end
    end
end)
