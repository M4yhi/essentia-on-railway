FROM python:3.10-bullseye

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir numpy

WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git
WORKDIR /opt/essentia
RUN wget -qO waf https://waf.io/waf-2.0.22 && chmod +x waf

RUN ./waf configure --mode=release --with-python \
    && ./waf build -j$(nproc) \
    && ./waf install

# Устанавливаем LD_LIBRARY_PATH чтобы Python видел .so файлы
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
