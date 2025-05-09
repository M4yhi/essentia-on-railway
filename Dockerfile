FROM python:3.10-bullseye

# Установка системных библиотек (включая ffmpeg 4)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка numpy (нужно для Essentia)
RUN pip install --no-cache-dir numpy

# Клонирование Essentia и обновление waf
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

# Сборка и установка Essentia с поддержкой Python
RUN ./waf configure --mode=release --with-python \
    && ./waf build -j$(nproc) \
    && ./waf install

# Установка зависимостей вашего Flask-приложения
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копирование всего приложения
COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
