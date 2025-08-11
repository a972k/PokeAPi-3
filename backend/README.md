# PokeAPI Backend - Modular Docker Setup

A production-ready, modular Docker setup for the PokeAPI game backend with Flask API, MongoDB, and centralized configuration management.

## Architecture Overview

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flask API     │    │    MongoDB      │    │  Configuration  │
│   (Python 3.12)│────│   (Version 7.0) │    │   Management    │
│   Port: 5000    │    │   Port: 27017   │    │   (config.py)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Development Mode

```bash
# Easy way (recommended)
.\deploy.ps1

# Traditional way
docker-compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up
```

### Production Mode

```bash
# Easy way (recommended)
.\deploy.ps1 -Environment prod -Detach

# Traditional way
copy .env.prod.template .env.prod
# Edit .env.prod with secure passwords
docker-compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Configuration Check

```bash
# Validate configuration and test connections
python check_config.py
```

## 📁 Project Structure

```text
backend/
├── Dockerfile                 # Multi-stage production-ready build
├── docker-compose.yml         # Base compose configuration
├── docker-compose.dev.yml     # Development overrides
├── docker-compose.prod.yml    # Production overrides
├── .dockerignore              # Optimized build context
├── .env.dev                   # Development environment variables
├── .env.prod.template         # Production environment template
├── config.py                  # Centralized configuration management
├── check_config.py            # Configuration validator and tester
├── app.py                     # Flask application
├── requirements.txt           # Python dependencies
├── deploy.ps1                 # Windows deployment script
├── deploy.sh                  # Linux/Mac deployment script
├── logs/                      # Application logs directory
└── mongo-init/                # MongoDB initialization scripts
```

## ⚙️ **New: Centralized Configuration System**

The backend now uses a centralized configuration system for better maintainability:

### Key Features

- **Single Source of Truth**: All settings managed in `config.py`
- **Smart Defaults**: Automatic environment detection and sensible defaults
- **Type Safety**: Automatic conversion of environment variables to correct types
- **Validation**: Prevents common configuration errors
- **Easy Debugging**: `check_config.py` validates and tests your setup

### Quick Commands

```bash
# Check configuration status
python check_config.py

# Start development (uses centralized config)
.\deploy.ps1

# Start production (uses centralized config)
.\deploy.ps1 -Environment prod -Detach
```

## 🛠️ Available Build Targets

The Dockerfile supports multiple build targets:

### 1. Production (Default)

- Optimized for performance and security
- Multi-worker Gunicorn with gevent
- Non-root user execution
- Health checks and signal handling

### 2. Development

- Hot reload with Flask development server
- Debug mode enabled
- Development tools included
- Single worker for easier debugging

### 3. Testing

- Includes testing frameworks (pytest, coverage)
- CI/CD ready
- Code coverage reporting

## 🔧 Configuration Options

### Centralized Configuration System

All configuration is now managed through `config.py` with smart defaults and validation:

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | `development` | Environment mode (development/production) |
| `PORT` | `5000` | API server port |
| `MONGO_HOST` | `mongodb` | MongoDB hostname |
| `MONGO_DB` | `pokeapi_game` | MongoDB database name |
| `SECRET_KEY` | `dev-key` | Flask secret key (must be secure in production) |
| `LOG_LEVEL` | `INFO` | Logging level (DEBUG/INFO/WARNING/ERROR) |

### Environment Files

**Development** (`.env.dev`):

- Simplified settings with smart defaults
- No authentication required for MongoDB
- Debug mode enabled

**Production** (`.env.prod`):

- Security-focused configuration
- Required authentication for MongoDB
- Performance optimizations enabled

### Configuration Validation

```bash
# Check configuration and test connections
python check_config.py

