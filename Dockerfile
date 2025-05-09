FROM python:3.10-slim

# Установка зависимостей
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
    python3-numpy \
    python3-yaml \
    python3-six \
    git \
    pkg-config \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Клонирование Essentia с подмодулями
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git

# Сборка и установка Essentia
WORKDIR /opt/essentia
RUN chmod +x waf && \
    python3 waf configure --mode=release --build-static --with-python && \
    python3 waf build && \
    python3 waf install

# Установка Python-биндингов
WORKDIR /opt/essentia/bindings/python
RUN pip install .

# Копирование и установка зависимостей Python-приложения
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
