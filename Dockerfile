FROM python:3.10-slim

# Системные пакеты
RUN apt-get update && apt-get install -y \
        build-essential ffmpeg libsndfile1 wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Python‑зависимости
RUN pip install --no-cache-dir numpy scipy soundfile \
    librosa==0.10.1 musicnn==0.2 tensorflow-cpu==2.13 flask

# Flask‑API
WORKDIR /app
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
