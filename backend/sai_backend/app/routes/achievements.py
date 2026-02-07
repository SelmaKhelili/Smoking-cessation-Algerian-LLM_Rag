from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.achievement import Achievement, UserAchievement
from app.models.user import User, UserProfile
from app.models.tracking import SmokingRecord
from app.models.goal import Goal
from app.models.content import UserContentProgress
from datetime import datetime, timedelta
from sqlalchemy import func
from app.models.notification import Notification

bp = Blueprint('achievements', __name__)

def create_notification(user_id, notification_type, title, message):
    """Create a notification for a user"""
    # Validate user exists first
    user_exists = db.session.query(User.id).filter_by(id=user_id).first()
    if not user_exists:
        raise ValueError(f"User with id {user_id} does not exist")
    
    notification = Notification(
        user_id=user_id,
        notification_type=notification_type,
        title=title,
        message=message
    )
    db.session.add(notification)
    # Remove flush here - let the caller handle it
    return notification

@bp.route('/', methods=['GET'])
def get_all_achievements():
    """Get all available achievements in the system"""
    try:
        # Get filter parameters
        badge_type = request.args.get('badge_type')  # optional filter
        
        query = Achievement.query
        
        if badge_type:
            query = query.filter_by(badge_type=badge_type)
        
        achievements = query.order_by(Achievement.points.desc()).all()
        
        return jsonify({
            'achievements': [achievement.to_dict() for achievement in achievements],
            'total': len(achievements)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:achievement_id>', methods=['GET'])
def get_achievement(achievement_id):
    """Get a specific achievement"""
    try:
        achievement = Achievement.query.get(achievement_id)
        if not achievement:
            return jsonify({'error': 'Achievement not found'}), 404
        
        return jsonify({'achievement': achievement.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/earned', methods=['GET'])
def get_earned_achievements():
    """Get all achievements earned by a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get earned achievements with achievement details
        earned = db.session.query(UserAchievement, Achievement).join(
            Achievement, UserAchievement.achievement_id == Achievement.id
        ).filter(UserAchievement.user_id == user_id).order_by(
            UserAchievement.earned_at.desc()
        ).all()
        
        earned_list = []
        for user_achievement, achievement in earned:
            achievement_dict = achievement.to_dict()
            achievement_dict['earned_at'] = user_achievement.earned_at.isoformat()
            earned_list.append(achievement_dict)
        
        # Calculate total points
        total_points = sum(a.points for _, a in earned)
        
        return jsonify({
            'earned_achievements': earned_list,
            'total_earned': len(earned_list),
            'total_points': total_points
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/available', methods=['GET'])
def get_available_achievements():
    """Get achievements user hasn't earned yet"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get IDs of earned achievements
        earned_ids = db.session.query(UserAchievement.achievement_id).filter_by(
            user_id=user_id
        ).all()
        earned_ids = [id[0] for id in earned_ids]
        
        # Get achievements not yet earned
        available = Achievement.query.filter(
            ~Achievement.id.in_(earned_ids)
        ).order_by(Achievement.points).all()
        
        return jsonify({
            'available_achievements': [achievement.to_dict() for achievement in available],
            'total_available': len(available)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500





@bp.route('/check', methods=['POST'])
def check_achievements():
    data = request.get_json()
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    profile = UserProfile.query.filter_by(user_id=user_id).first()
    all_achievements = Achievement.query.all()
    earned_ids = [id[0] for id in db.session.query(UserAchievement.achievement_id).filter_by(user_id=user_id).all()]
    newly_earned = []

    try:
        for achievement in all_achievements:
            if achievement.id in earned_ids:
                continue

            earned = False

            if achievement.criteria_type == 'days_smoke_free' and profile:
                earned = profile.longest_streak_days >= achievement.criteria_value
            elif achievement.criteria_type == 'money_saved' and profile:
                earned = profile.total_money_saved >= achievement.criteria_value
            elif achievement.criteria_type == 'goals_completed':
                completed_goals = Goal.query.filter_by(user_id=user_id, status='completed').count()
                earned = completed_goals >= achievement.criteria_value
            elif achievement.criteria_type == 'content_completed':
                completed_content = UserContentProgress.query.filter_by(user_id=user_id, completed=True).count()
                earned = completed_content >= achievement.criteria_value
            elif achievement.criteria_type == 'total_records':
                total_records = SmokingRecord.query.filter_by(user_id=user_id).count()
                earned = total_records >= achievement.criteria_value

            if earned:
                # Add achievement
                user_achievement = UserAchievement(user_id=user_id, achievement_id=achievement.id)
                db.session.add(user_achievement)

                # SIMPLE NOTIFICATION CREATION - NO COMPLEX LOGIC
                notification = Notification(
                    user_id=user_id,
                    notification_type='achievement_earned',
                    title='New Achievement!',
                    message=f"Congratulations! You earned: {achievement.name}",
                    is_read=False,
                    created_at=datetime.utcnow()
                )
                db.session.add(notification)

                newly_earned.append(achievement.to_dict())

        db.session.commit()
        
    except Exception as e:
        db.session.rollback()
        # Print exact error for debugging
        print(f"ERROR DETAILS: {str(e)}")
        return jsonify({'error': f"Failed to save: {str(e)}"}), 500

    return jsonify({'newly_earned': newly_earned, 'count': len(newly_earned)}), 200

@bp.route('/progress', methods=['GET'])
def get_achievement_progress():
    """Get progress toward unlocking achievements"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        profile = UserProfile.query.filter_by(user_id=user_id).first()
        
        # Get unearnedachievements
        earned_ids = db.session.query(UserAchievement.achievement_id).filter_by(
            user_id=user_id
        ).all()
        earned_ids = [id[0] for id in earned_ids]
        
        available = Achievement.query.filter(
            ~Achievement.id.in_(earned_ids)
        ).all()
        
        progress_list = []
        
        for achievement in available:
            current_value = 0
            
            if achievement.criteria_type == 'smoke_free_days' and profile:
                current_value = profile.longest_streak_days or 0

            
            elif achievement.criteria_type == 'money_saved' and profile:
                current_value = float(profile.total_money_saved)
            
            elif achievement.criteria_type == 'goals_completed':
                current_value = Goal.query.filter_by(
                    user_id=user_id,
                    status='completed'
                ).count()
            
            elif achievement.criteria_type == 'content_completed':
                current_value = UserContentProgress.query.filter_by(
                    user_id=user_id,
                    completed=True
                ).count()
            
            elif achievement.criteria_type == 'total_records':
                current_value = SmokingRecord.query.filter_by(user_id=user_id).count()
            
            # Calculate percentage
            percentage = 0
            if achievement.criteria_value > 0:
                percentage = min(100, round((current_value / achievement.criteria_value) * 100, 1))
            
            achievement_dict = achievement.to_dict()
            achievement_dict['current_value'] = current_value
            achievement_dict['progress_percentage'] = percentage
            
            progress_list.append(achievement_dict)
        
        # Sort by progress (closest to completion first)
        progress_list.sort(key=lambda x: x['progress_percentage'], reverse=True)
        
        return jsonify({
            'achievement_progress': progress_list,
            'total': len(progress_list)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_achievement_statistics(user_id):
    """Get achievement statistics for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Total achievements in system
        total_achievements = Achievement.query.count()
        
        # Earned achievements
        earned_count = UserAchievement.query.filter_by(user_id=user_id).count()
        
        # Total points earned
        earned_achievements = db.session.query(UserAchievement, Achievement).join(
            Achievement, UserAchievement.achievement_id == Achievement.id
        ).filter(UserAchievement.user_id == user_id).all()
        
        total_points = sum(a.points for _, a in earned_achievements)
        
        # Completion rate
        completion_rate = 0
        if total_achievements > 0:
            completion_rate = round((earned_count / total_achievements) * 100, 1)
        
        # Earned by badge type
        earned_by_type = {}
        for _, achievement in earned_achievements:
            badge_type = achievement.badge_type or 'other'
            earned_by_type[badge_type] = earned_by_type.get(badge_type, 0) + 1
        
        # Recent achievements (last 7 days)
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_earned = UserAchievement.query.filter(
            UserAchievement.user_id == user_id,
            UserAchievement.earned_at >= seven_days_ago
        ).count()
        
        return jsonify({
            'statistics': {
                'total_achievements': total_achievements,
                'earned_count': earned_count,
                'available_count': total_achievements - earned_count,
                'total_points': total_points,
                'completion_rate': completion_rate,
                'earned_by_type': earned_by_type,
                'recent_earned': recent_earned
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/leaderboard', methods=['GET'])
def get_leaderboard():
    """Get achievement leaderboard (top users by points)"""
    try:
        # Get limit parameter
        limit = request.args.get('limit', 10, type=int)
        
        # Query to get top users by total achievement points
        leaderboard = db.session.query(
            User.id,
            User.username,
            func.sum(Achievement.points).label('total_points'),
            func.count(UserAchievement.id).label('achievement_count')
        ).join(
            UserAchievement, User.id == UserAchievement.user_id
        ).join(
            Achievement, UserAchievement.achievement_id == Achievement.id
        ).group_by(
            User.id, User.username
        ).order_by(
            func.sum(Achievement.points).desc()
        ).limit(limit).all()
        
        leaderboard_list = []
        for rank, (user_id, username, total_points, achievement_count) in enumerate(leaderboard, 1):
            leaderboard_list.append({
                'rank': rank,
                'user_id': user_id,
                'username': username,
                'total_points': total_points or 0,
                'achievement_count': achievement_count
            })
        
        return jsonify({
            'leaderboard': leaderboard_list,
            'total_users': len(leaderboard_list)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/create', methods=['POST'])
def create_achievement():
    """Create a new achievement (admin function)"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('name'):
            return jsonify({'error': 'name is required'}), 400
        
        new_achievement = Achievement(
            name=data['name'],
            description=data.get('description'),
            icon_url=data.get('icon_url'),
            badge_type=data.get('badge_type'),
            criteria_type=data.get('criteria_type'),
            criteria_value=data.get('criteria_value'),
            points=data.get('points', 0)
        )
        
        db.session.add(new_achievement)
        db.session.commit()
        
        return jsonify({
            'message': 'Achievement created successfully',
            'achievement': new_achievement.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500