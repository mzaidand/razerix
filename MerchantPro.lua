local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zaylinho Merchant Pro 2026",
   LoadingTitle = "Menyiapkan Akses Pet...",
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
local listPetBawaan = {} -- Database nama pet asli

-- ==========================================
-- TAB: AUTO MERCHANT (FIXED SEARCH)
-- ==========================================
local TabMerchant = Window:CreateTab("Auto Merchant", 4483362458)

TabMerchant:CreateButton({
   Name = "🔄 1. Refresh Inventory (Khusus Pet)",
   Callback = function()
      local temp = {}
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         for _, item in pairs(backpack:GetChildren()) do
            -- Filter hanya untuk item tipe "Pet"
            local itemType = item:GetAttribute("ItemType") or item:GetAttribute("PetType")
            if itemType == "Pet" then
               if not table.find(temp, item.Name) then 
                  table.insert(temp, item.Name) 
               end
            end
         end
      end
      listPetBawaan = temp
      Rayfield:Notify({Title = "Sistem", Content = #listPetBawaan .. " Pet Berhasil Dimuat!", Duration = 3})
   end,
})

local antreanSlots = {}
local antreanCounter = 0
local isSelling = false

TabMerchant:CreateButton({
   Name = "➕ 2. Tambah Antrean Jual",
   Callback = function()
      antreanCounter = antreanCounter + 1
      local slotData = { Items = {}, Price = 2, Delay = 5 }
      TabMerchant:CreateSection("Urutan Antrean #" .. antreanCounter)
      
      -- DROPDOWN UTAMA
      local dd = TabMerchant:CreateDropdown({
         Name = "Pilih Pet (Hasil Search)",
         Options = listPetBawaan,
         CurrentOption = {},
         MultipleOptions = true,
         Flag = "Slot_" .. antreanCounter,
         Callback = function(Options) slotData.Items = Options end,
      })

      -- FITUR SEARCH MANUAL
      TabMerchant:CreateInput({
         Name = "🔍 Cari Nama Pet (Contoh: Peacock)",
         PlaceholderText = "Ketik di sini untuk menyaring list...",
         NumbersOnly = false,
         Callback = function(Text)
            local query = string.lower(Text)
            local filtered = {}
            
            -- Mencari nama pet yang mengandung kata kunci
            for _, name in pairs(listPetBawaan) do
               if string.find(string.lower(name), query) then
                  table.insert(filtered, name)
               end
            end
            
            -- Refresh dropdown dengan hasil filter
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
         PlaceholderText = "3",
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

-- LOGIKA PENJUALAN OTOMATIS
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
                        -- Cek kecocokan nama pet
                        if itemObj.Name == petName and isSelling then
                            -- Ambil UUID sesuai screenshot atribut
                            local petUUID = itemObj:GetAttribute("PET_UUID") 
                            
                            if petUUID then
                                pcall(function()
                                    -- Format InvokeServer sesuai SimpleSpy
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
            task.wait(2)
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

-- Tambahkan Tab Teleport di bawah sini sesuai script lamamu
