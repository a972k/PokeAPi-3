# =============================================================================
# PokeAPI Backend - Production-Ready Modular Docker Setup
# =============================================================================
# Multi-stage build for optimized production deployment
# Supports: Development, Testing, Production environments
# Features: Security hardening, health checks, configurable scaling

# -----------------------------------------------------------------------------
# Build Stage - Dependencies and compilation
# -----------------------------------------------------------------------------
# Use a slim Python base image for reduced size and attack surface
# Install build dependencies with security updates
FROM python:3.12.8-slim-bookworm AS builder
# Install essential build tools and Python dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    build-essential \
    curl \
    && pip install --upgrade pip setuptools wheel && \
    apt-get purge -y gcc build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Build arguments for customization
ARG BUILD_ENV=production
ARG PYTHON_VERSION=3.12

# Set build environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
# Install build dependencies
# (Already installed above for Debian-based image)

# Create virtual environment for clean dependency management
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Install production WSGI server with security extras
RUN pip install gunicorn[gevent] gevent

# -----------------------------------------------------------------------------
# Production Stage - Optimized runtime
# -----------------------------------------------------------------------------
FROM python:3.12.8-slim-bookworm AS production

# Runtime arguments for configuration
ARG APP_PORT=5000
ARG WORKERS=4
ARG WORKER_TIMEOUT=60
ARG KEEP_ALIVE=2
ARG MAX_REQUESTS=1000
ARG MAX_REQUESTS_JITTER=100

# Runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PORT=${APP_PORT} \
    WORKERS=${WORKERS} \
    WORKER_TIMEOUT=${WORKER_TIMEOUT} \
    KEEP_ALIVE=${KEEP_ALIVE} \
    MAX_REQUESTS=${MAX_REQUESTS} \
    MAX_REQUESTS_JITTER=${MAX_REQUESTS_JITTER} \
    FLASK_ENV=production \
    FLASK_DEBUG=0

# Install only runtime dependencies and update all packages to mitigate vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    tini \
    && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

# Create secure non-root user and group
RUN groupadd -g 1001 appgroup && \
    useradd -r -u 1001 -g appgroup -d /app -s /sbin/nologin appuser

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application code with proper ownership
COPY --chown=appuser:appgroup . .

# Create necessary directories and set permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R appuser:appgroup /app && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser

# Health check with configurable endpoint
HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose configurable port
EXPOSE ${PORT}

# Use tini as init system for proper signal handling
ENTRYPOINT ["tini", "--"]

# Default production command with optimized settings
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} --workers ${WORKERS} --worker-class gevent --worker-connections 1000 --timeout ${WORKER_TIMEOUT} --keep-alive ${KEEP_ALIVE} --max-requests ${MAX_REQUESTS} --max-requests-jitter ${MAX_REQUESTS_JITTER} --preload --access-logfile - --error-logfile - --log-level info app:app"]

# -----------------------------------------------------------------------------
# Development Stage - For local development
# -----------------------------------------------------------------------------
FROM production AS development

# Override environment for development
ENV FLASK_ENV=development \
    FLASK_DEBUG=1 \
    WORKERS=1

# Install development dependencies
USER root
RUN pip install --no-cache-dir flask-debugtoolbar pytest pytest-flask

# Switch back to app user
USER appuser

# Development command with hot reload
CMD ["flask", "--app", "app", "run", "--host", "0.0.0.0", "--port", "5000", "--debug"]

# -----------------------------------------------------------------------------
# Testing Stage - For CI/CD pipelines
# -----------------------------------------------------------------------------
FROM development AS testing

# Install testing dependencies
USER root
RUN pip install --no-cache-dir pytest pytest-cov pytest-mock coverage

USER appuser

# Test command
CMD ["python", "-m", "pytest", "-v", "--cov=app", "--cov-report=term-missing"]
