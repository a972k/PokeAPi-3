<<<<<<< HEAD
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

def loading_animation(message="Loading", duration=2):
    """Generic loading animation with customizable message"""
    frames = ["⏳", "⌛", "⏳", "⌛"]
    print(f"{message}", end="")
    
    cycles = int(duration * 4)  # 4 frames per second
    for i in range(cycles):
        frame = frames[i % len(frames)]
        print(f"\r{message} {frame}", end="", flush=True)
        time.sleep(0.25)
    
    print(f"\r{message}... Complete! ✅")

def sync_animation():
    """Animation for synchronizing data with backend"""
    frames = ["🔄", "🔃", "🔄", "🔃"]
    message = "Syncing with backend"
    
    print(f"{message}", end="")
    for i in range(12):  # 3 seconds of animation
        frame = frames[i % len(frames)]
        print(f"\r{message} {frame}", end="", flush=True)
        time.sleep(0.25)
    
    print(f"\r{message}... Complete! ✅")

def connection_test_animation():
    """Animation for testing backend connection"""
    frames = ["📡", "📶", "🌐", "✅"]
    message = "Testing backend connection"
    
    print(f"{message}", end="")
    for i, frame in enumerate(frames):
        print(f"\r{message} {frame}", end="", flush=True)
        time.sleep(0.5)
    
    print(f"\r{message}... Complete! ✅")

def collection_stats_animation():
    """Animation for calculating collection stats"""
    frames = ["📊", "📈", "📉", "📊"]
    message = "Calculating collection statistics"
    
    print(f"{message}", end="")
    for i in range(8):
        frame = frames[i % len(frames)]
        print(f"\r{message} {frame}", end="", flush=True)
        time.sleep(0.3)
    
    print(f"\r{message}... Complete! ✅")

def show_welcome_banner():
    """Display a welcome banner for the enhanced Pokemon game"""
    banner = """
╔══════════════════════════════════════════════════════════════╗
║                    🎮 POKÉMON COLLECTOR 🎮                   ║
║                     Enhanced Edition v2.0                    ║
║                                                              ║
║  🔹 Catch and collect Pokémon from the PokéAPI               ║
║  🔹 Cloud-based storage with AWS backend                     ║
║  🔹 Sync across multiple devices                             ║
║  🔹 Real-time collection statistics                          ║
║                                                              ║
║              Press any key to start your adventure!          ║
╚══════════════════════════════════════════════════════════════╝
    """
    print(banner)

def show_catch_success(pokemon_name):
    """Show success animation when catching a Pokemon"""
    print(f"\n🎉 Congratulations! You caught {pokemon_name.title()}! 🎉")
    
    # Quick celebration animation
    celebration = ["🎊", "🎉", "✨", "🌟", "⭐", "🎊"]
    for frame in celebration:
        print(f"    {frame} {pokemon_name.title()} {frame}", end="\r", flush=True)
        time.sleep(0.3)
    
    print(f"\n✅ {pokemon_name.title()} has been added to your collection!")

def show_error_animation(error_message):
    """Show error animation with message"""
    error_frames = ["❌", "⚠️", "❌", "⚠️"]
    
    for frame in error_frames:
        print(f"\r{frame} {error_message}", end="", flush=True)
        time.sleep(0.5)
    
    print()  # New line after error
=======
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
>>>>>>> b090d02949d07ea172da0fa95b45ed05ba6b52c1
