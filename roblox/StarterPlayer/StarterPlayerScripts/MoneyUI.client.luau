local Players = game:GetService("Players")

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
