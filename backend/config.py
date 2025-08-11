# =============================================================================
# PokeAPI Backend - Centralized Configuration
# =============================================================================
# Single source of truth for all backend configuration
# This file handles environment variables, defaults, and validation

import os
import logging
from typing import Optional
from dataclasses import dataclass

# Configure logging for config module
logger = logging.getLogger(__name__)

@dataclass
class DatabaseConfig:
    """MongoDB database configuration"""
    host: str
    port: int
    database: str
    collection: str
    username: Optional[str] = None
    password: Optional[str] = None
    uri: Optional[str] = None
    
    @property
    def connection_string(self) -> str:
        """Generate MongoDB connection string"""
        if self.uri:
            return self.uri
        
        if self.username and self.password:
            return f"mongodb://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}?authSource=admin"
        else:
            return f"mongodb://{self.host}:{self.port}/{self.database}"

@dataclass
class APIConfig:
    """Flask API configuration"""
    host: str
    port: int
    debug: bool
    secret_key: str
    log_level: str
    cors_enabled: bool = True
    
@dataclass
class ExternalAPIConfig:
    """External API configuration"""
    pokeapi_base_url: str
    timeout: int = 30
    retries: int = 3

@dataclass
class AppConfig:
    """Complete application configuration"""
    database: DatabaseConfig
    api: APIConfig
    external_apis: ExternalAPIConfig
    environment: str
    
    def is_production(self) -> bool:
        return self.environment.lower() == 'production'
    
    def is_development(self) -> bool:
        return self.environment.lower() in ['development', 'dev']

class ConfigError(Exception):
    """Configuration validation error"""
    pass

def get_env_bool(key: str, default: bool = False) -> bool:
    """Get boolean environment variable"""
    value = os.getenv(key, str(default)).lower()
    return value in ('true', '1', 'yes', 'on')

def get_env_int(key: str, default: int) -> int:
    """Get integer environment variable"""
    try:
        return int(os.getenv(key, str(default)))
    except ValueError:
        logger.warning(f"Invalid integer value for {key}, using default: {default}")
        return default

def get_env_str(key: str, default: str = "") -> str:
    """Get string environment variable"""
    return os.getenv(key, default)

def load_config() -> AppConfig:
    """
    Load and validate complete application configuration
    
    Returns:
        AppConfig: Validated configuration object
        
    Raises:
        ConfigError: If required configuration is missing or invalid
    """
    
    # ==========================================================================
    # Environment Detection
    # ==========================================================================
    environment = get_env_str('FLASK_ENV', 'development')
    logger.info(f"Loading configuration for environment: {environment}")
    
    # ==========================================================================
    # Database Configuration
    # ==========================================================================
    database_config = DatabaseConfig(
        host=get_env_str('MONGO_HOST', 'mongodb'),
        port=get_env_int('MONGO_PORT', 27017),
        database=get_env_str('MONGO_DB', 'pokeapi_game'),
        collection=get_env_str('MONGO_COLLECTION', 'pokemon_collection'),
        username=get_env_str('MONGO_ROOT_USERNAME') or None,
        password=get_env_str('MONGO_ROOT_PASSWORD') or None,
        uri=get_env_str('MONGO_URI') or None
    )
    
    # ==========================================================================
    # API Configuration
    # ==========================================================================
    # Determine defaults based on environment
    is_prod = environment.lower() == 'production'
    default_debug = not is_prod
    default_log_level = 'WARNING' if is_prod else 'INFO'
    
    api_config = APIConfig(
        host=get_env_str('API_HOST', '0.0.0.0'),
        port=get_env_int('PORT', 5000),  # PORT is standard for cloud deployments
        debug=get_env_bool('FLASK_DEBUG', default_debug),
        secret_key=get_env_str('SECRET_KEY', 'dev-secret-key-change-in-production'),
        log_level=get_env_str('LOG_LEVEL', default_log_level),
        cors_enabled=get_env_bool('CORS_ENABLED', True)
    )
    
    # ==========================================================================
    # External APIs Configuration
    # ==========================================================================
    external_apis_config = ExternalAPIConfig(
        pokeapi_base_url=get_env_str('POKEAPI_BASE_URL', 'https://pokeapi.co/api/v2'),
        timeout=get_env_int('EXTERNAL_API_TIMEOUT', 30),
        retries=get_env_int('EXTERNAL_API_RETRIES', 3)
    )
    
    # ==========================================================================
    # Configuration Validation
    # ==========================================================================
    config = AppConfig(
        database=database_config,
        api=api_config,
        external_apis=external_apis_config,
        environment=environment
    )
    
    # Validate production requirements
    if config.is_production():
        if config.api.secret_key in ['dev-secret-key-change-in-production', 'GENERATE_SECURE_RANDOM_KEY_FOR_PRODUCTION']:
            raise ConfigError("SECRET_KEY must be set to a secure value in production!")
        
        if config.api.debug:
            logger.warning("DEBUG mode is enabled in production - this is not recommended!")
    
    # Log configuration summary (without sensitive data)
    logger.info("Configuration loaded successfully:")
    logger.info(f"  Environment: {config.environment}")
    logger.info(f"  API: {config.api.host}:{config.api.port}")
    logger.info(f"  Database: {config.database.host}:{config.database.port}/{config.database.database}")
    logger.info(f"  Debug: {config.api.debug}")
    logger.info(f"  Log Level: {config.api.log_level}")
    
    return config

# =============================================================================
# Global Configuration Instance
# =============================================================================
# This will be imported by other modules
try:
    config = load_config()
except Exception as e:
    logger.error(f"Failed to load configuration: {e}")
    raise

# =============================================================================
# Convenience Functions for Backward Compatibility
# =============================================================================
def get_database_config() -> DatabaseConfig:
    """Get database configuration"""
    return config.database

def get_api_config() -> APIConfig:
    """Get API configuration"""
    return config.api

def get_external_api_config() -> ExternalAPIConfig:
    """Get external API configuration"""
    return config.external_apis

# =============================================================================
# Configuration Summary for Debugging
# =============================================================================
def print_config_summary():
    """Print configuration summary for debugging"""
    print("=" * 50)
    print("POKEAPI BACKEND CONFIGURATION")
    print("=" * 50)
    print(f"Environment: {config.environment}")
    print(f"API Host: {config.api.host}:{config.api.port}")
    print(f"Debug Mode: {config.api.debug}")
    print(f"Log Level: {config.api.log_level}")
    print(f"Database: {config.database.host}:{config.database.port}")
    print(f"Database Name: {config.database.database}")
    print(f"Collection: {config.database.collection}")
    print(f"PokeAPI URL: {config.external_apis.pokeapi_base_url}")
    print(f"CORS Enabled: {config.api.cors_enabled}")
    print("=" * 50)

if __name__ == '__main__':
    # When run directly, print configuration summary
    print_config_summary()
