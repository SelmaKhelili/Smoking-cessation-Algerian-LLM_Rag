
Write-Host "Creating SAI Backend Structure..." -ForegroundColor Green

# Create all directories
$directories = @(
    "sai_backend/app/models",
    "sai_backend/app/routes",
    "sai_backend/app/services",
    "sai_backend/app/utils",
    "sai_backend/app/config",
    "sai_backend/migrations/versions",
    "sai_backend/tests"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "Created: $dir" -ForegroundColor Cyan
}

Set-Location sai_backend

# Create all __init__.py files
$initFiles = @(
    "app/__init__.py",
    "app/models/__init__.py",
    "app/routes/__init__.py",
    "app/services/__init__.py",
    "app/utils/__init__.py",
    "app/config/__init__.py",
    "tests/__init__.py"
)

foreach ($file in $initFiles) {
    New-Item -ItemType File -Force -Path $file | Out-Null
}

# Create all Python files
$files = @(
    "app/models/user.py",
    "app/models/tracking.py",
    "app/models/goal.py",
    "app/models/achievement.py",
    "app/models/chat.py",
    "app/models/content.py",
    "app/models/notification.py",
    "app/routes/auth.py",
    "app/routes/user.py",
    "app/routes/tracking.py",
    "app/routes/goals.py",
    "app/routes/achievements.py",
    "app/routes/chat.py",
    "app/routes/content.py",
    "app/routes/notifications.py",
    "app/services/auth_service.py",
    "app/services/user_service.py",
    "app/services/tracking_service.py",
    "app/services/goal_service.py",
    "app/services/achievement_service.py",
    "app/services/llm_service.py",
    "app/services/notification_service.py",
    "app/services/analytics_service.py",
    "app/services/content_service.py",
    "app/utils/validators.py",
    "app/utils/helpers.py",
    "app/utils/decorators.py",
    "app/utils/constants.py",
    "app/config/config.py",
    "app/extensions.py",
    "run.py",
    "requirements.txt",
    ".env",
    ".env.example",
    ".gitignore",
    "README.md"
)

foreach ($file in $files) {
    New-Item -ItemType File -Force -Path $file | Out-Null
}

# Create requirements.txt
@"
Flask==3.0.0
Flask-SQLAlchemy==3.1.1
Flask-Migrate==4.0.5
Flask-CORS==4.0.0
psycopg2-binary==2.9.9
python-dotenv==1.0.0
Werkzeug==3.0.1
"@ | Set-Content "requirements.txt"

# Create .env.example
@"
DATABASE_URL=postgresql://postgres:password@localhost:5432/sai_app
FLASK_APP=run.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here
"@ | Set-Content ".env.example"

# Create .gitignore
@"
__pycache__/
*.py[cod]
venv/
.env
*.db
*.sqlite3
uploads/
*.log
.DS_Store
"@ | Set-Content ".gitignore"

# Create run.py
@"
from app import create_app
from app.extensions import db

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000)
"@ | Set-Content "run.py"

# Create app/__init__.py
@"
from flask import Flask
from flask_cors import CORS
from app.extensions import db, migrate
from app.config.config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app)
    
    from app.routes import auth, user, tracking, goals, achievements, chat, content, notifications
    
    app.register_blueprint(auth.bp, url_prefix='/api/auth')
    app.register_blueprint(user.bp, url_prefix='/api/user')
    app.register_blueprint(tracking.bp, url_prefix='/api/tracking')
    app.register_blueprint(goals.bp, url_prefix='/api/goals')
    app.register_blueprint(achievements.bp, url_prefix='/api/achievements')
    app.register_blueprint(chat.bp, url_prefix='/api/chat')
    app.register_blueprint(content.bp, url_prefix='/api/content')
    app.register_blueprint(notifications.bp, url_prefix='/api/notifications')
    
    @app.route('/api/health')
    def health():
        return {'status': 'healthy', 'message': 'SAI API is running'}, 200
    
    return app
"@ | Set-Content "app/__init__.py"

# Create app/extensions.py
@"
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()
"@ | Set-Content "app/extensions.py"

# Create app/config/config.py
@"
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'postgresql://postgres:password@localhost:5432/sai_app'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = True
    JSON_SORT_KEYS = False
    ITEMS_PER_PAGE = 20
"@ | Set-Content "app/config/config.py"

# Create app/utils/constants.py
@"
GOAL_TYPE_REDUCE_DAILY = 'reduce_daily'
GOAL_TYPE_SMOKE_FREE_DAYS = 'smoke_free_days'
GOAL_TYPE_MONEY_SAVED = 'money_saved'
GOAL_TYPE_HEALTH_MILESTONE = 'health_milestone'

GOAL_STATUS_ACTIVE = 'active'
GOAL_STATUS_COMPLETED = 'completed'
GOAL_STATUS_FAILED = 'failed'

SENDER_USER = 'user'
SENDER_ASSISTANT = 'assistant'

MOOD_HAPPY = 'happy'
MOOD_NEUTRAL = 'neutral'
MOOD_STRESSED = 'stressed'
MOOD_ANXIOUS = 'anxious'
MOOD_SAD = 'sad'
"@ | Set-Content "app/utils/constants.py"

Write-Host "`nStructure created successfully!" -ForegroundColor Green
Write-Host "Location: sai_backend/" -ForegroundColor Yellow
