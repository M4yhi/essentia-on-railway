FROM python:3.10-slim

# Установка системных зависимостей
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libeigen3-dev \
    libfftw3-dev \
    libsamplerate0-dev \
    libtag1-dev \
    libyaml-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    libchromaprint-dev \
    python3-dev \
    git \
    pkg-config \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка numpy (требуется для сборки Essentia)
RUN pip install numpy

# Клонирование Essentia с подмодулями
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git

# Сборка Essentia
WORKDIR /opt/essentia
RUN chmod +x waf && \
    python3 waf configure --mode=release --with-python --pythondir=/usr/local/lib/python3.10/dist-packages && \
    python3 waf build && \
    python3 waf install

# Установка Python-биндингов
WORKDIR /opt/essentia/bindings/python
RUN pip install .

# Установка зависимостей вашего проекта
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
