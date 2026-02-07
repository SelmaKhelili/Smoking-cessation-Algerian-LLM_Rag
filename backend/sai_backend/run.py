
import os
from dotenv import load_dotenv
# Load .env from the same directory as this file
dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path)
print("DATABASE_URL from env:", os.environ.get("DATABASE_URL"))

os.environ["PGCLIENTENCODING"] = "utf-8"
os.environ["LANG"] = "en_US.UTF-8"
os.environ["LC_ALL"] = "en_US.UTF-8"

from app import create_app
from app.extensions import db

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
