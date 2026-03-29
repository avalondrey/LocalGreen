# 🌱 LocalGreen

Mini-jeu de jardinage isométrique style manga avec IA locale.

## 🎮 Description

LocalGreen est un mini-jeu de jardinage isométrique où vous cultivez votre propre jardin virtuel. Plantez des graines, arrosez-les, regardez-les grandir et récoltez vos légumes ! Le jeu intègre une IA locale (Ollama + Mistral) pour générer des quêtes journalières et des conseils de jardinage personnalisés.

## ✨ Fonctionnalités

### Gameplay
- **🌿 3 types de plantes** : Tomate, Carotte, Laitue
- **📈 5 stades de croissance** : Graine → Pousse → Jeune → Mature → Prêt à récolter
- **🔧 4 outils** : Planter, Arroser, Récolter, Retirer
- **📅 Cycle jour/nuit** automatique avec transitions fluides et étoiles
- **🌸 4 saisons** : Printemps, Été, Automne, Hiver (avec modificateurs)
- **🌤️ Météo dynamique** : Soleil, Nuageux, Pluie (arrosage auto), Orage (éclairs)
- **📜 Quêtes journalières** générées par l'IA
- **🎒 Système d'inventaire** complet
- **⭐ Score et pièces** avec sauvegarde/chargement

### Systèmes avancés
- **🛒 Boutique** : Acheter des graines, vendre vos récoltes (touche B)
- **🤖 Chat IA** : Discutez avec le jardinier IA Mistral (touche T)
- **💡 Infobulles** : Survolez les plantes pour voir leurs infos détaillées
- **🖱️ Surbrillance** : Indicateur visuel coloré selon l'outil sélectionné
- **🏅 12 Succès** : Premier Pas Vert, Main Verte, Fermier Riche...
- **📖 Tutoriel** : Guide interactif pas-à-pas pour les nouveaux joueurs
- **🔊 Sons procéduraux** : Musique d'ambiance + effets sonores (aucun fichier requis)
- **✨ Effets de particules** : Arrosage, croissance, récolte, plantation

### Interface
- **🖥️ HUD complet** : Score, pièces, jour, saison, boutons sauvegarde/chargement
- **🔧 Barre d'outils** : Sélecteur d'outils + sélecteur de plantes en bas d'écran
- **🎒 Panneau d'inventaire** : Stock de légumes et graines en temps réel
- **📜 Panneau de quêtes** : Objectifs, progression, récompenses
- **💬 Notifications** : Messages contextuels animés
- **🎬 Écran titre** : Menu principal avec fond animé et particules

### IA Locale
- **🤖 Intégration Ollama** : Communication directe depuis Godot via HTTPRequest
- **🌐 Serveur HTTP Python** : API REST avec endpoints pour quêtes et conseils
- **💬 Chat interactif** : Posez des questions au jardinier IA
- **🎯 Quêtes IA** : Générées dynamiquement en JSON

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|-------------|
| Moteur | Godot 4.6 |
| Rendu | 2D isométrique procédural |
| Langage | GDScript + Python |
| IA | Ollama + Mistral |
| API IA | HTTP REST (Python stdlib) |
| Audio | Procédural (AudioStreamWAV) |

## 📁 Structure du projet

```
LocalGreen/
├── project.godot                  # Configuration Godot 4.6
├── scenes/
│   ├── main.tscn                  # Scène principale complète
│   └── title_screen.tscn          # Écran titre / menu principal
├── scripts/
│   ├── GreenhouseGrid.gd          # Grille isométrique + rendu plantes
│   ├── PlantData.gd               # Données des plantes (Resource)
│   ├── GameManager.gd             # Score, inventaire, saisons, sauvegarde
│   ├── UIManager.gd               # HUD, toolbar, quêtes, notifications
│   ├── AIManager.gd               # Intégration Ollama dans Godot
│   ├── TitleScreen.gd             # Écran titre animé avec menu
│   ├── ShopSystem.gd              # Boutique acheter/vendre
│   ├── ChatAI.gd                  # Chat interactif avec l'IA
│   ├── WeatherSystem.gd           # Météo dynamique (pluie, orage, nuages)
│   ├── TooltipSystem.gd           # Infobulles au survol des plantes
│   ├── TutorialSystem.gd          # Tutoriel interactif 10 étapes
│   ├── AchievementSystem.gd       # 12 succès/défis à débloquer
│   ├── HoverHighlight.gd          # Surbrillance des tuiles
│   ├── SoundManager.gd            # Sons et musique procéduraux
│   ├── DayNightCycle.gd           # Cycle jour/nuit + étoiles
│   ├── ParticleEffects.gd         # Effets visuels de particules
│   └── CameraController.gd        # Contrôle caméra (zoom, déplacement)
├── ai-backend/
│   ├── ollama_client.py           # Serveur IA HTTP REST
│   └── requirements.txt           # Dépendances Python
└── assets/
    ├── plants/tomato/spritesheet.png   # Sprite IA tomate
    ├── plants/carrot/spritesheet.png   # Sprite IA carotte
    ├── plants/lettuce/spritesheet.png  # Sprite IA laitue
    ├── tiles/garden_background.png     # Background de jardin
    └── ui/game_icon.png                # Icône du jeu
```

