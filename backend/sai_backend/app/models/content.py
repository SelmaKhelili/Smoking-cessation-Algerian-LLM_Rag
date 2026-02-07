from app.extensions import db
from datetime import datetime

class EducationalContent(db.Model):
    __tablename__ = 'educational_content'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    content_type = db.Column(db.String(50))
    content_text = db.Column(db.Text)
    content_url = db.Column(db.String(255))
    category = db.Column(db.String(50))
    language = db.Column(db.String(10), default='ar-dz')
    reading_time = db.Column(db.Integer)
    is_published = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user_progress = db.relationship('UserContentProgress', backref='content', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'content_type': self.content_type,
            'content_text': self.content_text,
            'content_url': self.content_url,
            'category': self.category,
            'language': self.language,
            'reading_time': self.reading_time,
            'is_published': self.is_published,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class UserContentProgress(db.Model):
    __tablename__ = 'user_content_progress'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    content_id = db.Column(db.Integer, db.ForeignKey('educational_content.id', ondelete='CASCADE'), nullable=False)
    progress_percentage = db.Column(db.Integer, default=0)
    completed = db.Column(db.Boolean, default=False)
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        db.UniqueConstraint('user_id', 'content_id', name='unique_user_content'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'content_id': self.content_id,
            'progress_percentage': self.progress_percentage,
            'completed': self.completed,
            'last_accessed': self.last_accessed.isoformat() if self.last_accessed else None
        }

