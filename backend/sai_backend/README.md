# SAI Backend — Setup & Migrations

Overview
- Minimal instructions to get the backend running locally and apply migrations.

## Prerequisites
- Python 3.10+ on PATH
- PostgreSQL (server & `psql`)
- Git

## Quick Setup (PowerShell)

```powershell
git clone <repo-url>
cd <repo-root>/sai_backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## Environment file

Copy the example and edit DB credentials:

```powershell
Copy-Item .env.example .env
# Edit .env and set DATABASE_URL, SECRET_KEY, etc.
```

- Use `KEY=value` format (no spaces around `=`) and ensure no BOM. Example:

```
DATABASE_URL=postgresql://postgres:password@127.0.0.1:5432/sai_app
FLASK_APP=run.py
FLASK_ENV=development
SECRET_KEY=dev-secret-key
```

## Create local DB (Postgres)

```powershell
psql -U postgres -c "CREATE DATABASE sai_app;"
```

## Apply migrations (existing schema)

```powershell
$env:FLASK_APP = 'run.py'
python -m flask db upgrade
```

- If you already have the schema and want to mark migrations as applied without running them:

```powershell
$env:FLASK_APP = 'run.py'
python -m flask db stamp head
```

## Generate new migrations (after model changes)

```powershell
$env:FLASK_APP = 'run.py'
python -m flask db migrate -m "describe change"
python -m flask db upgrade
```

- Always review `migrations/versions/*` before `upgrade`. Migrations can be destructive.

## Run the app

```powershell
python run.py
# then visit http://127.0.0.1:5000/api/health
```

## Quick DB test

```powershell
python test_db_connection.py
```

## API examples (PowerShell)

Register:

```powershell
$body = @{
	username = 'testuser'
	email = 'test@example.com'
	password = 'password123'
	smoking_start_age = 18
	cigarettes_per_day = 10
} | ConvertTo-Json
Invoke-RestMethod -Uri 'http://localhost:5000/api/auth/register' -Method Post -Headers @{ 'Content-Type' = 'application/json' } -Body $body
```

Login:

```powershell
$body = @{ email = 'test@example.com'; password = 'password123' } | ConvertTo-Json
Invoke-RestMethod -Uri 'http://localhost:5000/api/auth/login' -Method Post -Headers @{ 'Content-Type' = 'application/json' } -Body $body
```

## Troubleshooting

- Import error for `flask_sqlalchemy`: activate venv and `pip install -r requirements.txt`. In VS Code select the `.venv` interpreter.
- `DATABASE_URL` is `None`: ensure `.env` exists, keys formatted `KEY=value`, no BOM. Remove BOM with:

```powershell
python - <<'PY'
from pathlib import Path
p = Path('.env')
text = p.read_text(encoding='utf-8-sig')
p.write_text(text, encoding='utf-8')
print('BOM removed')
PY
```
- Migration upgrade fails with destructive drops: either edit the migration file in `migrations/versions/` to remove destructive `op.drop_*` calls, or run `python -m flask db stamp head` to mark migrations applied without running them.

## Notes

- Migrations include schema changes only — they do not include data. Use `pg_dump` or a seed script for data.
- Do not use `db.create_all()` in production — use migrations.

## Files of interest

- App entry: `run.py`
- Requirements: `requirements.txt`
- Example env: `.env.example`
- Migrations: `migrations/`

