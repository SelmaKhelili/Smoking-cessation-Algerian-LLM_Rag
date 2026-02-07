import os
from flask import Flask
from flask_cors import CORS
from app.extensions import db, migrate
from app.config.config import Config
from app.scheduler import check_goals_on_startup

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app)
    from app.achievement_seed import seed_achievements
    from app.podcast_seed import seed_podcasts
    with app.app_context():
        seed_achievements()
        seed_podcasts()
        check_goals_on_startup()
    
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
