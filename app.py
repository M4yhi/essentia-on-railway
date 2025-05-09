from flask import Flask, request, jsonify
import essentia
import essentia.standard as es
import os

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    file = request.files['audio']
    temp_filename = 'temp_audio_file.mp3'
    file.save(temp_filename)

    try:
        loader = es.MonoLoader(filename=temp_filename)
        audio = loader()

        rhythm_extractor = es.RhythmExtractor2013(method="multifeature")
        bpm, _, _, _, _ = rhythm_extractor(audio)

        return jsonify({'bpm': bpm})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        os.remove(temp_filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
