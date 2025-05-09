# ---- базовый образ с FFmpeg 4 (libavcodec58) ----
FROM python:3.10-bullseye

# ---- системные зависимости ----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential git pkg-config wget \
    libeigen3-dev libfftw3-dev libsamplerate0-dev libtag1-dev libyaml-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev ffmpeg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Python‑зависимости ----
RUN pip install --no-cache-dir numpy

# ---- клонируем Essentia (master) ----
WORKDIR /opt
RUN git clone --recursive https://github.com/MTG/essentia.git

# ---- при желании можно обновить waf до свежего ----
RUN wget -qO /opt/essentia/waf https://waf.io/waf-2.0.22 && chmod +x /opt/essentia/waf

# ---- сборка Essentia с Python‑биндингами ----
WORKDIR /opt/essentia
RUN ./waf configure --mode=release --with-python \
    && ./waf build -j$(nproc) \
    && ./waf install

# ---- ставим Python‑биндинги ----
WORKDIR /opt/essentia/bindings/python
RUN pip install .

# ---- твой проект ----
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

EXPOSE 5000
CMD ["python", "app.py"]
