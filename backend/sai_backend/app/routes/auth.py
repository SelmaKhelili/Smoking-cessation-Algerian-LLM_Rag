from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User, UserProfile
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

bp = Blueprint('auth', __name__)

@bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('username') or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Username, email, and password are required'}), 400
        
        # Check if user already exists
        if User.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already exists'}), 400
        
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 400
        
        # Create new user
        new_user = User(
            username=data['username'],
            email=data['email'],
            password_hash=generate_password_hash(data['password']),
            phone_number=data.get('phone_number'),
            date_of_birth=datetime.strptime(data['date_of_birth'], '%Y-%m-%d').date() if data.get('date_of_birth') else None,
            gender=data.get('gender'),
            preferred_language=data.get('preferred_language', 'ar-dz')
        )
        
        db.session.add(new_user)
        db.session.flush()  # Get the user ID
        
        # Create user profile
        new_profile = UserProfile(
            user_id=new_user.id,
            smoking_start_age=data.get('smoking_start_age'),
            cigarettes_per_day=data.get('cigarettes_per_day'),
            smoking_years=data.get('smoking_years'),
            motivation_level=data.get('motivation_level'),
            quit_reason=data.get('quit_reason')
        )
        
        db.session.add(new_profile)
        db.session.commit()
        
        return jsonify({
            'message': 'User registered successfully',
            'user': new_user.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


import jwt
from datetime import datetime, timedelta

import os
SECRET_KEY = os.environ.get("JWT_SECRET")

@bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400

        user = User.query.filter_by(email=data['email']).first()

        if not user or not check_password_hash(user.password_hash, data['password']):
            return jsonify({'error': 'Invalid email or password'}), 401

        user.last_login = datetime.utcnow()
        db.session.commit()

        profile = UserProfile.query.filter_by(user_id=user.id).first()

        # Create JWT token
        token = jwt.encode({
            'user_id': user.id,
            'exp': datetime.utcnow() + timedelta(hours=24)
        }, SECRET_KEY, algorithm='HS256')

        print(f"JWT token created for user {user.id}: {token}")  # <-- Flask terminal feedback

        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': user.to_dict(),
            'profile': profile.to_dict() if profile else None
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/check-username/<username>', methods=['GET'])
def check_username(username):
    """Check if username is available"""
    user = User.query.filter_by(username=username).first()
    return jsonify({'available': user is None}), 200


@bp.route('/check-email/<email>', methods=['GET'])
def check_email(email):
    """Check if email is available"""
    user = User.query.filter_by(email=email).first()
    return jsonify({'available': user is None}), 200

