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

    os.remove(filename)
    return jsonify({"bpm": bpm})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
