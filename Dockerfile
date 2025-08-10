# Builder stage
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

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

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.local/bin:$PATH"

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
COPY --chown=appuser:appuser . .

# Install application dependencies
RUN pip install --no-cache /wheels/*

# Collect static files
RUN python manage.py collectstatic --noinput || echo "Warning: Collectstatic failed, but continuing build"

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "4"]
