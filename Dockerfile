FROM python:3.10-bullseye

# Установка системных зависимостей
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget curl unzip \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev \
    python3-dev ffmpeg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка Python-зависимостей
RUN pip install --no-cache-dir numpy six tensorflow==2.10.0 flask

# Клонирование Essentia с подмодулями
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git

# Сборка Essentia с TensorFlow
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf
# Установка TensorFlow C API
RUN curl -L https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.10.0.tar.gz | tar -C /usr/local -xz
RUN ldconfig

# Конфигурация и сборка Essentia
RUN ./waf configure --mode=release --with-python --with-tensorflow && \
    ./waf build -j$(nproc) && \
    ./waf install


# Добавляем TensorFlow модель жанров
RUN mkdir -p /models && \
    curl -L -o /models/genre_discogs-effnet-discogs-50.pb \
    https://essentia.upf.edu/models/genre/genre_discogs-effnet-discogs-50.pb

# Установка переменной окружения, чтобы Python находил .so библиотеки
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Копируем и запускаем Flask-приложение
WORKDIR /app
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
