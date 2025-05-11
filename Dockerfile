FROM python:3.10-slim

# Установим зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    ffmpeg \
    libessentia0v2 \
    libessentia0-dev \
    python3-pip \
    libavformat-dev \
    libavcodec-dev \
    libavutil-dev \
    libtag1-dev \
    && rm -rf /var/lib/apt/lists/*

# Установка Essentia (если используешь pip версию)
RUN pip install essentia==2.1b6 fastapi uvicorn python-multipart

WORKDIR /app
COPY . .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
