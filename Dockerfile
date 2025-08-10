# Builder stage
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    # Set a default SECRET_KEY for build time
    SECRET_KEY=build-key-temporary

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Final stage
FROM python:3.11-slim

# Set environment variables with defaults
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.local/bin:$PATH" \
    # Set default SECRET_KEY that will be overridden by environment if provided
    SECRET_KEY=default-insecure-key-change-me

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and set work directory
WORKDIR /app

# Create a non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Copy Python wheels from builder
COPY --from=builder --chown=appuser:appuser /app/wheels /wheels

# Install application dependencies first (faster builds when only code changes)
RUN pip install --no-cache /wheels/*

# Copy application code
COPY --chown=appuser:appuser . .

# Generate a secure secret key if not set (for development only)
RUN if [ "$SECRET_KEY" = "default-insecure-key-change-me" ]; then \
    export SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'); \
    fi

# Collect static files (will use the generated or provided SECRET_KEY)
RUN python manage.py collectstatic --noinput || echo "Warning: Collectstatic failed, but continuing build"

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "4"]
