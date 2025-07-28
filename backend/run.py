import os
from app import create_app

app = create_app()

if __name__ == '__main__':
    port = int(os.environ.get("FLASK_PORT", 7000))  # Set to 6000 explicitly
    print(f"Running on http://0.0.0.0:{port}")  # Debug message
    app.run(debug=True, host='0.0.0.0', port=port)
