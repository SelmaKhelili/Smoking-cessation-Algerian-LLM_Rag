# debug_run.py
from dotenv import load_dotenv
from pathlib import Path
import os, traceback

# load env + locales like run.py
load_dotenv(Path(__file__).parent / ".env", override=True)
os.environ["PGCLIENTENCODING"] = "utf-8"
os.environ["LANG"] = "en_US.UTF-8"
os.environ["LC_ALL"] = "en_US.UTF-8"

print("os.environ DATABASE_URL repr:", repr(os.environ.get("DATABASE_URL")))

from app import create_app
from app.extensions import db
from sqlalchemy import create_engine

app = create_app()
print("app.config SQLALCHEMY_DATABASE_URI repr:", repr(app.config.get("SQLALCHEMY_DATABASE_URI")))

# 1) raw psycopg2
try:
    import psycopg2
    conn = psycopg2.connect(app.config["SQLALCHEMY_DATABASE_URI"])
    conn.close()
    print("psycopg2 raw connect: OK")
except Exception:
    print("psycopg2 raw connect: FAILED")
    traceback.print_exc()

# 2) SQLAlchemy engine connect
try:
    engine = create_engine(app.config["SQLALCHEMY_DATABASE_URI"])
    with engine.connect() as conn:
        conn.execute("SELECT 1")
    print("SQLAlchemy engine connect: OK")
except Exception:
    print("SQLAlchemy engine connect: FAILED")
    traceback.print_exc()

# 3) db.create_all (inside app context)
try:
    with app.app_context():
        db.create_all()
    print("db.create_all: OK")
except Exception:
    print("db.create_all: FAILED")
    traceback.print_exc()