FROM python:3.10-slim

# Системные зависимости
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libfftw3-dev \
    libsamplerate0-dev \
    libtag1-dev \
    libyaml-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libboost-all-dev \
    libsndfile1-dev \
    python3-dev \
    python3-pip \
    git \
    pkg-config \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Клонируем Essentia + подмодули
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git

# Сборка с помощью waf
WORKDIR /opt/essentia
RUN ./waf configure --mode=release --build-static --with-python && \
    ./waf build && \
    ./waf install

# Установка Python-биндингов
WORKDIR /opt/essentia/bindings/python
RUN pip install .

# Копируем приложение
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