# Output example:
✅ Configuration loaded successfully!
✅ Development configuration looks good!  
✅ MongoDB connection successful!
```

### Resource Limits

Each service has configurable resource limits:

**Development:**

- API: 128M RAM, 0.25 CPU
- MongoDB: 256M RAM, 0.25 CPU

**Production:**

- API: 512M RAM, 1.0 CPU
- MongoDB: 1G RAM, 1.0 CPU

## 📊 Health Checks & Monitoring

### Health Check Endpoints

- **API Health**: `GET /health`
- **MongoDB**: Internal ping command

### Monitoring Features

- Container health checks every 30s
- Automatic restart on failure
- Resource usage monitoring
- Production log rotation

## 🔐 Security Features

### Production Security

- Non-root user execution
- Secure MongoDB authentication
- No unnecessary port exposure
- Security-hardened base images
- Secrets management ready

### Development Security

- Simplified authentication for dev
- Debug mode for troubleshooting
- Port exposure for testing

## 🚀 Deployment Commands

### **New: Easy Deployment Scripts**

The easiest way to deploy is using the new deployment scripts:

```bash
# Development (Windows)
.\deploy.ps1

# Production (Windows)
.\deploy.ps1 -Environment prod -Detach

# Check logs
.\deploy.ps1 -Environment prod -Action logs

# Stop services
.\deploy.ps1 -Environment prod -Action down

# Linux/Mac equivalents
./deploy.sh
./deploy.sh --env prod --detach
```

### Traditional Docker Compose Commands

```bash
# Build and start development
docker-compose up --build

# Start in background (production)
docker-compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d

# View logs
docker-compose logs -f api
docker-compose logs -f mongodb

# Stop services
docker-compose down

# Remove volumes (careful!)
docker-compose down -v
```

### Scaling (Production)

```bash
# Scale API to 3 replicas
docker-compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d --scale api=3
```

### Development with Hot Reload

```bash
# Start development with source mounting
docker-compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up
```

## 🧪 Testing

### Run Tests in Container

```bash
# Build test target
docker build --target testing -t pokeapi-test .

# Run tests
docker run --rm pokeapi-test

# Run with coverage
docker run --rm pokeapi-test pytest --cov=app --cov-report=html
```

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/pokemon` | List all Pokemon |
| `POST` | `/pokemon` | Add new Pokemon |
| `GET` | `/pokemon/{id}` | Get Pokemon by ID |
| `PUT` | `/pokemon/{id}` | Update Pokemon |
| `DELETE` | `/pokemon/{id}` | Delete Pokemon |
| `POST` | `/sync` | Sync with PokeAPI |

## 🔍 Troubleshooting

### **New: Configuration Issues**

First, always check your configuration:

```bash
# Validate configuration and test connections
python check_config.py

# Common configuration issues it catches:
✅ Missing environment variables
✅ Invalid database connections
✅ Production security problems
✅ Type conversion errors
```

### Common Issues

**Configuration problems:**

```bash
# Check configuration first
python check_config.py

# If config is wrong, fix .env.dev or .env.prod
# Then restart services
.\deploy.ps1 -Action restart
```

**Container won't start:**

```bash
# Check logs with easy command
.\deploy.ps1 -Action logs

# Or traditional way
docker-compose logs api

# Check container status
docker-compose ps

# Rebuild with no cache
.\deploy.ps1 -Build
```

**Database connection issues:**

```bash
# Configuration checker tests MongoDB automatically
python check_config.py

# Manual MongoDB health check
docker-compose exec mongodb mongosh --eval "db.runCommand('ping')"

# Check environment variables
docker-compose exec api env | grep MONGO
```

**Permission denied errors:**

```bash
# Fix log directory permissions
mkdir -p logs
chmod 755 logs
```

### Performance Tuning

**Development:**

- Use `docker-compose.dev.yml` for hot reload
- Single worker for easier debugging
- Debug logging enabled

**Production:**

- Multiple workers for concurrency
- Resource limits for stability
- Optimized logging levels

## 🔄 Environment Migration

### Development → Production

1. Copy production template:

   ```bash
   cp .env.prod.template .env.prod
   ```

2. Update secure values:
   - `MONGO_ROOT_PASSWORD`: Strong password
   - `SECRET_KEY`: Random secure key
   - Resource limits as needed

3. Deploy:

   ```bash
   docker-compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

## 📚 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Gunicorn Documentation](https://gunicorn.org/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test with development environment
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
