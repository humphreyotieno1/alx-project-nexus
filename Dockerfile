# Stage 1: Builder (install dependencies)
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pip dependencies into /install directory
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt --root-user-action=ignore


# Copy project files
COPY . .

# Stage 2: Web runtime
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Set environment variables
ENV PATH="/home/appuser/.local/bin:$PATH"
ENV PYTHONPATH="/app"
ENV SECRET_KEY="django-insecure-temporary-key-for-build-only"

# Copy installed packages from builder
COPY --from=builder --chown=appuser:appuser /install /usr/local

# Copy application code
COPY --chown=appuser:appuser . .

# Generate a secure secret key if not set (for development only)
RUN if [ "$SECRET_KEY" = "django-insecure-temporary-key-for-build-only" ]; then \
        export SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'); \
    fi && \
    python manage.py collectstatic --noinput || echo "Warning: Collectstatic failed, but continuing build"

# Command for Django + Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "--workers", "4", "--threads", "4", "ecommerce.wsgi"]
