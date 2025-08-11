# Flask API for PokeAPI Game Backend
# This connects to MongoDB and provides CRUD endpoints for Pokemon collection

from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime
import logging

# Import centralized configuration
from config import config, ConfigError

# Configure logging based on config
logging.basicConfig(
    level=getattr(logging, config.api.log_level.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Configure Flask app from centralized config
app.config['SECRET_KEY'] = config.api.secret_key
app.config['DEBUG'] = config.api.debug

# Enable CORS if configured
if config.api.cors_enabled:
    CORS(app)
    logger.info("CORS enabled for frontend connections")

# Initialize MongoDB connection using centralized config
try:
    connection_string = config.database.connection_string
    client = MongoClient(connection_string)
    db = client[config.database.database]
    collection = db[config.database.collection]
    
    # Test the connection
    client.admin.command('ping')
    
    logger.info(f"Connected to MongoDB at {config.database.host}:{config.database.port}")
    logger.info(f"Using database: {config.database.database}, collection: {config.database.collection}")
    
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {e}")
    raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Test MongoDB connection
        client.admin.command('ping')
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected"
        }), 200
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/pokemon', methods=['GET'])
def get_all_pokemon():
    """Get all Pokemon in collection"""
    try:
        pokemon_list = list(collection.find({}, {'_id': 0}))
        return jsonify({
            "pokemon": pokemon_list,
            "count": len(pokemon_list)
        }), 200
    except Exception as e:
        logger.error(f"Error fetching Pokemon: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/pokemon/<name>', methods=['GET'])
def get_pokemon(name):
    """Get specific Pokemon by name"""
    try:
        pokemon = collection.find_one({"name": name.lower()}, {'_id': 0})
        if pokemon:
            return jsonify(pokemon), 200
        else:
            return jsonify({"error": "Pokemon not found"}), 404
    except Exception as e:
        logger.error(f"Error fetching Pokemon {name}: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/pokemon', methods=['POST'])
def add_pokemon():
    """Add new Pokemon to collection"""
    try:
        pokemon_data = request.get_json()
        
        if not pokemon_data or 'name' not in pokemon_data:
            return jsonify({"error": "Pokemon name is required"}), 400
        
        # Check if Pokemon already exists
        existing = collection.find_one({"name": pokemon_data['name'].lower()})
        if existing:
            return jsonify({"error": "Pokemon already in collection"}), 409
        
        # Add timestamp
        pokemon_data['caught_at'] = datetime.now().isoformat()
        pokemon_data['name'] = pokemon_data['name'].lower()
        
        # Insert into MongoDB
        result = collection.insert_one(pokemon_data)
        
        return jsonify({
            "message": "Pokemon added successfully",
            "name": pokemon_data['name']
        }), 201
        
    except Exception as e:
        logger.error(f"Error adding Pokemon: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/pokemon/<name>', methods=['DELETE'])
def delete_pokemon(name):
    """Delete Pokemon from collection"""
    try:
        result = collection.delete_one({"name": name.lower()})
        
        if result.deleted_count > 0:
            return jsonify({"message": f"Pokemon {name} deleted successfully"}), 200
        else:
            return jsonify({"error": "Pokemon not found"}), 404
            
    except Exception as e:
        logger.error(f"Error deleting Pokemon {name}: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get collection statistics"""
    try:
        total_count = collection.count_documents({})
        
        # Get some additional stats
        pipeline = [
            {"$group": {
                "_id": None,
                "total": {"$sum": 1},
                "latest": {"$max": "$caught_at"}
            }}
        ]
        
        stats_result = list(collection.aggregate(pipeline))
        
        stats = {
            "total_pokemon": total_count,
            "latest_catch": stats_result[0]["latest"] if stats_result else None
        }
        
        return jsonify(stats), 200
        
    except Exception as e:
        logger.error(f"Error fetching stats: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/sync', methods=['POST'])
def sync_data():
    """Sync local data to backend (for game integration)"""
    try:
        sync_data = request.get_json()
        
        if not sync_data:
            return jsonify({"error": "No data provided"}), 400
        
        synced_count = 0
        
        for name, pokemon_data in sync_data.items():
            # Check if already exists
            existing = collection.find_one({"name": name.lower()})
            
            if not existing:
                pokemon_data['name'] = name.lower()
                pokemon_data['synced_at'] = datetime.now().isoformat()
                collection.insert_one(pokemon_data)
                synced_count += 1
        
        return jsonify({
            "message": f"Synced {synced_count} Pokemon",
            "synced_count": synced_count
        }), 200
        
    except Exception as e:
        logger.error(f"Error syncing data: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Use centralized configuration for startup
    logger.info(f"Starting Flask API on {config.api.host}:{config.api.port}")
    logger.info(f"Environment: {config.environment}")
    logger.info(f"Debug mode: {config.api.debug}")
    
    app.run(
        host=config.api.host, 
        port=config.api.port, 
        debug=config.api.debug
    )
