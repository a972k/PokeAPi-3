<<<<<<< HEAD
import json
import os
import time
import sys
from pathlib import Path

# Import backend functions
try:
    from pokeapi import (
        check_backend_health, 
        get_pokemon_from_backend, 
        save_pokemon_to_backend, 
        get_backend_stats,
        sync_to_backend
    )
except ImportError:
    # Fallback if pokeapi module not available
    def check_backend_health(): return False
    def get_pokemon_from_backend(name): return None
    def save_pokemon_to_backend(data): return False
    def get_backend_stats(): return None
    def sync_to_backend(data): return False

# Configuration that matches your Terraform setup
AWS_REGION = 'us-west-2'  # From your Terraform variables
DYNAMODB_TABLE = 'PokemonCollection'  # Table for your backend

# Local JSON storage (fallback when backend isn't available)
STORAGE_FILE = Path(__file__).parent / "pokemon_collection.json"

def pokeball_animation():
    """Display a pokeball animation while loading"""
    pokeball_frames = [
        "🔴⚪",
        "⚪🔴", 
        "🔴⚪",
        "⚪🔴"
    ]
    
    print("Catching Pokémon...", end="", flush=True)
    
    for _ in range(6):  # Show animation for ~1.5 seconds
        for frame in pokeball_frames:
            print(f"\r{frame} Catching Pokémon... {frame}", end="", flush=True)
            time.sleep(0.25)
    
    print("\rPokémon caught! " + " " * 20)  # Clear line

def load_local_storage():
    """Load pokemon data from local JSON file"""
    if STORAGE_FILE.exists():
        try:
            with open(STORAGE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}
    return {}

