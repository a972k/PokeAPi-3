import time
import sys

def pokeball_animation():
    """Display a cool pokeball animation while fetching Pokémon data"""
    
    # Pokeball ASCII art frames
    frames = [
        """
    ⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪
 ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚫⚫⚫⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
 ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪
    ⚪⚪⚪⚪⚪⚪⚪
        """,
        """
    🔴🔴🔴🔴🔴🔴🔴
  🔴🔴🔴🔴🔴🔴🔴🔴🔴
 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴⚫⚫⚫🔴🔴🔴🔴
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
 ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪
    ⚪⚪⚪⚪⚪⚪⚪
        """,
        """
    🔴🔴🔴🔴🔴🔴🔴
  🔴🔴🔴🔴🔴🔴🔴🔴🔴
 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
🔴🔴🔴🔴🟡🟡🟡🔴🔴🔴🔴
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
 ⚪⚪⚪⚪⚪⚪⚪⚪⚪⚪
  ⚪⚪⚪⚪⚪⚪⚪⚪⚪
    ⚪⚪⚪⚪⚪⚪⚪
        """
    ]
    
    print("Fetching new Pokémon data...")
    
    # Animate the pokeball
    for i in range(6):  # Show animation for about 1.5 seconds
        for frame in frames:
            # Clear previous frame and show new one
            sys.stdout.write('\033[H\033[J')  # Clear screen
            print("Fetching new Pokémon data...")
            print(frame)
            sys.stdout.flush()
            time.sleep(0.25)
    
    # Clear the animation
    sys.stdout.write('\033[H\033[J')
    print("Fetching new Pokémon data...  Done!")

def simple_pokeball():
    """Simple pokeball animation without clearing screen (fallback)"""
    pokeball_frames = ["⚪", "🔴", "🟡", "⚪"]
    print("Fetching new Pokémon data", end="")
    
    for _ in range(8):
        for frame in pokeball_frames:
            print(f" {frame}", end="", flush=True)
            time.sleep(0.3)
    
    print(" Done! ")
