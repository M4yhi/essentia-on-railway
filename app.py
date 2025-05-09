from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return 'Webhook server is running.'

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.json
    print('🎧 Получены данные от Cyanite:')
    print(data)  # Здесь можно сохранить в базу, если нужно
    return jsonify({'status': 'received'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
