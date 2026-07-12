-- ServerScriptService > Script "Money"
-- Donne 5000$ à chaque joueur à l'arrivée

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local START_MONEY = 5000
local store = DataStoreService:GetDataStore("Money_v1")

local function setup(player)
	local money = START_MONEY

	local ok, saved = pcall(function()
		return store:GetAsync("p_" .. player.UserId)
	end)
	if ok and typeof(saved) == "number" then
		money = saved
	end

	player:SetAttribute("Money", money)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Money"
	cash.Value = money
	cash.Parent = stats

	player:GetAttributeChangedSignal("Money"):Connect(function()
		cash.Value = player:GetAttribute("Money") or 0
	end)
end

local function save(player)
	local m = player:GetAttribute("Money")
	if typeof(m) == "number" then
		pcall(function()
			store:SetAsync("p_" .. player.UserId, m)
		end)
	end
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(save)

for _, p in Players:GetPlayers() do
	setup(p)
end

_G.MoneyManager = {
	Get = function(plr) return plr:GetAttribute("Money") or 0 end,
	Add = function(plr, n)
		plr:SetAttribute("Money", (plr:GetAttribute("Money") or 0) + n)
	end,
	Remove = function(plr, n)
		local cur = plr:GetAttribute("Money") or 0
		if cur < n then return false end
		plr:SetAttribute("Money", cur - n)
		return true
	end,
}
