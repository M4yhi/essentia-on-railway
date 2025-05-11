FROM python:3.10-slim

# Установим базовые зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg \
    build-essential \
    libavformat-dev \
    libavcodec-dev \
    libavutil-dev \
    libtag1-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Установим essentia и другие библиотеки
RUN pip install essentia==2.1b6 fastapi uvicorn python-multipart

# Создаем рабочую директорию
WORKDIR /app

# Копируем все файлы
COPY . .

# Запуск
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
