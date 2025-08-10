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
RUN pip install --upgrade pip \
    && pip install --prefix=/install -r requirements.txt

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

# Copy installed packages from builder
COPY --from=builder --chown=appuser:appuser /install /usr/local

# Copy application code
COPY --chown=appuser:appuser . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Command for Django + Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "--workers", "4", "--threads", "4", "ecommerce.wsgi"]
