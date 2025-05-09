from flask import Flask, request, jsonify
import essentia.standard as es
import os

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        # Получаем аудиофайл из запроса
        file = request.files['audio']
        filename = "temp.wav"
        file.save(filename)

        # Загружаем аудио и извлекаем BPM
        audio = es.MonoLoader(filename=filename)()
        bpm, _, _, _, _ = es.RhythmExtractor2013(method="multifeature")(audio)

        # Удаляем временный файл
        os.remove(filename)

        # Возвращаем результат
        return jsonify({
            "bpm": round(bpm),
            "genre": "unknown",
            "mood": "unknown"
        })

    except Exception as e:
        print(f"🔥 Ошибка анализа: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
