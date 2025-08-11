<<<<<<< HEAD
import random
from storage import get_pokemon, save_pokemon, get_collection_stats, setup_game, sync_with_backend
from pokeapi import fetch_all_pokemon_names, fetch_pokemon_details, check_backend_health
from display import display_pokemon

# Import animations with fallback for environments where animations are not available
try:
    from animations import simple_pokeball
except ImportError:
    def simple_pokeball():
        """Fallback animation function when animations module is not available"""
        print("Catching Pokemon...")

def main():
    """
    Main game function that handles the Pokemon Collection Game loop.
    
    Game Features:
    - Catch random Pokemon from PokeAPI
    - Store Pokemon in local cache and backend database
    - View collection statistics
    - Sync data between local storage and backend API
    - Check backend connectivity status
    """
    print("Welcome to the Pokemon Collection Game!")
    print("=" * 50)
    
    # Initialize game setup and check backend/local storage connections
    setup_game()
    
    # Main game loop - continues until user chooses to quit
    while True:
        print("\nWhat would you like to do?")
        print("1. Catch a random Pokemon (yes)")
        print("2. View collection stats (stats)")
        print("3. Sync with backend (sync)")
        print("4. Check backend status (status)")
        print("5. Quit game (no)")
        
        choice = input("\nEnter your choice: ").strip().lower()

        if choice in ["yes", "1", "catch"]:
            catch_pokemon()
        
        elif choice in ["stats", "2", "collection"]:
            show_collection_stats()
        
        elif choice in ["sync", "3"]:
            sync_collection()
            
        elif choice in ["status", "4", "health"]:
            check_system_status()
        
        elif choice in ["no", "5", "quit", "exit"]:
            print("Thanks for playing! See you next time, trainer!")
            break

        else:
            print("Please enter a valid choice (1-5, or yes/stats/sync/status/no)")

def catch_pokemon():
    """
    Catch a random Pokemon from the PokeAPI.
    
    Process:
    1. Fetch list of all available Pokemon names
    2. Randomly select one Pokemon
    3. Check if already in collection
    4. Fetch detailed Pokemon data from PokeAPI
    5. Save to local storage and backend (if available)
    6. Display Pokemon information to user
    """
    print("\nCatching a random Pokemon...")
    
    # Get list of all Pokemon names from PokeAPI
    all_names = fetch_all_pokemon_names()
    if not all_names:
        print("Failed to fetch Pokemon list. Check your internet connection.")
        return

    # Select random Pokemon from the available list
    selected = random.choice(all_names)
    print(f"Selected: {selected.title()}")
    
    # Check if this Pokemon is already in the collection
    pokemon_data = get_pokemon(selected)

    if pokemon_data:
        print(f"[ALREADY CAUGHT] {selected.title()} is already in your collection!")
        display_pokemon(pokemon_data)
    else:
        # Show catching animation while fetching data
        simple_pokeball()
        
        # Fetch detailed Pokemon information from PokeAPI
        print(f"Fetching {selected.title()} from PokeAPI...")
        details = fetch_pokemon_details(selected)
        
        if details:
            # Save Pokemon to both local storage and backend (if available)
            save_pokemon(details)
            print(f"Successfully caught {selected.title()}!")
            display_pokemon(details)
        else:
            print(f"Failed to fetch {selected.title()} details. Try again.")

def show_collection_stats():
    """
    Display detailed statistics about the Pokemon collection.
    
    Shows:
    - Total number of Pokemon caught
    - Data sources (local cache, backend API)
    - Collection distribution by type
    - Recent catches
    """
    print("\nCollection Statistics")
    print("-" * 30)
    
    stats = get_collection_stats()
    print(f"Total Pokemon: {stats['total_pokemon']}")
    
    if stats.get("sources"):
        print(f"Data sources: {', '.join(stats['sources'])}")
    
    if stats.get("latest_catch"):
        print(f"Latest catch: {stats['latest_catch']}")
    
    # Show Pokemon list if collection is manageable size
    if stats["pokemon_names"] and len(stats["pokemon_names"]) <= 20:
        print("\nYour Pokemon:")
        for i, name in enumerate(sorted(stats["pokemon_names"]), 1):
            print(f"  {i:2d}. {name.title()}")
    elif stats["pokemon_names"]:
        print(f"\nYou have {len(stats['pokemon_names'])} Pokemon (too many to list)")
    else:
        print("\nYour collection is empty - time to catch some Pokemon!")

