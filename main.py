from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import librosa
import numpy as np
import tempfile
import os

app = FastAPI()

# Разрешаем запросы от любого источника (для Flutter)
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
        # Временное сохранение файла
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_file:
            temp_file.write(await file.read())
            temp_path = temp_file.name

        # Загрузка и анализ трека
        y, sr = librosa.load(temp_path, sr=None)

        # BPM (темп)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

        # Тональность (через chroma и спектр)
        chroma = librosa.feature.chroma_stft(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1)
        key_index = np.argmax(chroma_mean)
        key_names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
        key = key_names[key_index]

        os.remove(temp_path)  # удаляем временный файл

        return {"bpm": round(tempo), "key": key}
    
    except Exception as e:
        return {"error": str(e)}
