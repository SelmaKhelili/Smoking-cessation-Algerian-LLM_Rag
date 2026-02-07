import os, traceback
from pathlib import Path
from dotenv import load_dotenv
load_dotenv(Path('.') / '.env', override=True)
dsn = os.environ.get('DATABASE_URL')
print('Attempting psycopg2.connect with DSN repr:', repr(dsn))

home = Path.home()
candidates = [home/'.pgpass', Path(os.environ.get('PGPASSFILE','')), Path(os.environ.get('PGSERVICEFILE',''))]

for p in candidates:
    if not p or str(p) == '.':
        continue
    if p.exists() and p.is_file():
        try:
            b = p.read_bytes()
            print('Found', p, 'bytes repr sample:', repr(b[:200]))
        except Exception as e:
            print('Could not read', p, '->', e)

try:
    import psycopg2
    conn = psycopg2.connect(dsn)
    conn.close()
    print('Connected successfully')
except Exception:
    traceback.print_exc()