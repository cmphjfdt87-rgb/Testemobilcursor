# Ninebot Companion — application iPhone native

> **Tu veux juste ouvrir l'app sur ton iPhone sans rien configurer ?**
> Lis **[OUVRE-MOI.md](OUVRE-MOI.md)** — 3 gestes, Bluefy + Bluetooth.
> URL directe : `https://auric-bit-3e3n82h.shipstatic.com`

Application iOS **native** (SwiftUI + CoreBluetooth) pour se connecter en Bluetooth
à une trottinette **Ninebot / Xiaomi** que vous possédez, afficher sa télémétrie
en temps réel, changer de **région** et ajuster les **réglages** (vitesse,
régulateur, feux).

Ce n'est pas une web-app : c'est un vrai projet Xcode qui produit un `.app`
installable sur iPhone.

---

## ⚠️ À lire avant tout

- **Compilation & installation sur iPhone** : Apple impose un **Mac avec Xcode**
  et un **compte développeur Apple** (gratuit pour installer sur son propre
  appareil, payant pour l'App Store). Aucun environnement Linux/cloud ne peut
  compiler ni signer une app iOS — c'est une contrainte d'Apple.
- **Aucune app ne « débride tous les Ninebot sur tous les firmwares ».** Les
  modèles récents (Max G30 et suivants) utilisent un protocole BLE **chiffré**
  dont la clé de session diffère selon le firmware. Ce projet fournit une
  **couche protocole propre et extensible** (voir `NinebotCrypto`) plutôt qu'un
  faux exploit universel qui prétendrait fonctionner.
- **Légalité & sécurité** : retirer le limiteur de vitesse rend généralement la
  trottinette **non homologuée pour la voie publique** (plafond légal 25 km/h en
  France/UE), peut **annuler la garantie** et l'assurance. À utiliser sur
  **terrain privé** et sous votre responsabilité.

---

## Fonctionnalités

- 🔍 **Scan Bluetooth** et connexion via le service Nordic UART.
- 📊 **Tableau de bord temps réel** : vitesse, batterie, tension, distance,
  température, n° de série, firmware.
- 🌍 **Changement de région** (Global / US / Europe / Chine) avec relecture de
  confirmation.
- 🎚️ **Réglages** : vitesse maximale, régulateur de vitesse, feu arrière
  (verrouillés derrière une confirmation de risques).
- 📝 **Journal** des échanges pour le diagnostic.

## Modèles ciblés

| Famille | Protocole | État |
|---|---|---|
| Xiaomi M365 / 1S / Pro / Pro 2 | Texte clair | Lecture/écriture opérationnelles |
| Ninebot ES1/ES2/ES4 | Texte clair | Lecture/écriture opérationnelles |
| Ninebot Max G30 | Chiffré (AES) | Couche crypto à compléter/valider |
| Ninebot F-series, Max G2/GT | Chiffré (AES) | Couche crypto à compléter/valider |

## Compiler et installer

1. Ouvrir `NinebotCompanion.xcodeproj` dans **Xcode 16+** (macOS).
2. Onglet *Signing & Capabilities* → choisir votre *Team* et un
   `Bundle Identifier` unique (ex. `com.votrenom.NinebotCompanion`).
3. Brancher l'iPhone, le sélectionner comme destination, puis **Run** (`⌘R`).
4. Sur l'iPhone : *Réglages → Général → VPN et gestion → faire confiance* au
   profil développeur si demandé.

> iOS 17.0 minimum.

### Installer sans PC / sans App Store

Pas de Mac ? Voir **[INSTALL-SANS-PC.md](INSTALL-SANS-PC.md)** : compilation sur
un Mac cloud (workflow GitHub Actions inclus) puis installation via **TestFlight**
ou **AltStore PAL** (UE), le tout piloté depuis le navigateur de l'iPhone.

## Version web gratuite (sans PC, sans compte) — dossier `web/`

Pour un usage **immédiat, gratuit et sans PC**, une console **Web Bluetooth**
(« NBX Console ») est disponible dans `web/` (`index.html`, entièrement
autonome). Elle contrôle réellement la trottinette et s'ouvre dans le navigateur
**Bluefy** sur iPhone (gratuit sur l'App Store) — Safari ne gère pas le
Bluetooth web.

Interface soignée (jauge animée, thème sombre monochrome), détection auto du
protocole, et **support expérimental du protocole chiffré Ninebot** (E-series /
Max) : portage JavaScript de `scooterhacking/NinebotCrypto` (AES-128 + SHA-1,
vecteurs FIPS-197 / SHA-1 validés, appairage PRE_COMM/SET_PWD/AUTH). La lecture
de télémétrie chiffrée est tentée automatiquement ; l'**écriture** (débridage)
reste bloquée par le firmware sur E-series récents (downgrade requis via
ScooterHacking Utility, Android).

1. Active GitHub Pages : *Settings → Pages → Source = GitHub Actions* (le
   workflow `deploy-pages.yml` publie le dossier `web/`).
2. Sur l'iPhone, installe **Bluefy** depuis l'App Store.
3. Ouvre l'URL Pages (`https://<utilisateur>.github.io/<depot>/`) dans Bluefy.
4. Appuie sur *Connecter ma trottinette*, sélectionne-la, c'est prêt.

Limite : les modèles récents chiffrés (Max G30+) ne sont pas gérés par la
version web ; ils nécessitent l'app native + la couche `NinebotCrypto`.

## Architecture

```
NinebotCompanion/
├── App/            Point d'entrée SwiftUI + navigation
├── Models/         État de la trottinette, régions, modèles
├── Bluetooth/      CoreBluetooth + protocole série Ninebot/Xiaomi
│   ├── BluetoothManager.swift   Scan, connexion, boucle read/write
│   ├── NinebotProtocol.swift    Trame 0x5A 0xA5, checksum, parsing
│   ├── NinebotRegisters.swift   Adresses de registres documentées
│   └── NinebotCrypto.swift      Seam de chiffrement (familles récentes)
└── Views/          Scan, Dashboard, Région, Réglages, Infos
```

### Étendre à un firmware chiffré

1. Capturez la poignée de main BLE de l'app officielle pour votre modèle.
2. Implémentez `encrypt`/`decrypt` dans une conformité à `NinebotCrypto`
   (voir `AESPlaceholderCrypto`) avec le mode/IV/MAC vérifiés.
3. Injectez-la dans `BluetoothManager`.

Le reste de l'app (UI, registres, télémétrie) fonctionne sans modification.

### Vérifier les registres

Les adresses de `NinebotRegisters` sont celles documentées par la communauté
open-source (m365 / ScooterHacking) pour les familles M365/ES. Sur un modèle
inconnu, **lisez toujours un registre avant d'y écrire** pour confirmer sa
signification.

## Avertissement

Ce logiciel est fourni « en l'état », à des fins de diagnostic et de
configuration d'un matériel que vous possédez. Les auteurs déclinent toute
responsabilité en cas de dommage matériel, perte de garantie ou usage non
conforme à la législation locale.
