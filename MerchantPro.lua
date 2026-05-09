local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho World Teleport", -- Nama asli sesuai file kamu
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
local listPetBawaan = {} -- Database untuk Auto Merchant

-- ==========================================
-- TAB: SMART CLAIM (TETAP ASLI)
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
-- TAB: AUTO MERCHANT (HANYA INI YANG DIUBAH)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

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
            -- Filter PET_UUID dan ItemType Pet
            if item:GetAttribute("ItemType") == "Pet" or item:GetAttribute("PET_UUID") then
               if not table.find(temp, item.Name) then 
                  table.insert(temp, item.Name) 
               end
            end
         end
      end
      listPetBawaan = temp
      Rayfield:Notify({Title = "Sistem", Content = #listPetBawaan .. " Pet Terdeteksi!", Duration = 3})
   end,
})

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabMerchant:CreateSection("Urutan Antrean #" .. antreanCounter)
      
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Pet",
         Options = listPetBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Flag = "Slot_" .. antreanCounter,
         Callback = function(Options) slotData.Items = Options end,
      })

      TabMerchant:CreateInput({
         Name = "🔍 Cari Pet",
         PlaceholderText = "Ketik nama pet...",
         NumbersOnly = false,
         Callback = function(Text)
            local query = string.lower(Text)
            local filtered = {}
            for _, name in pairs(listPetBawaan) do
               if string.find(string.lower(name), query) then table.insert(filtered, name) end
            end
            dd:Refresh(filtered, true)
         end,
      })
      
      TabMerchant:CreateInput({
         Name = "Harga",
         PlaceholderText = "2",
         NumbersOnly = true,
         Callback = function(Text) slotData.Price = tonumber(Text) or 2 end,
      })
      
      TabMerchant:CreateInput({
         Name = "Jeda",
         PlaceholderText = "5",
         NumbersOnly = true,
         Callback = function(Text) slotData.Delay = tonumber(Text) or 5 end,
      })
      
      table.insert(antreanSlots, slotData)
   end,
})

local function jalankanJual()
    task.spawn(function()
        while isSelling do
            for _, slot in ipairs(antreanSlots) do
                if not isSelling then break end
                for _, petName in ipairs(slot.Items) do
                    if not isSelling then break end
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        for _, item in pairs(backpack:GetChildren()) do
                            if item.Name == petName and isSelling then
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

TabMerchant:CreateToggle({
   Name = "🚀 MULAI AUTO MERCHANT",
   CurrentValue = false,
   Callback = function(Value)
      isSelling = Value
      if Value then jalankanJual() end
   end,
})

-- ==========================================
-- TAB: TELEPORT (TETAP ASLI)
-- ==========================================
local TabTeleport = Window:CreateTab("Teleport", 4483362458)

TabTeleport:CreateButton({
   Name = "TRAVEL TO TRADE WORLD",
   Callback = function()
      game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer()
   end,
})

TabTeleport:CreateButton({
   Name = "TRAVEL TO MAIN WORLD",
   Callback = function()
      game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToMainWorld:FireServer()
   end,
})

TabTeleport:CreateToggle({
   Name = "Auto Travel (Repeat)",
   CurrentValue = true,
   Callback = function(Value) _G.AutoTravel = Value end,
})

-- [[ LOGIKA BACKGROUND TETAP ASLI ]]
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoTravel and tick() - lastTravel >= _G.TravelDelay then
            game:GetService("ReplicatedStorage").GameEvents.TradeEvents.TravelToTradeWorld:FireServer()
            lastTravel = tick()
        end
    end
end)

local vu = game:GetService("VirtualUser")
player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
