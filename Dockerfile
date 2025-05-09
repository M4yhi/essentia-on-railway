FROM python:3.10-bullseye

### 1. системные пакеты ###############################################
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget curl \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    libchromaprint-dev python3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

### 2. TensorFlow C API (v2.10 — последняя, что собирается с Essentia) ###
ENV TF_VERSION=2.10.0
RUN curl -L https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-${TF_VERSION}.tar.gz \
    | tar -C /usr/local -xz && ldconfig

# путь к инклудам/библиотекам для waf
ENV TF_INC=/usr/local/include
ENV TF_LIB=/usr/local/lib
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

### 3. python‑deps #####################################################
RUN pip install --no-cache-dir numpy six flask

### 4. Essentia ########################################################
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

# --disable-chromaprint → если chromaprint не нужен
RUN ./waf configure --mode=release --with-python --with-tensorflow \
       --extra-cxxflags="-I${TF_INC}" --extra-ldflags="-L${TF_LIB}" && \
    ./waf build -j$(nproc) && \
    ./waf install

### 5. модель жанров ###################################################
RUN mkdir -p /models && \
    wget -qO /models/genre_discogs-effnet-discogs-50.pb \
        https://essentia.upf.edu/models/genre/genre_discogs-effnet-discogs-50.pb

### 6. Flask‑API #######################################################
WORKDIR /app
COPY app.py .

EXPOSE 5000
CMD ["python", "app.py"]
