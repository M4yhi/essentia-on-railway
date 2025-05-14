from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import tempfile
import os
import numpy as np
import librosa
import subprocess

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def convert_to_wav(input_path: str, output_path: str):
    result = subprocess.run([
        "ffmpeg", "-y", "-i", input_path, "-ar", "44100", "-ac", "1", output_path
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg error: {result.stderr.decode()}")

@app.post("/analyze/")
async def analyze(file: UploadFile = File(...)):
    try:
        suffix = "." + file.filename.split(".")[-1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_file.write(await file.read())
            temp_path = temp_file.name

        # Переводим MP3 → WAV
        wav_path = temp_path + ".wav"
        convert_to_wav(temp_path, wav_path)

        # Анализ BPM и тональности
        y, sr = librosa.load(wav_path, sr=None, mono=True, duration=120)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        chroma = librosa.feature.chroma_stft(y=y, sr=sr)
        key_index = int(np.argmax(chroma.mean(axis=1)))
        key = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][key_index]

        os.remove(temp_path)
        os.remove(wav_path)

        return {"bpm": int(round(tempo)), "key": key}
    except Exception as e:
        return {"error": f"Failed to process audio: {str(e)}"}
