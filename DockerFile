FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libfftw3-dev \
    libsamplerate0-dev \
    libtag1-dev \
    libyaml-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libavresample-dev \
    libboost-dev \
    libsndfile1-dev \
    git cmake \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/MTG/essentia.git && \
    cd essentia && \
    mkdir build && cd build && \
    cmake .. -DBUILD_PYTHON_BINDINGS=ON -DPYTHON_EXECUTABLE=$(which python3) && \
    make -j4 && \
    make install && \
    ldconfig && \
    cd ../bindings/python && \
    pip install .

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . /app
WORKDIR /app

EXPOSE 5000
CMD ["python", "app.py"]
