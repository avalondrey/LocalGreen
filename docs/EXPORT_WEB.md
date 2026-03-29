# 🌐 Guide d'export web — LocalGreen

## 📋 Résumé rapide

| Plateforme | Difficulté | Coût | URL perso ? |
|------------|-----------|------|-------------|
| **Itch.io** | ⭐ Très facile | Gratuit | ✅ `pseudo.itch.io/localgreen` |
| **GitHub Pages** | ⭐⭐ Facile | Gratuit | ✅ `pseudo.github.io/LocalGreen` |
| **Netlify** | ⭐⭐ Facile | Gratuit | ✅ `localgreen.netlify.app` |
| **Vercel** | ⭐⭐ Facile | Gratuit | ✅ `localgreen.vercel.app` |

---

## 🚀 Méthode 1 : Itch.io (la plus simple)

### Étape A : Exporter depuis Godot
1. Ouvrir le projet dans Godot 4.6
2. **Éditeur → Gérer les templates d'exportation** → Télécharger **Web (HTML5)**
3. **Projet → Exporter...**
4. Le preset "Web" est déjà configuré
5. Cocher **Exporter avec débogage** (pour tester)
6. Cliquer **Exporter le projet** → choisir un dossier `builds/web/`
7. Ça génère : `index.html` + `LocalGreen.js` + `LocalGreen.wasm`

### Étape B : Publier sur Itch.io
1. Aller sur [itch.io](https://itch.io) → Créer un compte
2. **Dashboard → Create new project**
3. Remplir :
   - Title : `LocalGreen`
   - Kind of project : `HTML`
   - Upload : Glisser le dossier `builds/web/` (ou zipper puis upload)
   - Check "This file will be played in the browser"
   - Dimensions : `1280 x 720`
   - Mobile-friendly : coché
4. Cliquer **Save & View page**
5. Cliquez **Publish** → Votre jeu est en ligne ! 🎉

> **URL** : `https://pseudo.itch.io/localgreen`

---

## 🚀 Méthode 2 : GitHub Pages

### Étape A : Exporter
1. Exporter comme ci-dessus dans `builds/web/`

### Étape B : Commit sur GitHub
```bash
cd LocalGreen
# Copier les fichiers exportés dans docs/
cp -r builds/web/* docs/

git add docs/
git commit -m "🚀 Déploiement web"
git push origin main
```

### Étape C : Activer GitHub Pages
1. Aller sur le repo GitHub → **Settings → Pages**
2. Source : `Deploy from a branch`
3. Branch : `main` / Folder : `/docs`
4. Cliquer **Save**
5. Attendre 1-2 minutes → Votre jeu est en ligne !

> **URL** : `https://pseudo.github.io/LocalGreen`

**Astuce** : Utilise le `web_shell.html` fourni dans `export/` à la place du `index.html` par défaut pour un meilleur design.

---

## 🚀 Méthode 3 : Netlify (drag & drop)

### Étape A : Exporter
1. Exporter dans `builds/web/`
2. Optionnel : utiliser le `export/web_shell.html` comme page principale

### Étape B : Déployer
1. Aller sur [app.netlify.com](https://app.netlify.com)
2. Glisser-déposer le dossier `builds/web/` directement sur la page
3. C'est tout ! 🎉

> **URL** : `https://random-name-12345.netlify.app` (renommable)

---

## ⚠️ Limites du mode web

| Fonctionnalité | Desktop | Web |
|---------------|---------|-----|
| Gameplay complet | ✅ | ✅ |
| Sauvegarde | Fichier JSON | localStorage |
| IA Ollama | ✅ | ❌ (quêtes prédéfinies) |
| Chat IA | ✅ | ❌ |
| Sons procéduraux | ✅ | ✅ (si supporté) |
| Boutique | ✅ | ✅ |
| Succès | ✅ | ✅ |
| Météo | ✅ | ✅ |
| Tutorial | ✅ | ✅ |

### Adaptations incluses
- **WebAdapter.gd** : Détecte le mode web, désactive l'IA proprement
- **WebQuests.gd** : 12 quêtes prédéfinies utilisées sans IA
- **web_shell.html** : Page HTML personnalisée avec loader, responsive, plein écran

---

## 🔧 Personnaliser l'HTML (optionnel)

Pour utiliser le `web_shell.html` au lieu du HTML par défaut de Godot :

1. Dans Godot → Projet → Exporter... → Preset Web
2. **Custom HTML shell** → Sélectionner `export/web_shell.html`
3. Ré-exporter

Le shell personnalisé inclut :
- Barre de chargement verte avec pourcentage
- Design adapté au thème du jeu
- Support mobile (plein écran sur double-tap)
- Empêche le scroll involontaire
- Meta tags pour le partage sur réseaux sociaux
