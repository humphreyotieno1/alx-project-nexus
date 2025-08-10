# Use official Python image
FROM python:3.11-slim

# Prevents Python from writing .pyc files & enables unbuffered logging
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Create app directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy the rest of the application
COPY . .

# Ensure static files are collected in production
RUN python manage.py collectstatic --noinput

# Environment variables (must be set in Render dashboard)
# SECRET_KEY, DATABASE_URL, ALLOWED_HOSTS, DEBUG=False

# Expose port (Render sets $PORT automatically)
EXPOSE 8000

# Start Gunicorn server
CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000"]
