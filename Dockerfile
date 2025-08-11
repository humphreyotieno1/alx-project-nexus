# Stage 1: Build dependencies
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.local/bin:$PATH" \
    # Default values for build time
    SECRET_KEY=ucuqp5616lwcb8&ne1-a^r*^rs9%!-wa$t!m@zbrog60u=cj_7 \
    DEBUG=False \
    ALLOWED_HOSTS=.onrender.com, \
    FRONTEND_URL=http://localhost:3000 \
    DATABASE_URL=postgresql://neondb_owner:npg_NKBSZ0n3Tzeu@ep-silent-resonance-a8om4bn6-pooler.eastus2.azure.neon.tech/neondb?sslmode=require&channel_binding=require \
    DJANGO_SETTINGS_MODULE=ecommerce.settings \
    # Add other default environment variables here
    CELERY_BROKER_URL=redis://redis:6379/0 \
    CELERY_RESULT_BACKEND=redis://redis:6379/0

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/staticfiles \
    && mkdir -p /app/mediafiles \
    && chmod -R 755 /app/staticfiles \
    && chmod -R 755 /app/mediafiles

# Copy Python wheels from builder
COPY --from=builder /app/wheels /wheels

# Install application dependencies
RUN pip install --no-cache /wheels/* \
    && rm -rf /wheels \
    && rm -rf /root/.cache/pip/*

# Copy project
COPY . .

# Create a script to handle collectstatic with fallbacks and run the application
RUN echo '#!/bin/sh\n\
# Set default environment variables if not set\n\
if [ -z "$SECRET_KEY" ]; then\n\
    export SECRET_KEY="ucuqp5616lwcb8&ne1-a^r*^rs9%!-wa\$t!m@zbrog60u=cj_7"\n\
fi\n\
if [ -z "$FRONTEND_URL" ]; then\n\
    export FRONTEND_URL="http://localhost:3000"\n\
fi\n\
if [ -z "$DATABASE_URL" ]; then\n\
    export DATABASE_URL="postgresql://neondb_owner:npg_NKBSZ0n3Tzeu@ep-silent-resonance-a8om4bn6-pooler.eastus2.azure.neon.tech/neondb?sslmode=require&channel_binding=require"\n\
fi\n\
\n\
# Run collectstatic\n\
python manage.py collectstatic --noinput --clear\n\
\n\
# Execute the CMD\n\
exec "$@"' > /entrypoint.sh && \
chmod +x /entrypoint.sh

# Expose the port the app runs on
EXPOSE 8000

# Run the application
ENTRYPOINT ["/entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--worker-class", "gthread", "--threads", "2", "ecommerce.wsgi:application"]