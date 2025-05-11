from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import requests
import tempfile
import os

app = FastAPI()

# CORS для Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # в проде лучше указать домен
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

LASTFM_API_KEY = "YOUR_LASTFM_API_KEY"

def extract_artist_from_filename(filename: str) -> str:
    # Простой хак: пробуем взять имя артиста из названия файла
    return filename.rsplit("-", 1)[0].strip()

def get_similar_artists(artist_name: str):
    url = "http://ws.audioscrobbler.com/2.0/"
    params = {
        "method": "artist.getsimilar",
        "artist": artist_name,
        "api_key": LASTFM_API_KEY,
        "format": "json",
        "limit": 10
    }
    response = requests.get(url, params=params)
    data = response.json()

    if "similarartists" in data:
        return [artist["name"] for artist in data["similarartists"]["artist"]]
    else:
        return []

@app.post("/upload/")
async def upload_mp3(file: UploadFile = File(...)):
    if not file.filename.endswith(".mp3"):
        raise HTTPException(status_code=400, detail="Only MP3 files are supported")

    try:
        # Временно сохраняем файл
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        # Пытаемся извлечь имя артиста
        artist = extract_artist_from_filename(file.filename)
        if not artist:
            raise HTTPException(status_code=422, detail="Could not detect artist name")

        similar_artists = get_similar_artists(artist)
        os.remove(tmp_path)
        return {"original_artist": artist, "similar_artists": similar_artists}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
