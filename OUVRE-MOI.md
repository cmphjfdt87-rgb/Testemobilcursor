# Ouvre ça sur ton iPhone — c'est tout

Tu n'as **rien d'autre à faire**. Pas de PC, pas de compte, pas de GitHub.

## Lien principal (ouvre l'app, pas le code source)

**Copie ce lien et ouvre-le dans Bluefy** (pas Safari) :

```
https://driven-binary-5br3fny.shipstatic.com
```

Tu dois voir l'écran **NBX Console** (bouton blanc « Connecter ma trottinette »), **pas** du code HTML.

## Lien de secours permanent (ne expire pas)

Si le lien principal ne charge plus :

```
https://htmlpreview.github.io/?https://raw.githubusercontent.com/cmphjfdt87-rgb/Testemobilcursor/gh-pages/index.html
```

## En 3 gestes

1. **App Store** → installe **Bluefy** (gratuit, navigateur avec Bluetooth).
2. Ouvre Bluefy → colle le **lien principal** ci-dessus.
3. Allume ta trottinette → appuie sur **Connecter ma trottinette**.

Tu dois voir **« NBX v2.3 — Prêt »** en bas de l'écran d'accueil.

---

## Tu vois du code au lieu de l'app ?

C'est le **mauvais lien**. N'utilise **pas** les liens `cdn.jsdelivr.net` — ils affichent le code source dans Bluefy. Utilise uniquement les deux liens ci-dessus.

---

## Ta trottinette : Ninebot E45E

| Ce que l'app fait | Ce qu'elle ne peut pas faire |
|---|---|
| Se connecter en Bluetooth | Débrider à 45 km/h (impossible) |
| Lire vitesse, batterie, firmware | Changer la région sur firmware DRV 2.7.x |
| Tenter une connexion chiffrée | Flasher / downgrader le firmware depuis iPhone |

Le **35 km/h roue en l'air puis 25** est normal : à vide le moteur s'emballe, en charge le limiteur revient à 25.

Pour débrider **vraiment** (~30 km/h max sur E45) il faut **un téléphone Android** (emprunté 15 min) + **ScooterHacking Utility** (gratuit) : downgrade DRV 2.7.1 → 2.5.5 puis preset région E45 30 km/h. Aucune app iPhone ne peut faire ça sans risque de brick.

---

## Problème ?

- **Code source affiché** → mauvais lien, utilise le lien ShipStatic ou htmlpreview ci-dessus.
- **« Script non chargé »** → tire vers le bas pour rafraîchir, ou réouvre le lien dans Bluefy.
- **Menu Bluetooth ne s'ouvre pas** → vérifie que tu es bien dans **Bluefy**, pas Safari.
- **Connecté mais 25 km/h** → firmware 2.7.x bloque l'écriture ; voir Android ci-dessus.
