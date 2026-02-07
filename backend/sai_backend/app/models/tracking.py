from app.extensions import db
from datetime import datetime

class SmokingRecord(db.Model):
    __tablename__ = 'smoking_records'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    record_date = db.Column(db.Date, nullable=False)
    cigarettes_smoked = db.Column(db.Integer, nullable=False)
    cravings_count = db.Column(db.Integer, default=0)
    mood = db.Column(db.String(20))
    triggers = db.Column(db.Text)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'record_date': self.record_date.isoformat() if self.record_date else None,
            'cigarettes_smoked': self.cigarettes_smoked,
            'cravings_count': self.cravings_count,
            'mood': self.mood,
            'triggers': self.triggers,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

