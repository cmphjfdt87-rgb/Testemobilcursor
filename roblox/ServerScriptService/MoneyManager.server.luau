local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game.ReplicatedStorage:WaitForChild("MoneyConfig"))

local STARTING_MONEY = Config.STARTING_MONEY
local ATTRIBUTE_NAME = Config.ATTRIBUTE_NAME
local LEADERSTAT_NAME = Config.LEADERSTAT_NAME
local USE_DATASTORE = Config.USE_DATASTORE
local DATASTORE_NAME = Config.DATASTORE_NAME

local moneyStore = USE_DATASTORE and DataStoreService:GetDataStore(DATASTORE_NAME) or nil

local function formatMoney(amount: number): string
	return Config.CURRENCY_SYMBOL .. tostring(math.floor(amount))
end

local function createLeaderstats(player: Player): IntValue
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local moneyStat = leaderstats:FindFirstChild(LEADERSTAT_NAME)
	if not moneyStat then
		moneyStat = Instance.new("IntValue")
		moneyStat.Name = LEADERSTAT_NAME
		moneyStat.Parent = leaderstats
	end

	return moneyStat :: IntValue
end

local function setMoney(player: Player, amount: number)
	local value = math.max(0, math.floor(amount))
	player:SetAttribute(ATTRIBUTE_NAME, value)

	local moneyStat = createLeaderstats(player)
	moneyStat.Value = value
end

local function loadMoney(player: Player): number
	if not USE_DATASTORE or not moneyStore then
		return STARTING_MONEY
	end

	local key = "u_" .. player.UserId
	local ok, saved = pcall(function()
		return moneyStore:GetAsync(key)
	end)

	if ok and typeof(saved) == "number" then
		return saved
	end

	return STARTING_MONEY
end

local function saveMoney(player: Player)
	if not USE_DATASTORE or not moneyStore then
		return
	end

	local amount = player:GetAttribute(ATTRIBUTE_NAME)
	if typeof(amount) ~= "number" then
		return
	end

	local key = "u_" .. player.UserId
	pcall(function()
		moneyStore:SetAsync(key, amount)
	end)
end

local function onPlayerAdded(player: Player)
	local money = loadMoney(player)
	setMoney(player, money)

	player:GetAttributeChangedSignal(ATTRIBUTE_NAME):Connect(function()
		local stat = player:FindFirstChild("leaderstats")
		if stat then
			local moneyStat = stat:FindFirstChild(LEADERSTAT_NAME)
			if moneyStat and moneyStat:IsA("IntValue") then
				local attr = player:GetAttribute(ATTRIBUTE_NAME)
				if typeof(attr) == "number" then
					moneyStat.Value = attr
				end
			end
		end
	end)
end

local function onPlayerRemoving(player: Player)
	saveMoney(player)
end

-- Public API for other server scripts (shops, rewards, etc.)
local MoneyManager = {}

function MoneyManager.GetMoney(player: Player): number
	local amount = player:GetAttribute(ATTRIBUTE_NAME)
	if typeof(amount) == "number" then
		return amount
	end
	return 0
end

function MoneyManager.SetMoney(player: Player, amount: number)
	setMoney(player, amount)
end

function MoneyManager.AddMoney(player: Player, amount: number)
	setMoney(player, MoneyManager.GetMoney(player) + amount)
end

function MoneyManager.RemoveMoney(player: Player, amount: number): boolean
	local current = MoneyManager.GetMoney(player)
	if current < amount then
		return false
	end
	setMoney(player, current - amount)
	return true
end

function MoneyManager.Format(amount: number): string
	return formatMoney(amount)
end

_G.MoneyManager = MoneyManager

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		saveMoney(player)
	end
end)
