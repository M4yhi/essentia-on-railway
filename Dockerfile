FROM python:3.10-bullseye

# --- системные пакеты ---
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    libchromaprint-dev \
    python3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- TensorFlow C API ---
RUN wget -q https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz && \
    tar -C /usr/local -xzf libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz && \
    ldconfig && rm libtensorflow-cpu-linux-x86_64-2.12.0.tar.gz

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# --- Python deps ---
RUN pip install --no-cache-dir numpy six

# --- Essentia ---
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

# если Chromaprint не нужен, добавь --disable-chromaprint ниже
RUN ./waf configure --mode=release --with-python --with-tensorflow \
    && ./waf build -j$(nproc) \
    && ./waf install

# --- модели ---
RUN mkdir -p /root/.essentia/models && \
    wget -q -O /root/.essentia/models/genre_classifier_discogs-effnet-bs64-1.pb \
    https://essentia.upf.edu/models/classification/genre_classifier_discogs-effnet-bs64-1.pb

# --- твой проект ---
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
