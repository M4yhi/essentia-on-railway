from flask import Flask, request, jsonify
import essentia.standard as es
import os

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze():
    file = request.files['audio']
    filename = 'temp.wav'
    file.save(filename)

    audio = es.MonoLoader(filename=filename)()

    # BPM
    bpm, _, _, _, _ = es.RhythmExtractor2013(method="multifeature")(audio)

    # Жанр и настроение — модель GMD
    genreModel = es.TensorflowPredictEffnetDiscogs()
    moodModel = es.TensorflowPredictVGGish()
    genreVector = genreModel(audio)
    moodVector = moodModel(audio)

    genre = genreModel.getLabels()[genreVector.index(max(genreVector))]
    mood = moodModel.getLabels()[moodVector.index(max(moodVector))]

    os.remove(filename)
    return jsonify({
        'bpm': round(bpm),
        'genre': genre,
        'mood': mood
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
