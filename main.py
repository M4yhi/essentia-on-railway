from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import requests
import tempfile
import os

app = FastAPI()

# Разрешить Flutter-доступ
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В проде укажи домен
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Твой Last.fm API ключ
LASTFM_API_KEY = "6154c8de33ba7f96a1f28a002bc6ef3c"

# Попытка извлечь имя артиста из названия файла (формат: "Artist - Track.mp3")
def extract_artist_from_filename(filename: str) -> str:
    parts = filename.replace(".mp3", "").split("-")
    return parts[0].strip() if len(parts) > 1 else filename.replace(".mp3", "").strip()

# Получить похожих артистов с Last.fm
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

    if "error" in data:
        raise HTTPException(status_code=404, detail=data.get("message", "Artist not found"))

    artists = data.get("similarartists", {}).get("artist", [])
    return [a["name"] for a in artists]

@app.post("/upload/")
async def upload_mp3(file: UploadFile = File(...)):
    if not file.filename.endswith(".mp3"):
        raise HTTPException(status_code=400, detail="Only MP3 files are supported")

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        artist = extract_artist_from_filename(file.filename)

        if not artist:
            raise HTTPException(status_code=422, detail="Could not extract artist name")

        similar_artists = get_similar_artists(artist)

        os.remove(tmp_path)

        return {
            "original_artist": artist,
            "similar_artists": similar_artists
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")
