# Use Python 3.11 slim as the base image
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Final stage
FROM python:3.11-slim

# Set environment variables for build and runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.local/bin:$PATH" \
    SECRET_KEY=dummy-key-for-build \
    ALLOWED_HOSTS="*" \
    FRONTEND_URL="http://localhost:3000"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and set work directory
WORKDIR /app

# Create staticfiles directory
RUN mkdir -p /app/staticfiles
RUN chmod -R 755 /app/staticfiles

# Copy Python wheels from builder
COPY --from=builder /app/wheels /wheels

# Install application dependencies
RUN pip install --no-cache /wheels/*

# Copy project
COPY . .

# Create a script to handle collectstatic with fallback
RUN echo $'#!/bin/sh\n\
if [ -z "$SECRET_KEY" ]; then\n\
    export SECRET_KEY="dummy-key-for-build"\n\
fi\n\
if [ -z "$FRONTEND_URL" ]; then\n\
    export FRONTEND_URL="http://localhost:3000"\n\
fi\n\
python manage.py collectstatic --noinput' > /collectstatic.sh && \
    chmod +x /collectstatic.sh

# Debug: Print the script to verify its content
RUN cat /collectstatic.sh

# Use the script for collectstatic
RUN /collectstatic.sh

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "ecommerce.wsgi:application"]