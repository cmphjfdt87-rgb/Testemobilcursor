# NEON DRIFT 3D 🏁

Le runner de conduite **3D** néon ultime — moteur WebGL (Three.js), boutique de véhicules, économie de pièces et partage de score.

## 🎮 Jouer maintenant

**Lien direct (Safari) :** https://raw.githack.com/cmphjfdt87-rgb/Testemobilcursor/main/index.html

> Si une page de confirmation s'affiche, appuie sur **« Open the page »**.

**Lien permanent (après activation GitHub Pages) :** https://cmphjfdt87-rgb.github.io/Testemobilcursor/

### Activer GitHub Pages (1 minute, une seule fois)

1. Va sur https://github.com/cmphjfdt87-rgb/Testemobilcursor/settings/pages
2. **Source** → **Deploy from a branch**
3. Branche **gh-pages** → dossier **/ (root)** → **Save**

## 📲 Installer sur iPhone

1. Ouvre le lien dans **Safari** (pas Chrome)
2. Appuie sur **Partager** (carré avec flèche vers le haut)
3. Choisis **« Sur l'écran d'accueil »** → **Ajouter**

## 🕹️ Gameplay

- **Balaye ← →** pour changer de voie (tap = klaxon 📯)
- Esquive voitures, camions et barrières néon
- 🪙 Collecte les pièces + bonus de fin de course
- ⚡ « Frôlé ! » : +5 points quand tu rases un obstacle
- La vitesse monte en continu, jusqu'à 230 km/h

## 🛒 Boutique (Garage)

| Véhicule | Prix |
|----------|------|
| 🏎️ NEON GT | Gratuit |
| 🚐 RETRO VAN | 🪙 250 |
| 🚗 MUSCLE 88 | 🪙 750 |
| 🚓 INTERCEPTOR (gyrophares !) | 🪙 1500 |
| 🚛 BIG RIG — le camion néon | 🪙 3000 |
| 🛸 OVNI 51 (il vole !) | 🪙 6000 |

Prévisualisation 3D en direct dans le garage, achats sauvegardés sur ton téléphone.

## ⚙️ Tech

- Three.js r128 (WebGL), 60 FPS visé sur mobile
- Musique synthwave + SFX générés en WebAudio (zéro fichier audio)
- PWA : hors-ligne après le premier chargement, installable
- Un seul fichier `index.html`

## Développement local

```bash
python3 -m http.server 8080
```
