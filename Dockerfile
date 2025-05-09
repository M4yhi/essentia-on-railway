FROM python:3.10-bullseye

# Системные зависимости
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка TensorFlow C API (для сборки Essentia с TensorFlow)
RUN wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz && \
    tar -C /usr/local -xzf libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz && \
    ldconfig && rm libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz

# Окружение для сборки с TensorFlow
ENV CPLUS_INCLUDE_PATH=/usr/local/include
ENV LIBRARY_PATH=/usr/local/lib
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN pip install --no-cache-dir numpy six

# Сборка Essentia
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

RUN ./waf configure --mode=release --with-python --with-tensorflow \
    && ./waf build -j$(nproc) \
    && ./waf install

# Модели Essentia
RUN mkdir -p /root/.essentia/models \
  && wget -q -O /root/.essentia/models/genre_classifier_discogs-effnet-bs64-1.pb \
     https://essentia.upf.edu/models/classification/genre_classifier_discogs-effnet-bs64-1.pb

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]

