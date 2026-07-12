-- Shared money settings (Server + Client)
return {
	STARTING_MONEY = 5000,
	CURRENCY_SYMBOL = "$",
	ATTRIBUTE_NAME = "Money",
	LEADERSTAT_NAME = "Money",

	-- Set false to give STARTING_MONEY every join (no save between sessions)
	USE_DATASTORE = true,
	DATASTORE_NAME = "PlayerMoney_v1",

	-- Client UI: names of TextLabels to update (first match wins)
	LABEL_NAMES = {
		"MoneyLabel",
		"Money",
		"Cash",
		"Argent",
		"Coins",
		"MoneyText",
	},

	-- Optional: exact ScreenGui name in PlayerGui (nil = search all GUIs)
	SCREEN_GUI_NAME = nil,
}
