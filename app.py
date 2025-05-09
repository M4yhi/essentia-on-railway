from flask import Flask, request, jsonify
import essentia.standard as es
import os

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze():
    file = request.files['audio']
    filename = "temp.wav"
    file.save(filename)

    audio = es.MonoLoader(filename=filename)()
    bpm, *_ = es.RhythmExtractor2013(method="multifeature")(audio)

    # Жанр через TensorflowPredictEffnetDiscogs
    genre_model = es.TensorflowPredictEffnetDiscogs(
        graphFilename="/models/genre_discogs-effnet-discogs-50.pb",
        output="prediction",
        poolingType="mean"
    )
    genre_probs = genre_model(audio)
    genre_labels = genre_model.getLabels()
    genre = genre_labels[genre_probs.index(max(genre_probs))]

    # Пример "муд" — пока фейковый, так как Essentia не имеет mood-модели
    mood = "calm" if bpm < 100 else "energetic"

    os.remove(filename)
    return jsonify({
        "bpm": int(bpm),
        "genre": genre,
        "mood": mood
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