def sync_collection():
    """
    Synchronize local Pokemon collection with the backend API.
    
    Process:
    1. Check backend API health/availability
    2. Upload local collection data to backend
    3. Download any missing Pokemon from backend
    4. Resolve conflicts between local and backend data
    """
    print("\nSyncing collection with backend...")
    
    if not check_backend_health():
        print("[ERROR] Backend is not available for sync")
        return
    
    success = sync_with_backend()
    if success:
        print("[SUCCESS] Sync completed successfully!")
    else:
        print("[ERROR] Sync failed - check backend connection")

def check_system_status():
    """
    Check the status of various game systems and connections.
    
    Verifies:
    - Local storage system functionality
    - Backend API connectivity and health
    - PokeAPI external service availability
    - File system permissions and paths
    """
    print("\nSystem Status")
    print("-" * 20)
    
    # Check backend API connectivity
    if check_backend_health():
        print("[OK] Backend API: Connected")
    else:
        print("[FAIL] Backend API: Disconnected")
    
    # Check PokeAPI external service connectivity
    try:
        names = fetch_all_pokemon_names()
        if names:
            print("[OK] PokeAPI: Connected")
        else:
            print("[FAIL] PokeAPI: No data received")
    except Exception as e:
        print(f"[FAIL] PokeAPI: Error - {e}")
    
    # Check local storage system
    try:
        stats = get_collection_stats()
        print(f"[OK] Local Storage: {stats['total_pokemon']} Pokemon stored")
    except Exception as e:
        print(f"[FAIL] Local Storage: Error - {e}")

if __name__ == "__main__":
    """
    Main entry point for the Pokemon Collection Game.
    
    Initializes the game environment and starts the main game loop.
    Handles keyboard interrupts gracefully for clean exit.
    """
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nGame interrupted by user. Goodbye!")
    except Exception as e:
        print(f"\nUnexpected error occurred: {e}")
        print("Please report this issue if it persists.")

=======
import random
from storage import get_pokemon, save_pokemon, get_collection_stats
from pokeapi import fetch_all_pokemon_names, fetch_pokemon_details
from display import display_pokemon
from animations import simple_pokeball

# pokemon drawing game that uses PokeAPI + local storage
def main():
    print("🎮 Welcome to the Pokémon Drawing Game! 🎮")
    
    # Show collection stats
    stats = get_collection_stats()
    if stats["total_pokemon"] > 0:
        print(f"📚 You have {stats['total_pokemon']} Pokémon in your collection!")
    else:
        print("📚 Your collection is empty. Let's catch some Pokémon!")
    
    print()

    # main game loop
    while True:
        choice = input("Would you like to draw a Pokémon? (yes/no/stats): ").strip().lower()

        if choice == "yes":
            all_names = fetch_all_pokemon_names()
            if not all_names:
                print("❌ Failed to fetch Pokémon list. Try again.")
                continue

            selected = random.choice(all_names)
            pokemon_data = get_pokemon(selected)

            if pokemon_data:
                print(f"✅ {selected.title()} already in your collection!")
                display_pokemon(pokemon_data)
            else:
                # Show pokeball animation while fetching
                simple_pokeball()
                details = fetch_pokemon_details(selected)
                if details:
                    save_pokemon(details)
                    display_pokemon(details)
                else:
                    print("❌ Failed to fetch Pokémon details.")
        
        elif choice == "stats":
            stats = get_collection_stats()
            print(f"\n📊 Collection Statistics:")
            print(f"Total Pokémon: {stats['total_pokemon']}")
            if stats["pokemon_names"]:
                print("Your Pokémon:")
                for name in sorted(stats["pokemon_names"]):
                    print(f"  - {name.title()}")
            print()
        
        elif choice == "no":
            print("👋 Thanks for playing! See you next time, trainer!")
            break

        else:
            print("❓ Please enter 'yes', 'no', or 'stats'.")

if __name__ == "__main__":
    main()

>>>>>>> b090d02949d07ea172da0fa95b45ed05ba6b52c1
