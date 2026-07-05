# Ninebot Companion — application iPhone native

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
