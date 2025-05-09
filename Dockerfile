FROM python:3.9-slim

# ── system deps ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    build-essential ffmpeg libsndfile1 wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── python deps ───────────────────────────────────────────────
RUN pip install --no-cache-dir \
      numpy \
      scipy \
      soundfile \
      librosa==0.10.1 \
      musicnn==0.1.0 \
      tensorflow-cpu==2.13.0 \
      flask

# ── Flask API ─────────────────────────────────────────────────
WORKDIR /app
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
