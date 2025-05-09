FROM python:3.10-bullseye

# 1. Установка системных зависимостей
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget curl unzip \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Установка TensorFlow C API вручную
ENV TENSORFLOW_C_URL=https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.11.0.tar.gz
RUN curl -L $TENSORFLOW_C_URL | tar -C /usr/local -xz && ldconfig

# 3. Установка Python-зависимостей
RUN pip install --no-cache-dir numpy six flask

# 4. Клонирование Essentia
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia

# 5. Скачиваем waf и делаем исполняемым
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

# 6. Конфигурация и сборка Essentia с TensorFlow
RUN ./waf configure --mode=release --with-python --with-tensorflow && \
    ./waf build -j$(nproc) && \
    ./waf install

# 7. Установка переменной окружения, чтобы Python видел libessentia.so
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# 8. Flask-приложение
WORKDIR /app
COPY requirements.txt . || true
RUN pip install --no-cache-dir -r requirements.txt || true
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
