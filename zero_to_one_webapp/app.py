from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend interaction

@app.route('/add', methods=['POST'])
def add_numbers():
    data = request.json  # Get JSON data from frontend
    num1 = float(data.get('num1', 0))
    num2 = float(data.get('num2', 0))
    return jsonify({'sum': num1 + num2})  # Return sum as JSON

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


