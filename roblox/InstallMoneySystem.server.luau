--[[
  INSTALLATION EN 1 CLIC — Roblox Studio

  1. ServerScriptService → Insert Object → Script → nomme-le "InstallMoneySystem"
  2. Colle TOUT ce fichier dans le script
  3. Appuie sur Play (F5) une seule fois
  4. Le script crée MoneyConfig, MoneyManager et MoneyUI puis se supprime
  5. Renomme ton TextLabel d'argent en "Money" ou "Argent"
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local SOURCES = {
	MoneyConfig = [=[-- Shared money settings (Server + Client)
return {
	STARTING_MONEY = 5000,
	CURRENCY_SYMBOL = "$",
	ATTRIBUTE_NAME = "Money",
	LEADERSTAT_NAME = "Money",
	USE_DATASTORE = true,
	DATASTORE_NAME = "PlayerMoney_v1",
	LABEL_NAMES = {
		"MoneyLabel",
		"Money",
		"Cash",
		"Argent",
		"Coins",
		"MoneyText",
	},
	SCREEN_GUI_NAME = nil,
}
]=],

	MoneyManager = [=[local Players = game:GetService("Players")
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
]=],

	MoneyUI = [=[local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(game.ReplicatedStorage:WaitForChild("MoneyConfig"))

local ATTRIBUTE_NAME = Config.ATTRIBUTE_NAME
local LABEL_NAMES = Config.LABEL_NAMES
local SCREEN_GUI_NAME = Config.SCREEN_GUI_NAME

local connectedLabels: { TextLabel | TextButton } = {}

local function formatMoney(amount: number): string
	return Config.CURRENCY_SYMBOL .. tostring(math.floor(amount))
end

local function isMoneyLabel(instance: Instance): boolean
	if not (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
		return false
	end

	for _, name in LABEL_NAMES do
		if instance.Name == name then
			return true
		end
	end

	return false
end

local function findMoneyLabels(root: Instance): { TextLabel | TextButton }
	local found = {}

	for _, descendant in root:GetDescendants() do
		if isMoneyLabel(descendant) then
			table.insert(found, descendant)
		end
	end

	return found
end

local function refreshLabelText()
	local money = player:GetAttribute(ATTRIBUTE_NAME)
	if typeof(money) ~= "number" then
		money = 0
	end

	local text = formatMoney(money)
	for _, label in connectedLabels do
		if label.Parent then
			label.Text = text
		end
	end
end

local function bindGui(screenGui: ScreenGui)
	if SCREEN_GUI_NAME and screenGui.Name ~= SCREEN_GUI_NAME then
		return
	end

	local labels = findMoneyLabels(screenGui)
	for _, label in labels do
		local alreadyBound = false
		for _, existing in connectedLabels do
			if existing == label then
				alreadyBound = true
				break
			end
		end

		if not alreadyBound then
			table.insert(connectedLabels, label)
		end
	end

	refreshLabelText()
end

local function scanAllGuis()
	connectedLabels = {}

	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") then
			bindGui(child)
		end
	end

	if #connectedLabels == 0 then
		warn(
			"[MoneyUI] Aucun TextLabel trouvé. Renomme ton label en un de ces noms: "
				.. table.concat(LABEL_NAMES, ", ")
		)
	end
end

playerGui.ChildAdded:Connect(function(child)
	if child:IsA("ScreenGui") then
		task.defer(function()
			bindGui(child)
		end)
	end
end)

player:GetAttributeChangedSignal(ATTRIBUTE_NAME):Connect(refreshLabelText)

scanAllGuis()
refreshLabelText()
]=],
}

local function upsertScript(parent: Instance, name: string, className: string, source: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local script = Instance.new(className)
	script.Name = name
	script.Source = source
	script.Parent = parent
	return script
end

print("[InstallMoneySystem] Installation du système d'argent...")

upsertScript(ReplicatedStorage, "MoneyConfig", "ModuleScript", SOURCES.MoneyConfig)
upsertScript(ServerScriptService, "MoneyManager", "Script", SOURCES.MoneyManager)
upsertScript(StarterPlayerScripts, "MoneyUI", "LocalScript", SOURCES.MoneyUI)

print("[InstallMoneySystem] OK — MoneyConfig, MoneyManager, MoneyUI créés.")
print("[InstallMoneySystem] Renomme ton label UI en 'Money' ou 'Argent', puis relance Play.")

script:Destroy()