## 🚀 Démarrage rapide

### 1. Ouvrir le projet dans Godot
1. Téléchargez [Godot 4.6](https://godotengine.org/download)
2. Ouvrez Godot et importez le projet (sélectionnez `project.godot`)
3. Lancez la scène `scenes/main.tscn`

### 2. Lancer l'IA (optionnel)
```bash
# Installer Ollama : https://ollama.ai
ollama pull mistral

# Lancer le serveur IA
cd ai-backend
pip install -r requirements.txt
python ollama_client.py
```

Le serveur sera accessible sur `http://localhost:8080`

## 🎯 Contrôles

### Gameplay
| Action | Contrôle |
|--------|----------|
| Sélectionner outil | 1 = Planter, 2 = Arroser, 3 = Récolter, 4 = Retirer |
| Utiliser outil | Clic gauche sur une tuile |
| Annuler / Eau | Clic droit |
| Déplacer caméra | WASD / Flèches |
| Zoomer | Molette de la souris |

### Interface
| Action | Contrôle |
|--------|----------|
| Boutique | B |
| Chat IA | T |
| Succès | J |
| Sauvegarder | F5 |
| Charger | F9 |

## 🌱 Mécaniques de jeu

### Croissance des plantes
Chaque plante passe par 5 stades de croissance. La croissance nécessite de l'eau qui se consomme au fil du temps :

| Stade | Description | Temps |
|-------|-------------|-------|
| 🌰 Graine | Nouvellement plantée | 10s |
| 🌱 Pousse | Premières feuilles | 20s |
| 🌿 Jeune | Plante en croissance | 30s |
| ☘️ Mature | Bientôt prête | 40s |
| ✨ Prêt | À récolter ! | Instant |

### Saisons
| Saison | Croissance | Eau | Bonus |
|--------|-----------|-----|----|
| 🌸 Printemps | ×1.0 | ×1.0 | +1 graine/jour |
| ☀️ Été | ×1.3 | ×1.5 | Aucun |
| 🍂 Automne | ×0.8 | ×0.8 | +2 graines/jour |
| ❄️ Hiver | ×0.5 | ×0.5 | Aucun |

### Météo
| Météo | Croissance | Eau | Spécial |
|-------|-----------|-----|---------|
| ☀️ Ensoleillé | ×1.2 | ×1.3 | Aucun |
| ☁️ Nuageux | ×1.0 | ×1.0 | Aucun |
| 🌧️ Pluie | ×1.1 | ×0.7 | Arrosage auto |
| ⛈️ Orage | ×0.8 | ×0.4 | Arrosage intense + éclairs |

### Valeurs de récolte
| Plante | Récolte (⭐) | Vente (🪙) | Temps total |
|--------|-------------|-----------|-------------|
| 🍅 Tomate | 100 pts | 12 pièces | ~100s |
| 🥕 Carotte | 80 pts | 10 pièces | ~100s |
| 🥬 Laitue | 60 pts | 7 pièces | ~100s |

## 🏅 Succès

| Succès | Condition |
|--------|-----------|
| 🌱 Premier Pas Vert | Planter 1 graine |
| 🌿 Main Verte | Planter 10 graines |
| 🧑‍🌾 Fermier | Planter 50 graines |
| 🧺 Première Récolte | Récolter 1 légume |
| 🏆 Maître Fermier | Récolter 25 légumes |
| 💰 Fermier Riche | Avoir 200 pièces |
| 💧 L'Arroseur | Arroser 50 fois |
| 🏡 Jardin Complet | Remplir la grille (24 cases) |
| 📅 Survivant | Atteindre le jour 10 |
| 🌸 Cycle Complet | Voir les 4 saisons |
| 📦 Collectionneur | 5 de chaque légume |
| 🤖 Ami de l'IA | Recevoir une quête IA |

## 🤖 API IA

Le serveur Python expose les endpoints suivants :

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Vérifie la connexion Ollama |
| `/quest` | GET | Génère une quête journalière |
| `/tip` | POST | `{"plant_type": "tomato"}` → Conseil |
| `/advice` | POST | `{"question": "..."}` → Réponse IA |
| `/status` | GET | Informations du serveur |

## 📝 Licence

Projet personnel — libre d'utilisation et de modification.
