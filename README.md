# ALX Project Nexus - E-commerce Platform

A full-featured e-commerce platform built with Django, Django REST Framework, and React.

## Features

- **User Authentication & Authorization**
  - JWT-based authentication
  - User registration and profile management
  - Role-based access control

- **Product Management**
  - Product catalog with categories
  - Product search and filtering
  - Product reviews and ratings

- **Shopping Cart & Checkout**
  - Persistent shopping cart
  - Secure checkout process
  - Order history and tracking

- **Payment Integration**
  - Multiple payment gateways
  - Secure payment processing

- **Admin Dashboard**
  - Product management
  - Order management
  - User management
  - Sales analytics

## Tech Stack

### Backend
- Python 3.12
- Django 5.2
- Django REST Framework
- PostgreSQL (Neon DB)
- Redis
- Celery

### Frontend
- React
- Redux
- Material-UI
- Axios

## Prerequisites

- Docker and Docker Compose
- Python 3.12
- Node.js 18+
- npm or yarn

## Getting Started

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd alx-project-nexus
   ```

2. **Set up environment variables**
   Copy `.env.example` to `.env` and update the values:
   ```bash
   cp .env.example .env
   ```

3. **Start the development environment**
   ```bash
   docker-compose up --build
   ```

4. **Run database migrations**
   ```bash
   docker-compose exec web python manage.py migrate
   ```

5. **Create a superuser**
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

6. **Access the application**
   - Backend API: http://localhost:8000
   - Admin panel: http://localhost:8000/admin

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```
# Django
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgresql://user:password@host:port/dbname

# Email
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
DEFAULT_FROM_EMAIL=noreply@example.com

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
```

## API Documentation

API documentation is available at `/swagger/` or `/redoc/` when the development server is running.

## Deployment

### Render.com

1. **Create a new Web Service**
   - Connect your GitHub/GitLab repository
   - Set the following environment variables:
     - `DATABASE_URL`: Your Neon DB connection string
     - `SECRET_KEY`: A secure secret key
     - `DEBUG`: False
     - `ALLOWED_HOSTS`: Your Render domain
     - Other required environment variables

2. **Build Command**
   ```
   pip install -r requirements.txt && python manage.py collectstatic --no-input
   ```

3. **Start Command**
   ```
   gunicorn ecommerce.wsgi:application --log-file -
   ```

## Project Structure

```
alx-project-nexus/
├── .github/           # GitHub workflows and templates
├── config/            # Project configuration
├── ecommerce/         # Main project settings
├── products/          # Products app
│   ├── migrations/
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── serializers.py
│   ├── tests.py
│   ├── urls.py
│   └── views.py
├── users/             # Users app
├── cart/              # Shopping cart app
├── orders/            # Orders app
├── payments/          # Payments app
├── static/            # Static files
├── templates/         # Django templates
├── .env.example       # Example environment variables
├── .gitignore
├── docker-compose.yml # Docker Compose configuration
├── Dockerfile         # Docker configuration
├── manage.py
├── README.md          # This file
└── requirements.txt   # Python dependencies
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- ALX School for the project inspiration
- All contributors who have helped improve this project
