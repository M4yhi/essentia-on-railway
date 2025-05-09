FROM python:3.10-bullseye

# Системные зависимости
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget curl unzip \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev \
    ffmpeg python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка TensorFlow C API
ENV TENSORFLOW_C_URL=https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.11.0.tar.gz
RUN curl -L $TENSORFLOW_C_URL | tar -C /usr/local -xz \
    && ldconfig

# Python зависимости
RUN pip install --no-cache-dir numpy six flask

# Клонируем Essentia
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia

# waf + сборка с TensorFlow
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

RUN ./waf configure --mode=release --with-python --with-tensorflow \
    && ./waf build -j$(nproc) \
    && ./waf install

# Устанавливаем LD_LIBRARY_PATH для Python
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Flask приложение
WORKDIR /app
COPY requirements.txt .  # если есть
RUN pip install --no-cache-dir -r requirements.txt || true
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