def save_local_storage(data):
    """Save pokemon data to local JSON file"""
    try:
        with open(STORAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except IOError as e:
        print(f"Error saving to local storage: {e}")

def get_pokemon(name):
    """Get pokemon from storage (Backend API first, then local fallback)"""
    try:
        # Show pokeball animation
        pokeball_animation()
        
        # Try backend API first
        if check_backend_health():
            backend_pokemon = get_pokemon_from_backend(name)
            if backend_pokemon:
                print(f"🌐 Found {name} in backend API!")
                return backend_pokemon
        
        # Fallback to local storage
        local_data = load_local_storage()
        pokemon_data = local_data.get(name.lower())
        
        if pokemon_data:
            print(f"Found {name} in local storage!")
            return pokemon_data
            
        return None
        
    except Exception as e:
        print(f"Error getting Pokémon: {e}")
        return None

def save_pokemon(data):
    """Save pokemon to storage (Backend API first, then local backup)"""
    try:
        pokemon_name = data['name'].lower()
        
        # Try to save to backend API first
        if check_backend_health():
            if save_pokemon_to_backend(data):
                print(f"Saved {data['name']} to backend API!")
            else:
                print(f"Backend save failed for {data['name']}, using local storage")
        
        # Always save to local storage as backup
        local_data = load_local_storage()
        local_data[pokemon_name] = data
        save_local_storage(local_data)
        print(f"Saved {data['name']} to local storage!")
        
    except Exception as e:
        print(f"Error saving Pokémon: {e}")

def get_collection_stats():
    """Get statistics about the pokemon collection from all sources"""
    try:
        # Try backend API first
        if check_backend_health():
            backend_stats = get_backend_stats()
            if backend_stats:
                print("Stats from backend API")
                return {
                    "total_pokemon": backend_stats.get("total_pokemon", 0),
                    "pokemon_names": [],  # Don't list all names for performance
                    "sources": ["Backend API"],
                    "latest_catch": backend_stats.get("latest_catch")
                }
        
        # Fallback to local storage
        local_data = load_local_storage()
        pokemon_names = list(local_data.keys())
        
        return {
            "total_pokemon": len(pokemon_names),
            "pokemon_names": sorted(pokemon_names),
            "sources": ["Local storage"],
            "latest_catch": None
        }
        
    except Exception as e:
        print(f"Error getting collection stats: {e}")
        return {"total_pokemon": 0, "pokemon_names": [], "sources": ["Error occurred"]}

def sync_with_backend():
    """Sync local data with backend when connection is available"""
    if not check_backend_health():
        print("Backend not available for sync")
        return False
    
    try:
        local_data = load_local_storage()
        if not local_data:
            print("No local data to sync")
            return True
        
        print(f"Syncing {len(local_data)} Pokemon to backend...")
        return sync_to_backend(local_data)
        
    except Exception as e:
        print(f"Sync failed: {e}")
        return False

def setup_game():
    """Setup the game with backend/local storage detection"""
    print("\nSetting up Pokemon Game...")
    
    # Check backend connection
    if check_backend_health():
        print("Backend API connected!")
        print("Using centralized Pokemon collection")
        
        # Try to sync local data to backend
        local_data = load_local_storage()
        if local_data:
            print(f"Found {len(local_data)} local Pokemon, syncing...")
            sync_with_backend()
    else:
        print("Backend API not available")
        print("Using local storage only")
    
    # Show current stats
    stats = get_collection_stats()
    if stats["total_pokemon"] > 0:
        print(f"You have {stats['total_pokemon']} Pokemon in your collection!")
    else:
        print("Your collection is empty - time to catch some Pokemon!")
    
    print("Game ready!\n")
    return True

# Auto-setup when module is imported
if __name__ == "__main__":
    setup_game()
=======
import json
import os
import time
import sys
from pathlib import Path

# Configuration that matches your Terraform setup
AWS_REGION = 'us-west-2'  # From your Terraform variables
DYNAMODB_TABLE = 'PokemonCollection'  # Table for your backend
API_ENDPOINT = None  # Will be set when backend is deployed

# Local JSON storage (fallback when AWS isn't available)
STORAGE_FILE = Path(__file__).parent / "pokemon_collection.json"

def pokeball_animation():
    """Display a pokeball animation while loading"""
    pokeball_frames = [
        "🔴⚪",
        "⚪🔴", 
        "🔴⚪",
        "⚪🔴"
    ]
    
    print("Fetching new Pokémon data...", end="", flush=True)
    
    for _ in range(8):  # Show animation for ~2 seconds
        for frame in pokeball_frames:
            print(f"\r{frame} Catching Pokémon... {frame}", end="", flush=True)
            time.sleep(0.25)
    
    print("\r Pokémon caught! " + " " * 20)  # Clear line

def get_backend_endpoint():
    """Get the backend API endpoint from Terraform outputs or environment"""
    global API_ENDPOINT
    
    if API_ENDPOINT:
        return API_ENDPOINT
    
    # Try to get from environment variable (set after Terraform deployment)
    endpoint = os.getenv('POKEAPI_BACKEND_URL')
    if endpoint:
        API_ENDPOINT = endpoint
        return endpoint
    
    # Try to read from Terraform outputs file (if exists)
    terraform_outputs = Path(__file__).parent.parent / "terraform" / "terraform_outputs.json"
    if terraform_outputs.exists():
        try:
            with open(terraform_outputs, 'r') as f:
                outputs = json.load(f)
                backend_ip = outputs.get('backend_system_private_ip', {}).get('value')
                if backend_ip:
                    API_ENDPOINT = f"http://{backend_ip}:5000"
                    return API_ENDPOINT
        except Exception as e:
            print(f"Warning: Could not read Terraform outputs: {e}")
    
    return None

def check_aws_connection():
    """Check if we can connect to AWS services (DynamoDB)"""
    try:
        import boto3
        from botocore.exceptions import ClientError, NoCredentialsError
        
        dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
        table = dynamodb.Table(DYNAMODB_TABLE)
        
        # Try a simple operation to test connection
        table.load()
        return True, table
        
    except NoCredentialsError:
        print("AWS credentials not configured. Using local storage.")
        return False, None
    except ClientError as e:
        print(f"AWS connection failed: {e}. Using local storage.")
        return False, None
    except ImportError:
        print("boto3 not installed. Using local storage.")
        return False, None
    except Exception as e:
        print(f"AWS error: {e}. Using local storage.")
        return False, None

def load_local_storage():
    """Load pokemon data from local JSON file"""
    if STORAGE_FILE.exists():
        try:
            with open(STORAGE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}
    return {}

def save_local_storage(data):
    """Save pokemon data to local JSON file"""
    try:
        with open(STORAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except IOError as e:
        print(f"Error saving to local storage: {e}")

def get_pokemon(name):
    """Get pokemon from storage (DynamoDB first, then local fallback)"""
    try:
        # Show pokeball animation
        pokeball_animation()
        
        # Try AWS DynamoDB first
        aws_connected, table = check_aws_connection()
        
        if aws_connected:
            try:
                response = table.get_item(Key={'name': name.lower()})
                if 'Item' in response:
                    print(f"Found {name} in DynamoDB!")
                    return response['Item']
            except Exception as e:
                print(f"AWS read error: {e}")
        
        # Fallback to local storage
        local_data = load_local_storage()
        pokemon_data = local_data.get(name.lower())
        
        if pokemon_data:
            print(f"📂 Found {name} in local storage!")
            return pokemon_data
            
        return None
        
    except Exception as e:
        print(f"Error getting Pokémon: {e}")
        return None

def save_pokemon(data):
    """Save pokemon to storage (both DynamoDB and local)"""
    try:
        pokemon_name = data['name'].lower()
        
        # Try to save to AWS DynamoDB first
        aws_connected, table = check_aws_connection()
        
        if aws_connected:
            try:
                # Prepare data for DynamoDB (ensure all values are JSON serializable)
                dynamo_data = {
                    'name': pokemon_name,
                    'id': data.get('id'),
                    'height': data.get('height'),
                    'weight': data.get('weight'),
                    'types': data.get('types', []),
                    'abilities': data.get('abilities', []),
                    'stats': data.get('stats', []),
                    'sprites': data.get('sprites', {}),
                    'captured_at': str(int(time.time()))  # Unix timestamp
                }
                
                table.put_item(Item=dynamo_data)
                print(f"Saved {data['name']} to DynamoDB!")
                
            except Exception as e:
                print(f"AWS save error: {e}, falling back to local storage")
        
        # Always save to local storage as backup
        local_data = load_local_storage()
        local_data[pokemon_name] = data
        save_local_storage(local_data)
        print(f"Saved {data['name']} to local storage!")
        
    except Exception as e:
        print(f"Error saving Pokémon: {e}")

def get_collection_stats():
    """Get statistics about the pokemon collection from all sources"""
    try:
        stats = {"total_pokemon": 0, "pokemon_names": [], "sources": []}
        
        # Check DynamoDB first
        aws_connected, table = check_aws_connection()
        
        if aws_connected:
            try:
                response = table.scan()
                dynamo_pokemon = response.get('Items', [])
                
                if dynamo_pokemon:
                    stats["total_pokemon"] += len(dynamo_pokemon)
                    stats["pokemon_names"].extend([p['name'] for p in dynamo_pokemon])
                    stats["sources"].append(f"DynamoDB ({len(dynamo_pokemon)} Pokémon)")
                    
            except Exception as e:
                print(f"Error reading from DynamoDB: {e}")
        
        # Check local storage
        local_data = load_local_storage()
        if local_data:
            # Remove duplicates between DynamoDB and local
            local_only = {name: data for name, data in local_data.items() 
                         if name not in stats["pokemon_names"]}
            
            if local_only:
                stats["total_pokemon"] += len(local_only)
                stats["pokemon_names"].extend(local_only.keys())
                stats["sources"].append(f"Local storage ({len(local_only)} Pokémon)")
        
        # Remove duplicates and sort
        stats["pokemon_names"] = sorted(list(set(stats["pokemon_names"])))
        stats["total_pokemon"] = len(stats["pokemon_names"])
        
        return stats
        
    except Exception as e:
        print(f"Error getting collection stats: {e}")
        return {"total_pokemon": 0, "pokemon_names": [], "sources": ["Error occurred"]}

def setup_terraform_integration():
    """Setup integration with Terraform-deployed infrastructure"""
    print("\nSetting up Terraform integration...")
    
    # Check if Terraform outputs exist
    terraform_dir = Path(__file__).parent.parent / "terraform"
    if not terraform_dir.exists():
        print("Terraform directory not found")
        return False
    
    # Try to get backend endpoint
    endpoint = get_backend_endpoint()
    if endpoint:
        print(f"Backend endpoint: {endpoint}")
    else:
        print("Backend endpoint not configured (will use local storage)")
    
    # Check AWS connection
    aws_connected, _ = check_aws_connection()
    if aws_connected:
        print("DynamoDB connection successful")
    else:
        print("DynamoDB not available (will use local storage)")
    
    print("Game ready to play!\n")
    return True

def sync_with_backend():
    """Sync local data with backend when connection is available"""
    endpoint = get_backend_endpoint()
    if not endpoint:
        return
    
    try:
        import requests
        local_data = load_local_storage()
        
        for name, pokemon_data in local_data.items():
            # Try to sync each Pokemon to backend
            response = requests.post(f"{endpoint}/pokemon", json=pokemon_data, timeout=5)
            if response.status_code == 200:
                print(f"📤 Synced {name} to backend")
            
    except Exception as e:
        print(f"Sync failed: {e}")

# Initialize when module is imported
if __name__ == "__main__":
    setup_terraform_integration()
>>>>>>> b090d02949d07ea172da0fa95b45ed05ba6b52c1
