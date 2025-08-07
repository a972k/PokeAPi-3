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

