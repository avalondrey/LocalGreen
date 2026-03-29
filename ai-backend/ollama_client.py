"""
LocalGreen — Backend IA (Ollama + Mistral)
===========================================
API HTTP locale pour l'intégration IA dans Godot.
Lance ce serveur pour que le jeu communique avec l'IA.

Usage:
    pip install -r requirements.txt
    python ollama_client.py

Endpoints:
    GET  /health         — Vérifie la connexion Ollama
    GET  /quest          — Génère une quête journalière
    POST /tip            — Conseil de jardinage  {"plant_type": "tomato"}
    POST /advice         — Demande au bot          {"question": "..."}
    GET  /status         — Statut du serveur
"""

import requests
import json
import sys

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ─── Configuration ───────────────────────────────────────────────────
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "mistral"
SERVER_PORT = 8080
SERVER_HOST = "0.0.0.0"

# ─── Ollama Client ───────────────────────────────────────────────────
def ollama_generate(prompt: str, temperature: float = 0.7) -> dict:
    """Envoie un prompt à Ollama et retourne la réponse."""
    try:
        resp = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": temperature, "num_predict": 300}
            },
            timeout=30
        )
        return resp.json()
    except requests.exceptions.ConnectionError:
        return {"error": "Ollama n'est pas lancé. Lancez: ollama serve"}
    except requests.exceptions.Timeout:
        return {"error": "Délai d'attente dépassé"}
    except Exception as e:
        return {"error": str(e)}

# ─── Générateurs de contenu ──────────────────────────────────────────
def generate_quest() -> dict:
    """Génère une quête journalière pour le jeu."""
    prompt = """Tu es un générateur de quêtes pour un mini-jeu de jardinage isométrique style manga.
Génère UNE quête au format JSON STRICT (pas de markdown, pas de backticks).
Champs requis :
- "title": titre court (max 40 caractères)
- "description": description en français (max 100 caractères)
- "objective_type": "plant" ou "harvest" ou "water"
- "objective_target": nombre entre 2 et 10
- "reward_coins": nombre entre 10 et 100
- "reward_xp": nombre entre 25 et 200

Variétés de quêtes : planter X plants, récolter X légumes, arroser X fois,
cultiver un type spécifique, etc.

Réponds UNIQUEMENT avec le JSON."""
    result = ollama_generate(prompt, 0.8)
    if "error" in result:
        return result

    text = result.get("response", "").strip()
    if "```" in text:
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]

    try:
        quest = json.loads(text)
        required = ["title", "description", "objective_type", "objective_target", "reward_coins", "reward_xp"]
        for field in required:
            if field not in quest:
                raise ValueError(f"Champ manquant: {field}")
        quest["objective_current"] = 0
        quest["completed"] = False
        return quest
    except (json.JSONDecodeError, ValueError) as e:
        return {
            "title": "Quête mystérieuse",
            "description": "La quête n'a pas pu être générée correctement.",
            "objective_type": "harvest",
            "objective_target": 3,
            "reward_coins": 15,
            "reward_xp": 30,
            "objective_current": 0,
            "completed": False,
            "raw_response": text,
            "error": str(e)
        }

def generate_tip(plant_type: str) -> dict:
    """Génère un conseil de jardinage pour un type de plante."""
    prompt = f"""Donne un conseil de jardinage court (1-2 phrases) en français pour cultiver : {plant_type}.
Sois précis, utile et encourageant. Style manga kawaii."""
    result = ollama_generate(prompt, 0.6)
    if "error" in result:
        return result
    return {"tip": result.get("response", "").strip(), "plant_type": plant_type}

def generate_advice(question: str) -> dict:
    """Répond à une question du joueur."""
    prompt = f"""Tu es un expert jardinier dans un jeu vidéo style manga kawaii.
Le joueur te demande : {question}
Réponds en 1-2 phrases en français, de façon utile, sympathique et encourageante."""
    result = ollama_generate(prompt, 0.7)
    if "error" in result:
        return result
    return {"advice": result.get("response", "").strip()}


# ─── Serveur HTTP ────────────────────────────────────────────────────
class LocalGreenAPI(BaseHTTPRequestHandler):
    """Handler HTTP pour l'API du jeu."""

    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        body = self.rfile.read(length)
        return json.loads(body.decode("utf-8"))

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/health":
            result = ollama_generate("Réponds OK")
            connected = "response" in result
            self._set_headers()
            self.wfile.write(json.dumps({
                "ollama_connected": connected,
                "model": MODEL,
                "status": "healthy" if connected else "degraded"
            }).encode())

        elif path == "/quest":
            quest = generate_quest()
            self._set_headers()
            self.wfile.write(json.dumps(quest).encode())

        elif path == "/status":
            self._set_headers()
            self.wfile.write(json.dumps({
                "server": "LocalGreen AI Backend",
                "version": "1.0.0",
                "model": MODEL,
                "port": SERVER_PORT,
                "endpoints": ["/health", "/quest", "/tip", "/advice", "/status"]
            }).encode())

        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Endpoint non trouvé"}).encode())

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        body = self._read_body()

        if path == "/tip":
            plant = body.get("plant_type", "tomate")
            tip = generate_tip(plant)
            self._set_headers()
            self.wfile.write(json.dumps(tip).encode())

        elif path == "/advice":
            question = body.get("question", "Comment bien jardiner ?")
            advice = generate_advice(question)
            self._set_headers()
            self.wfile.write(json.dumps(advice).encode())

        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Endpoint non trouvé"}).encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, format, *args):
        print(f"  📡 {args[0]}")


# ─── Point d'entrée ──────────────────────────────────────────────────
def main():
    print()
    print("  ╔══════════════════════════════════════╗")
    print("  ║   🌱 LocalGreen AI Backend v1.0.0   ║")
    print("  ╚══════════════════════════════════════╝")
    print()
    print(f"  🤖 Modèle IA : {MODEL}")
    print(f"  🌐 Serveur   : http://{SERVER_HOST}:{SERVER_PORT}")
    print(f"  🔗 Ollama    : {OLLAMA_URL}")
    print()
    print("  Endpoints disponibles :")
    print("    GET  /health  — Vérifier la connexion IA")
    print("    GET  /quest   — Générer une quête")
    print("    POST /tip     — Conseil de jardinage")
    print("    POST /advice  — Poser une question")
    print("    GET  /status  — Statut du serveur")
    print()

    # Vérifier Ollama
    print("  🔍 Vérification de la connexion Ollama...", end=" ")
    result = ollama_generate("Réponds OK")
    if "response" in result:
        print("✅ Connecté !")
    else:
        print("❌ Non connecté")
        print(f"     Erreur: {result.get('error', 'Inconnue')}")
        print("     Assurez-vous que Ollama est lancé : ollama serve")
    print()

    # Lancer le serveur
    server = HTTPServer((SERVER_HOST, SERVER_PORT), LocalGreenAPI)
    try:
        print("  🚀 Serveur démarré ! Ctrl+C pour arrêter.")
        print()
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  👋 Arrêt du serveur.")
        server.server_close()


if __name__ == "__main__":
    main()
