// MongoDB initialization script for PokeAPI Game
// This script runs when MongoDB container starts for the first time

// Switch to the pokeapi_game database
db = db.getSiblingDB('pokeapi_game');

// Create pokemon_collection with validation
db.createCollection('pokemon_collection', {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["name"],
         properties: {
            name: {
               bsonType: "string",
               description: "Pokemon name must be a string and is required"
            },
            id: {
               bsonType: "number",
               description: "Pokemon ID from PokeAPI"
            },
            height: {
               bsonType: "number",
               description: "Pokemon height"
            },
            weight: {
               bsonType: "number",
               description: "Pokemon weight"
            },
            types: {
               bsonType: "array",
               description: "Pokemon types array"
            },
            abilities: {
               bsonType: "array", 
               description: "Pokemon abilities array"
            },
            sprites: {
               bsonType: "object",
               description: "Pokemon sprite URLs"
            },
            caught_at: {
               bsonType: "string",
               description: "ISO timestamp when Pokemon was caught"
            }
         }
      }
   }
});

// Create indexes for better performance
db.pokemon_collection.createIndex({ "name": 1 }, { unique: true });
db.pokemon_collection.createIndex({ "caught_at": -1 });
db.pokemon_collection.createIndex({ "id": 1 });

// Insert sample data for testing
db.pokemon_collection.insertOne({
   name: "pikachu",
   id: 25,
   height: 4,
   weight: 60,
   types: ["electric"],
   abilities: ["static", "lightning-rod"],
   sprites: {
      front_default: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
   },
   caught_at: new Date().toISOString()
});

print("PokeAPI Game database initialized successfully!");
print("Created pokemon_collection with validation and indexes.");
print("Inserted sample Pikachu for testing.");
