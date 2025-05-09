FROM python:3.10-bullseye

# ---- system deps -----------------------------------------------------
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget curl \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    libchromaprint-dev python3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- TensorFlow C API ------------------------------------------------
ENV TF_VER=2.10.0
RUN curl -L https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-${TF_VER}.tar.gz \
    | tar -C /usr/local -xz && ldconfig

# ---- python deps -----------------------------------------------------
RUN pip install --no-cache-dir numpy six flask

# ---- Essentia --------------------------------------------------------
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

# → если Chromaprint не нужен – добавь   --disable-chromaprint
RUN ./waf configure --mode=release --with-python --with-tensorflow \
    && ./waf build -j"$(nproc)" \
    && ./waf install

# ---- модель жанров ---------------------------------------------------
RUN mkdir -p /models && \
    wget -qO /models/genre_discogs-effnet-discogs-50.pb \
      https://essentia.upf.edu/models/genre/genre_discogs-effnet-discogs-50.pb

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# ---- Flask API -------------------------------------------------------
WORKDIR /app
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
