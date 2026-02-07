from app.extensions import db
from datetime import datetime

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    phone_number = db.Column(db.String(20))
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.String(10))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    is_active = db.Column(db.Boolean, default=True)
    email_verified = db.Column(db.Boolean, default=False)
    preferred_language = db.Column(db.String(10), default='ar-dz')
    
    # Relationships
    profile = db.relationship('UserProfile', backref='user', uselist=False, cascade='all, delete-orphan')
    smoking_records = db.relationship('SmokingRecord', backref='user', cascade='all, delete-orphan')
    goals = db.relationship('Goal', backref='user', cascade='all, delete-orphan')
    user_achievements = db.relationship('UserAchievement', backref='user', cascade='all, delete-orphan')
    chat_sessions = db.relationship('ChatSession', backref='user', cascade='all, delete-orphan')
    notifications = db.relationship('Notification', backref='user', cascade='all, delete-orphan')
    content_progress = db.relationship('UserContentProgress', backref='user', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'phone_number': self.phone_number,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'gender': self.gender,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'is_active': self.is_active,
            'preferred_language': self.preferred_language
        }


class UserProfile(db.Model):
    __tablename__ = 'user_profiles'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False)
    smoking_start_age = db.Column(db.Integer)
    cigarettes_per_day = db.Column(db.Integer)
    smoking_years = db.Column(db.Integer)
    quit_attempts = db.Column(db.Integer, default=0)
    motivation_level = db.Column(db.String(20))
    quit_reason = db.Column(db.Text)
    health_conditions = db.Column(db.Text)
    profile_picture_url = db.Column(db.String(255))
    total_money_saved = db.Column(db.Numeric(10, 2), default=0.00)
    total_cigarettes_avoided = db.Column(db.Integer, default=0)
    current_streak_days = db.Column(db.Integer, default=0)
    longest_streak_days = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'smoking_start_age': self.smoking_start_age,
            'cigarettes_per_day': self.cigarettes_per_day,
            'smoking_years': self.smoking_years,
            'quit_attempts': self.quit_attempts,
            'motivation_level': self.motivation_level,
            'quit_reason': self.quit_reason,
            'health_conditions': self.health_conditions,
            'profile_picture_url': self.profile_picture_url,
            'total_money_saved': float(self.total_money_saved) if self.total_money_saved else 0.0,
            'total_cigarettes_avoided': self.total_cigarettes_avoided,
            'current_streak_days': self.current_streak_days,
            'longest_streak_days': self.longest_streak_days
        }

