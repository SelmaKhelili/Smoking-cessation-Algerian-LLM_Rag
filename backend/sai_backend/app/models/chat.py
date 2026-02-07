from app.extensions import db
from datetime import datetime

class ChatSession(db.Model):
    __tablename__ = 'chat_sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    session_title = db.Column(db.String(200))
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_message_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    message_count = db.Column(db.Integer, default=0)
    
    # Relationships
    messages = db.relationship('ChatMessage', backref='session', cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'session_title': self.session_title,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'last_message_at': self.last_message_at.isoformat() if self.last_message_at else None,
            'is_active': self.is_active,
            'message_count': self.message_count
        }


class ChatMessage(db.Model):
    __tablename__ = 'chat_messages'
    
    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.Integer, db.ForeignKey('chat_sessions.id', ondelete='CASCADE'), nullable=False)
    sender_type = db.Column(db.String(10), nullable=False)  # 'user' or 'assistant'
    message_text = db.Column(db.Text, nullable=False)
    message_metadata = db.Column(db.JSON)
    sentiment_score = db.Column(db.Numeric(3, 2))
    flagged = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'session_id': self.session_id,
            'sender_type': self.sender_type,
            'message_text': self.message_text,
            'message_metadata': self.message_metadata,
            'sentiment_score': float(self.sentiment_score) if self.sentiment_score else None,
            'flagged': self.flagged,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

