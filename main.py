from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import essentia.standard as ess
import tempfile
import os
import json

app = FastAPI()

# Разрешить CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/analyze/")
async def analyze_audio(file: UploadFile = File(...)):
    try:
        # Сохраняем во временный файл
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        # Конвертация в mono (если stereo)
        mono_loader = ess.MonoLoader(filename=tmp_path)
        audio = mono_loader()

        # BPM
        bpm_extractor = ess.RhythmExtractor2013(method="multifeature")
        bpm, _, _, _, _ = bpm_extractor(audio)

        # Мел спектрограмма
        extractor = ess.MusicExtractor(lowlevelSilentFrames='drop')

        features, _ = extractor(tmp_path)

        # Примеры: danceability, acousticness, mood
        danceability = features["rhythm.danceability"]
        acousticness = features["lowlevel.average_loudness"]  # Условно
        mood = features["mood.acoustic"]

        # Очистка
        os.remove(tmp_path)

        return {
            "bpm": round(bpm),
            "danceability": round(danceability, 3),
            "mood_acoustic": round(mood, 3),
            "loudness": round(acousticness, 3)
        }

    except Exception as e:
        return {"error": str(e)}
