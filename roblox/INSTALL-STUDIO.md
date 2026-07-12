# Système d'argent Roblox — installation dans Studio

Chaque joueur reçoit **5000$** à sa première arrivée. L'argent est sauvegardé (DataStore) entre les sessions.

## Installation rapide (1 clic)

1. **ServerScriptService** → Insert Object → **Script** → nomme-le `InstallMoneySystem`
2. Ouvre `roblox/InstallMoneySystem.server.luau` et **colle tout** dans le script
3. Appuie sur **Play (F5)** une fois
4. Le script crée tout automatiquement puis se supprime
5. Renomme ton TextLabel d'argent en **`Money`** ou **`Argent`**
6. Relance **Play** — tu dois voir **$5000**

## Installation manuelle (alternative)

| Fichier source | Où le mettre dans Studio |
|---|---|
| `ReplicatedStorage/MoneyConfig.luau` | **ReplicatedStorage** → ModuleScript `MoneyConfig` |
| `ServerScriptService/MoneyManager.server.luau` | **ServerScriptService** → Script `MoneyManager` |
| `StarterPlayer/StarterPlayerScripts/MoneyUI.client.luau` | **StarterPlayerScripts** → LocalScript `MoneyUI` |

## 2. Lier ton UI existante

Le client cherche un **TextLabel** ou **TextButton** nommé :

- `MoneyLabel`
- `Money`
- `Cash`
- `Argent`
- `Coins`
- `MoneyText`

Renomme ton label d'argent avec un de ces noms (ex. `Money` ou `Argent`).

## 3. Activer la sauvegarde (publié)

Dans **Game Settings → Security** :

- **Enable Studio Access to API Services** = ON (pour tester DataStore en Studio)
- Publie le jeu pour que la sauvegarde fonctionne en production

## 4. Options dans MoneyConfig

```lua
STARTING_MONEY = 5000,   -- argent de départ
USE_DATASTORE = true,    -- false = 5000$ à chaque reconnexion
CURRENCY_SYMBOL = "$",
```

## 5. Utiliser depuis d'autres scripts (serveur)

```lua
local MoneyManager = _G.MoneyManager

MoneyManager.AddMoney(player, 100)      -- +100$
MoneyManager.RemoveMoney(player, 50)    -- -50$ (retourne false si pas assez)
MoneyManager.GetMoney(player)
MoneyManager.SetMoney(player, 5000)
```
