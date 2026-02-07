from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User, UserProfile
from app.models.tracking import SmokingRecord
from app.models.goal import Goal
from datetime import datetime, timedelta
from sqlalchemy import func

bp = Blueprint('user', __name__)

@bp.route('/profile/<int:user_id>', methods=['GET'])
def get_profile(user_id):
    """Get user profile"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        profile = UserProfile.query.filter_by(user_id=user_id).first()
        
        
        return jsonify({
            'user': user.to_dict(),
            'profile': profile.to_dict() if profile else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/profile/<int:user_id>', methods=['PUT'])
def update_profile(user_id):
    """Update user profile"""
    try:
        data = request.get_json() or {}

        # ---------- USER TABLE ----------
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Check if username is being changed and if it already exists
        if 'username' in data:
            new_username = data['username'].strip()
            
            # Check if the username is different from current
            if new_username != user.username:
                # Check if another user already has this username
                existing_user = User.query.filter(
                    User.username == new_username,
                    User.id != user_id  # Exclude current user
                ).first()
                
                if existing_user:
                    return jsonify({
                        'error': 'Username already taken',
                        'field': 'username'
                    }), 409  # 409 Conflict

            user.username = new_username

        # Email (optional, if you want to allow it)
        if 'email' in data:
            new_email = data['email'].strip()
            
            # Check if email is being changed
            if new_email != user.email:
                # Check if another user already has this email
                existing_user = User.query.filter(
                    User.email == new_email,
                    User.id != user_id  # Exclude current user
                ).first()
                
                if existing_user:
                    return jsonify({
                        'error': 'Email already registered',
                        'field': 'email'
                    }), 409

            user.email = new_email

        if 'phone_number' in data:
            user.phone_number = data['phone_number']

        if 'date_of_birth' in data:
            # Expecting YYYY-MM-DD from Flutter
            try:
                user.date_of_birth = datetime.strptime(
                    data['date_of_birth'], '%Y-%m-%d'
                ).date()
            except ValueError:
                return jsonify({
                    'error': 'Invalid date format. Use YYYY-MM-DD',
                    'field': 'date_of_birth'
                }), 400

        if 'gender' in data:
            user.gender = data['gender']

        if 'preferred_language' in data:
            user.preferred_language = data['preferred_language']

        user.updated_at = datetime.utcnow()

        # ---------- USER PROFILE TABLE ----------
        profile = UserProfile.query.filter_by(user_id=user_id).first()
        if not profile:
            profile = UserProfile(user_id=user_id)
            db.session.add(profile)

        if 'smoking_start_age' in data:
            profile.smoking_start_age = data['smoking_start_age']

        if 'cigarettes_per_day' in data:
            profile.cigarettes_per_day = data['cigarettes_per_day']

        if 'smoking_years' in data:
            profile.smoking_years = data['smoking_years']

        if 'quit_attempts' in data:
            profile.quit_attempts = data['quit_attempts']

        if 'motivation_level' in data:
            profile.motivation_level = data['motivation_level']

        if 'quit_reason' in data:
            profile.quit_reason = data['quit_reason']

        if 'health_conditions' in data:
            profile.health_conditions = data['health_conditions']

        if 'profile_picture_url' in data:
            profile.profile_picture_url = data['profile_picture_url']

        profile.updated_at = datetime.utcnow()

        # ---------- SAVE ----------
        db.session.commit()

        return jsonify({
            'message': 'Profile updated successfully',
            'user': user.to_dict(),
            'profile': profile.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_statistics(user_id):
    """Get user statistics dashboard"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        profile = UserProfile.query.filter_by(user_id=user_id).first()
        
        # Get smoking records statistics
        total_records = SmokingRecord.query.filter_by(user_id=user_id).count()
        
        # Last 7 days records
        seven_days_ago = datetime.utcnow().date() - timedelta(days=7)
        recent_records = SmokingRecord.query.filter(
            SmokingRecord.user_id == user_id,
            SmokingRecord.record_date >= seven_days_ago
        ).all()
        
        # Calculate average cigarettes per day (last 7 days)
        avg_cigarettes = 0
        if recent_records:
            total_cigarettes = sum(record.cigarettes_smoked for record in recent_records)
            avg_cigarettes = total_cigarettes / len(recent_records)
        
        # Get active goals
        active_goals = Goal.query.filter_by(user_id=user_id, status='active').count()
        completed_goals = Goal.query.filter_by(user_id=user_id, status='completed').count()
        
        # Get all-time statistics
        all_records = SmokingRecord.query.filter_by(user_id=user_id).all()
        total_cigarettes_logged = sum(record.cigarettes_smoked for record in all_records)
        
        return jsonify({
            'profile': profile.to_dict() if profile else None,
            'statistics': {
                'total_records': total_records,
                'avg_cigarettes_last_7_days': round(avg_cigarettes, 1),
                'total_cigarettes_logged': total_cigarettes_logged,
                'active_goals': active_goals,
                'completed_goals': completed_goals,
                'current_streak_days': profile.current_streak_days if profile else 0,
                'longest_streak_days': profile.longest_streak_days if profile else 0,
                'total_money_saved': float(profile.total_money_saved) if profile and profile.total_money_saved else 0.0,
                'total_cigarettes_avoided': profile.total_cigarettes_avoided if profile else 0
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/account/<int:user_id>', methods=['DELETE'])
def delete_account(user_id):
    """Delete user account (cascade deletes all related data)"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        db.session.delete(user)
        db.session.commit()
        
        return jsonify({'message': 'Account deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/avatar/<int:user_id>', methods=['POST'])
def upload_avatar(user_id):
    """Upload profile picture (placeholder - implement file upload later)"""
    try:
        data = request.get_json()
        
        profile = UserProfile.query.filter_by(user_id=user_id).first()
        if not profile:
            return jsonify({'error': 'Profile not found'}), 404
        
        profile.profile_picture_url = data.get('profile_picture_url')
        profile.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Avatar updated successfully',
            'profile_picture_url': profile.profile_picture_url
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500