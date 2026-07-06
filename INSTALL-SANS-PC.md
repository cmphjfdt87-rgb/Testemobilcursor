# Installer l'app sur iPhone sans PC (et sans App Store)

## Le principe à comprendre

Le code Swift **doit être compilé par un Mac**. C'est une règle d'Apple, on ne
peut pas la contourner. Mais ce Mac peut être un **Mac dans le cloud** : tu ne
possèdes aucun ordinateur, tu pilotes tout depuis le navigateur de ton iPhone.

Il y a donc deux étapes :
1. **Compiler dans le cloud** (Mac distant).
2. **Installer sur l'iPhone sans App Store** (TestFlight ou AltStore PAL).

---

## Option A — TestFlight (recommandée, marche partout)

TestFlight est l'outil officiel d'Apple pour distribuer une app en test **sans
la publier sur l'App Store**. Une fois l'app envoyée, tu l'installes sur
l'iPhone avec la seule app **TestFlight** — aucun PC.

**Ce qu'il faut :** un **compte Apple Developer payant (99 $/an)**. C'est la
seule contrainte, mais c'est de loin la voie la plus simple et stable.

### Étapes (tout depuis le navigateur du téléphone)

1. Ce dépôt contient déjà un workflow GitHub Actions
   (`.github/workflows/ios-build.yml`) qui compile sur un Mac cloud gratuit.
2. Crée un compte sur [developer.apple.com](https://developer.apple.com) (99 $/an).
3. Dans **App Store Connect → Users and Access → Integrations**, crée une **clé
   API** (App Store Connect API Key). Note le *Key ID*, l'*Issuer ID* et
   télécharge le fichier `.p8`.
4. Dans GitHub → ton dépôt → **Settings → Secrets and variables → Actions**,
   ajoute trois secrets :
   - `ASC_KEY_ID` = le Key ID
   - `ASC_ISSUER_ID` = l'Issuer ID
   - `ASC_KEY_P8` = tout le contenu du fichier `.p8`
5. Relance le workflow (onglet **Actions → Build iOS app → Run workflow**). Le
   job `testflight` archive, signe et envoie automatiquement le build.
6. Sur l'iPhone : installe l'app **TestFlight** depuis l'App Store, connecte-toi
   avec ton Apple ID, et l'app apparaît prête à installer.

> Astuce : tu peux tout faire depuis Safari sur l'iPhone (GitHub, App Store
> Connect). Aucun ordinateur nécessaire.

---

## Option B — AltStore PAL (Europe uniquement, sans compte payant)

Depuis iOS 17.4, dans l'**Union européenne**, Apple autorise les magasins
alternatifs. **AltStore PAL** s'installe directement sur l'iPhone **sans PC** et
permet d'installer une app `.ipa` **hors App Store**.

**Ce qu'il faut :** être dans l'UE (France OK) + iOS 17.4 ou plus.

### Étapes

1. Il faut d'abord obtenir un fichier `.ipa` **signé**. Le plus simple sans PC :
   un service de build cloud comme [Codemagic](https://codemagic.io) ou
   [GitHub Actions](.github/workflows/ios-build.yml) qui produit l'`.ipa`
   (nécessite quand même un Apple ID pour la signature).
2. Sur l'iPhone, installe **AltStore PAL** depuis
   [altstore.io](https://altstore.io) (dispo en UE, iOS 17.4+).
3. Ouvre l'`.ipa` avec AltStore PAL → **Installer**.
4. Renouvellement : avec un Apple ID gratuit, l'app expire au bout de **7 jours**
   et doit être réinstallée ; AltStore peut le faire automatiquement en Wi-Fi.

---

## Résumé rapide

| Méthode | Compte payant ? | Zone | Renouvellement | Difficulté |
|---|---|---|---|---|
| TestFlight | Oui (99 $/an) | Monde | ~90 jours par build | Simple |
| AltStore PAL | Non (Apple ID gratuit) | UE seulement | 7 jours | Moyenne |

Dans les deux cas, la **compilation** se fait sur un Mac cloud via le workflow
fourni — tu n'as jamais besoin d'un ordinateur personnel.
