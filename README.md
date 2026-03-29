# 🌱 LocalGreen

Mini-jeu de jardinage isométrique style manga, avec IA locale.

## 🎮 Features
- Grille de culture 6x4 en perspective isométrique 2:1
- Système de croissance avec 5 états par plante
- Rendu manga : contours épais, hachures, screentones
- IA locale via Ollama pour quêtes et conseils

## 🛠️ Stack
- **Moteur** : Godot 4.x
- **IA** : Ollama + Mistral/Llama 3.1
- **Langage** : GDScript + Python (backend IA)
- **Assets** : Tilesets générés style manga

## 🚀 Démarrage rapide

### Prérequis
- Godot 4.x installé
- Ollama : https://ollama.ai
- Modèle : `ollama pull mistral`

### Lancer le jeu
1. Ouvrir `project.godot` dans Godot
2. Lancer la scène `scenes/main.tscn`

### Lancer le backend IA (optionnel)
```bash
cd ai-backend
pip install -r requirements.txt
python ollama_client.py