# Build stage
FROM python:3.12-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=100

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# Copy the rest of the application
COPY . .

# Runtime stage
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
RUN useradd -m appuser && mkdir -p /app && chown -R appuser:appuser /app
USER appuser

# Set work directory and environment variables
WORKDIR /app
ENV PATH="/home/appuser/.local/bin:$PATH"
ENV PYTHONPATH="/app"

# Copy installed packages from builder
COPY --from=builder --chown=appuser:appuser /install /usr/local

# Copy application code
COPY --chown=appuser:appuser . .

ENV SECRET_KEY=ucuqp5616lwcb8&ne1-a^r*^rs9%!-wa$t!m@zbrog60u=cj_7

# Collect static files
RUN python manage.py collectstatic --noinput

# Use gunicorn as the production server
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "--workers", "4", "--threads", "4", "ecommerce.wsgi"]
