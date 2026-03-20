# ---- builder stage ----
FROM python:3.12-slim AS builder
WORKDIR /build

# Only needed if some wheels require compilation (safe for "prod-grade")
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# ---- runtime stage ----
FROM python:3.12-slim AS runtime
WORKDIR /app

# Create a non-root user
RUN useradd -r -u 10001 -g root appuser

# Install dependencies from prebuilt wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# Copy source code
COPY app ./app

ENV PORT=8080
EXPOSE 8080

# Container healthcheck hits the service health endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health').read()" || exit 1

USER 10001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]