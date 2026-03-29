import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "mistral"

def generate(prompt: str, stream: bool = False) -> dict:
    try:
        resp = requests.post(OLLAMA_URL, json={"model": MODEL, "prompt": prompt, "stream": stream}, timeout=30)
        return resp.json()
    except Exception as e:
        return {"error": str(e)}

def get_daily_quest() -> dict:
    prompt = 'Genere une quete jardinage JSON: {"title":"...", "description":"...", "reward":50}'
    r = generate(prompt)
    if "response" in r:
        try:
            return json.loads(r["response"])
        except:
            return {"title":"Quest","description":r["response"],"reward":50}
    return {"title":"Error","description":"IA offline","reward":0}

if __name__ == "__main__":
    print("🤖 Test Ollama...")
    q = get_daily_quest()
    print(f"📜 {q['title']}: {q['description']} (+{q['reward']} XP)")
    input("\nAppuie sur Entrée pour quitter...")
