<<<<<<< HEAD
import requests
import os
from pathlib import Path

# PokeAPI URL to fetch all pokemon names
pokeapi_url = "https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0"

# Backend API configuration
def get_backend_url():
    """Get backend API URL from environment or configuration"""
    # Try environment variable first (for AWS deployment)
    backend_url = os.getenv('POKEAPI_BACKEND_URL')
    if backend_url:
        return backend_url
    
    # Try to read from Terraform outputs file
    terraform_outputs = Path(__file__).parent.parent / "terraform" / "terraform_outputs.json"
    if terraform_outputs.exists():
        try:
            import json
            with open(terraform_outputs, 'r') as f:
                outputs = json.load(f)
                backend_ip = outputs.get('backend_system_private_ip', {}).get('value')
                if backend_ip:
                    return f"http://{backend_ip}:5000"
        except Exception:
            pass
    
    # Default to local backend for development
    return "http://localhost:5000"

# Functions to interact with the PokeAPI fetch data and confirm successful retrieval
def fetch_all_pokemon_names():
    response = requests.get(pokeapi_url)
    if response.status_code == 200:
        results = response.json()['results']
        return [p['name'] for p in results]
    else:
        print("Failed to get Pokémon list.")
        return []

# Function to fetch details of a specific Pokémon by name and confirm successful retrieval
def fetch_pokemon_details(name):
    url = f"https://pokeapi.co/api/v2/pokemon/{name}"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return {
            "name": data["name"],
            "id": data["id"],
            "height": data["height"],
            "weight": data["weight"],
            "base_experience": data["base_experience"],
            "types": [t["type"]["name"] for t in data["types"]],
            "abilities": [a["ability"]["name"] for a in data["abilities"]],
            "stats": [{"name": s["stat"]["name"], "value": s["base_stat"]} for s in data["stats"]],
            "sprites": data["sprites"]
        }
    return None

# New backend API functions
def check_backend_health():
    """Check if backend API is available"""
    try:
        backend_url = get_backend_url()
        response = requests.get(f"{backend_url}/health", timeout=5)
        return response.status_code == 200
    except Exception:
        return False

def get_pokemon_from_backend(name):
    """Get Pokemon from backend collection"""
    try:
        backend_url = get_backend_url()
        response = requests.get(f"{backend_url}/pokemon/{name}", timeout=5)
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        print(f"Backend error: {e}")
        return None

def save_pokemon_to_backend(pokemon_data):
    """Save Pokemon to backend collection"""
    try:
        backend_url = get_backend_url()
        response = requests.post(f"{backend_url}/pokemon", json=pokemon_data, timeout=5)
        return response.status_code == 201
    except Exception as e:
        print(f"Backend save error: {e}")
        return False

def get_backend_stats():
    """Get collection statistics from backend"""
    try:
        backend_url = get_backend_url()
        response = requests.get(f"{backend_url}/stats", timeout=5)
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        print(f"Backend stats error: {e}")
        return None

def sync_to_backend(local_data):
    """Sync local collection to backend"""
    try:
        backend_url = get_backend_url()
        response = requests.post(f"{backend_url}/sync", json=local_data, timeout=10)
        if response.status_code == 200:
            result = response.json()
            print(f" Synced {result.get('synced_count', 0)} Pokemon to backend")
            return True
        return False
    except Exception as e:
        print(f"Sync error: {e}")
        return False
=======
import requests
# api url to fetch all pokemon names
pokeapi_url = "https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0"

# functions to interact with the PokeAPI fetch data and confirm successful retrieval
def fetch_all_pokemon_names():
    response = requests.get(pokeapi_url)
    if response.status_code == 200:
        results = response.json()['results']
        return [p['name'] for p in results]
    else:
        print("Failed to get Pokémon list.")
        return []

# function to fetch details of a specific Pokémon by name and confirm successful retrieval
def fetch_pokemon_details(name):
    url = f"https://pokeapi.co/api/v2/pokemon/{name}"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return {
            "name": data["name"],
            "base_experience": data["base_experience"],
            "abilities": [a["ability"]["name"] for a in data["abilities"]]
        }
    return None
>>>>>>> b090d02949d07ea172da0fa95b45ed05ba6b52c1
