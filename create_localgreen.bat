
### `ai-backend/ollama_client.py`
```python
import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "mistral"

def generate(prompt: str, stream: bool = False) -> dict:
    """Génère du texte avec Ollama"""
    try:
        resp = requests.post(OLLAMA_URL, json={
            "model": MODEL,
            "prompt": prompt,
            "stream": stream
        }, timeout=30)
        return resp.json()
    except Exception as e:
        return {"error": str(e)}

def get_daily_quest() -> dict:
    """Génère une quête quotidienne"""
    prompt = """Génère une quête de jardinage en JSON:
    {
        "title": "Titre de la quête",
        "description": "Description courte",
        "reward": 50
    }
    Sois créatif et manga-style!"""
    
    response = generate(prompt)
    if "response" in response:
        try:
            return json.loads(response["response"])
        except:
            return {"title": "Quest", "description": response["response"], "reward": 50}
    return {"title": "Error", "description": "IA indisponible", "reward": 0}

def get_planting_tip(plant_type: str, stage: str) -> str:
    """Conseil de plantation"""
    prompt = f"Conseil manga-style pour {plant_type} au stade {stage}. 1 phrase max."
    response = generate(prompt)
    return response.get("response", "Arrose régulièrement !")

if __name__ == "__main__":
    print("🤖 Test connexion Ollama...")
    quest = get_daily_quest()
    print(f"📜 Quête du jour: {quest['title']}")
    print(f"   {quest['description']}")
    print(f"   Récompense: {quest['reward']} XP")