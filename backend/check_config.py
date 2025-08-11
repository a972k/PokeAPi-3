#!/usr/bin/env python3
# =============================================================================
# Configuration Validator and Inspector
# =============================================================================
# Quick script to check configuration and troubleshoot issues

import sys
import os

# Add the backend directory to the path so we can import config
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def main():
    print("PokeAPI Backend Configuration Inspector")
    print("=" * 50)
    
    try:
        # Import and load configuration
        from config import config, print_config_summary
        
        print("Configuration loaded successfully!")
        print()
        
        # Print detailed summary
        print_config_summary()
        
        # Validation checks
        print("\nConfiguration Validation:")
        print("-" * 30)
        
        # Check production readiness
        if config.is_production():
            issues = []
            
            if config.api.secret_key in ['dev-secret-key-not-for-production', 'REPLACE_WITH_SECURE_RANDOM_KEY_FOR_PRODUCTION']:
                issues.append("SECRET_KEY is not set to a secure value")
            else:
                print("SECRET_KEY is configured")
            
            if config.api.debug:
                issues.append("DEBUG mode is enabled (not recommended for production)")
            else:
                print("DEBUG mode is disabled")
            
            if config.database.username and config.database.password:
                print("Database authentication is configured")
            else:
                issues.append("Database authentication is not configured")
            
            if issues:
                print("\nProduction Issues Found:")
                for issue in issues:
                    print(f"  {issue}")
                print("\nFix these issues before deploying to production!")
            else:
                print("\nConfiguration is production-ready!")
        
        else:
            print("Development configuration looks good!")
        
        # Connection test
        print(f"\nTesting MongoDB connection...")
        try:
            from pymongo import MongoClient
            client = MongoClient(config.database.connection_string, serverSelectionTimeoutMS=5000)
            client.admin.command('ping')
            print("MongoDB connection successful!")
        except Exception as e:
            print(f"MongoDB connection failed: {e}")
            print("Make sure MongoDB is running (try: docker-compose up mongodb)")
        
    except Exception as e:
        print(f"Configuration failed to load: {e}")
        print("\nCommon issues:")
        print("  - Missing environment variables")
        print("  - Invalid environment file")
        print("  - Typos in variable names")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())
