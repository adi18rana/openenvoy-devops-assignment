# Build stage: install dependencies and prepare environment
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip wheel --wheel-dir /wheels -r requirements.txt

# Copy app files
COPY app.py .

# Runtime stage: minimal image with installed packages
FROM python:3.11-slim

WORKDIR /app

# Copy wheels and install dependencies from build stage cache
COPY --from=builder /wheels /wheels
COPY app.py .

RUN pip install --no-index --find-links=/wheels -r requirements.txt

EXPOSE 8000

# Run app with Gunicorn binding to 0.0.0.0 for external access
CMD ["gunicorn", "--workers", "3", "--bind", "0.0.0.0:8000", "app:app"]
