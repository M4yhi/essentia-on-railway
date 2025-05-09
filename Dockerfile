FROM python:3.10-slim

# Установка системных зависимостей
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
    git \
    cmake \
    pkg-config \
    python3-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Клонирование Essentia (поверхность, без истории)
WORKDIR /opt
RUN git clone --depth=1 https://github.com/MTG/essentia.git

# Сборка Essentia
WORKDIR /opt/essentia/build
RUN cmake .. -DBUILD_PYTHON_BINDINGS=ON -DPYTHON_EXECUTABLE=$(which python3) && \
    make -j4 && \
    make install && \
    ldconfig

# Установка Python биндингов
WORKDIR /opt/essentia/bindings/python
RUN pip install .

# Установка зависимостей Python
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
