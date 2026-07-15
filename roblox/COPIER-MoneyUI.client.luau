-- StarterPlayer > StarterPlayerScripts > LocalScript "MoneyUI"
-- Met à jour ton UI automatiquement

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local labels = {}

local function isMoneyLabel(obj)
	if not obj:IsA("TextLabel") and not obj:IsA("TextButton") then
		return false
	end
	local n = string.lower(obj.Name)
	return n == "money"
		or n == "argent"
		or n == "cash"
		or n == "coins"
		or n == "moneylabel"
		or n == "moneytext"
		or string.find(n, "money")
		or string.find(n, "argent")
		or string.find(n, "cash")
end

local function scan(root)
	for _, d in root:GetDescendants() do
		if isMoneyLabel(d) then
			table.insert(labels, d)
		end
	end
end

local function refresh()
	local m = player:GetAttribute("Money") or 0
	local txt = "$" .. tostring(m)
	for _, lbl in labels do
		if lbl.Parent then
			lbl.Text = txt
		end
	end
end

local function onGui(child)
	if child:IsA("ScreenGui") then
		scan(child)
		refresh()
	end
end

for _, c in gui:GetChildren() do
	onGui(c)
end
gui.ChildAdded:Connect(onGui)

player:GetAttributeChangedSignal("Money"):Connect(refresh)
refresh()

if #labels == 0 then
	warn("[MoneyUI] Label introuvable! Renomme ton TextLabel en 'Money' ou 'Argent'")
end
