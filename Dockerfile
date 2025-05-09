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
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Работаем в нормальной директории
WORKDIR /opt

# Клонируем и собираем Essentia
RUN git clone https://github.com/MTG/essentia.git && \
    cd essentia && \
    mkdir build && cd build && \
    cmake .. -DBUILD_PYTHON_BINDINGS=ON -DPYTHON_EXECUTABLE=$(which python3) && \
    make -j4 && \
    make install && \
    ldconfig && \
    cd ../bindings/python && \
    pip install .

# Установка зависимостей Python
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app
EXPOSE 5000
CMD ["python", "app.py"]
