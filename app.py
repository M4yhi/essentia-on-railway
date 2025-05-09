from flask import Flask, request, jsonify
import librosa, numpy as np, os, musicnn.tagger as mtag

app = Flask(__name__)

# ────────────────────────────────────────────────────────────────
def calc_bpm(y, sr):
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr, units='time')
    return round(tempo)

def musicnn_tags(y, sr):
    tags, probs = mtag.musicnn(y, sr)
    top = sorted(zip(tags, probs), key=lambda x: x[1], reverse=True)[:5]
    return {tag: float(p) for tag, p in top}

def mood_from_tags(tag_dict):
    mood_map = {
        'happy': 'happy', 'sad': 'sad', 'chill': 'calm',
        'aggressive': 'energetic', 'romantic': 'romantic'
    }
    for t in tag_dict:
        if t in mood_map:
            return mood_map[t]
    return 'unknown'
# ────────────────────────────────────────────────────────────────

@app.route('/analyze', methods=['POST'])
def analyze():
    f = request.files['audio']
    file_path = 'tmp_'+f.filename
    f.save(file_path)

    y, sr = librosa.load(file_path, sr=22050, mono=True, duration=60)
    bpm = calc_bpm(y, sr)
    tags = musicnn_tags(y, sr)

    # genre = самый вероятный жанровый тег из musicnn
    genre = max(tags, key=tags.get)
    mood  = mood_from_tags(tags)

    os.remove(file_path)
    return jsonify({'bpm': bpm, 'genre': genre, 'mood': mood, 'tags': tags})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
