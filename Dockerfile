# Stage 1: Builder (install dependencies)
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_DEFAULT_TIMEOUT=100

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pip dependencies into /install directory
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt --root-user-action=ignore

# Copy project files
COPY . .

# Stage 2: Web runtime
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
RUN useradd --create-home appuser
USER appuser

# Set environment variables
ENV PATH="/home/appuser/.local/bin:$PATH"
ENV PYTHONPATH="/app"

# Copy installed packages from builder
COPY --from=builder --chown=appuser:appuser /install /usr/local
COPY --chown=appuser:appuser . .

# Generate a secure secret key if not set (for development only)
RUN if [ -z "$SECRET_KEY" ]; then \
        export SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'); \
    fi

# Collect static files
RUN python manage.py collectstatic --noinput --clear || echo "Warning: Collectstatic failed, but continuing build"

# Expose the port the app runs on
EXPOSE 8000

# Command for Django + Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "4", "ecommerce.wsgi"]
