from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.notification import Notification
from app.models.user import User
from app.utils.constants import (
    NOTIF_ACHIEVEMENT_EARNED, NOTIF_GOAL_COMPLETED,
    NOTIF_DAILY_REMINDER, NOTIF_STREAK_MILESTONE,
    NOTIF_MOTIVATIONAL, NOTIF_EDUCATIONAL
)
from datetime import datetime, timedelta
from sqlalchemy import desc

bp = Blueprint('notifications', __name__)


@bp.route('/', methods=['GET'])
def get_all_notifications():
    """Get all notifications for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # Get filter parameters
        is_read = request.args.get('is_read', type=bool)
        notification_type = request.args.get('notification_type')
        
        # Build query
        query = Notification.query.filter_by(user_id=user_id)
        
        if is_read is not None:
            query = query.filter_by(is_read=is_read)
        if notification_type:
            query = query.filter_by(notification_type=notification_type)
        
        # Order by creation date (newest first)
        query = query.order_by(desc(Notification.created_at))
        
        # Paginate
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        notifications = pagination.items
        
        return jsonify({
            'notifications': [notif.to_dict() for notif in notifications],
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page,
            'unread_count': Notification.query.filter_by(user_id=user_id, is_read=False).count()
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:notification_id>', methods=['GET'])
def get_notification(notification_id):
    """Get a specific notification"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'error': 'Notification not found'}), 404
        
        return jsonify({'notification': notification.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/unread', methods=['GET'])
def get_unread_notifications():
    """Get all unread notifications for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get limit parameter
        limit = request.args.get('limit', 50, type=int)
        
        notifications = Notification.query.filter_by(
            user_id=user_id,
            is_read=False
        ).order_by(
            desc(Notification.created_at)
        ).limit(limit).all()
        
        return jsonify({
            'unread_notifications': [notif.to_dict() for notif in notifications],
            'count': len(notifications)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:notification_id>/read', methods=['PUT'])
def mark_as_read(notification_id):
    """Mark a notification as read"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'error': 'Notification not found'}), 404
        
        if not notification.is_read:
            notification.is_read = True
            notification.read_at = datetime.utcnow()
            db.session.commit()
        
        return jsonify({
            'message': 'Notification marked as read',
            'notification': notification.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/read-all', methods=['PUT'])
def mark_all_as_read():
    """Mark all notifications as read for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Update all unread notifications
        unread_notifications = Notification.query.filter_by(
            user_id=user_id,
            is_read=False
        ).all()
        
        count = 0
        for notification in unread_notifications:
            notification.is_read = True
            notification.read_at = datetime.utcnow()
            count += 1
        
        db.session.commit()
        
        return jsonify({
            'message': f'Marked {count} notifications as read',
            'count': count
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:notification_id>', methods=['DELETE'])
def delete_notification(notification_id):
    """Delete a notification"""
    try:
        notification = Notification.query.get(notification_id)
        if not notification:
            return jsonify({'error': 'Notification not found'}), 404
        
        db.session.delete(notification)
        db.session.commit()
        
        return jsonify({'message': 'Notification deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/delete-read', methods=['DELETE'])
def delete_read_notifications():
    """Delete all read notifications for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Delete all read notifications
        read_notifications = Notification.query.filter_by(
            user_id=user_id,
            is_read=True
        ).all()
        
        count = len(read_notifications)
        for notification in read_notifications:
            db.session.delete(notification)
        
        db.session.commit()
        
        return jsonify({
            'message': f'Deleted {count} read notifications',
            'count': count
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/create', methods=['POST'])
def create_notification():
    """Create a new notification"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('user_id') or not data.get('notification_type') or not data.get('title') or not data.get('message'):
            return jsonify({'error': 'user_id, notification_type, title, and message are required'}), 400
        
        user_id = data['user_id']
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Create notification
        new_notification = Notification(
            user_id=user_id,
            notification_type=data['notification_type'],
            title=data['title'],
            message=data['message']
        )
        
        db.session.add(new_notification)
        db.session.commit()
        
        return jsonify({
            'message': 'Notification created successfully',
            'notification': new_notification.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_notification_statistics(user_id):
    """Get notification statistics for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Total notifications
        total_notifications = Notification.query.filter_by(user_id=user_id).count()
        
        # Unread count
        unread_count = Notification.query.filter_by(user_id=user_id, is_read=False).count()
        
        # Read count
        read_count = Notification.query.filter_by(user_id=user_id, is_read=True).count()
        
        # Count by type
        notifications_by_type = {}
        notification_types = [
            NOTIF_ACHIEVEMENT_EARNED,
            NOTIF_GOAL_COMPLETED,
            NOTIF_DAILY_REMINDER,
            NOTIF_STREAK_MILESTONE,
            NOTIF_MOTIVATIONAL,
            NOTIF_EDUCATIONAL
        ]
        
        for notif_type in notification_types:
            count = Notification.query.filter_by(
                user_id=user_id,
                notification_type=notif_type
            ).count()
            notifications_by_type[notif_type] = count
        
        # Recent notifications (last 7 days)
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_count = Notification.query.filter(
            Notification.user_id == user_id,
            Notification.created_at >= seven_days_ago
        ).count()
        
        return jsonify({
            'statistics': {
                'total_notifications': total_notifications,
                'unread_count': unread_count,
                'read_count': read_count,
                'notifications_by_type': notifications_by_type,
                'recent_count': recent_count
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/types', methods=['GET'])
def get_notification_types():
    """Get all notification types"""
    try:
        types = [
            {'id': NOTIF_ACHIEVEMENT_EARNED, 'name': 'Achievement Earned', 'name_ar': 'إنجاز جديد'},
            {'id': NOTIF_GOAL_COMPLETED, 'name': 'Goal Completed', 'name_ar': 'هدف مكتمل'},
            {'id': NOTIF_DAILY_REMINDER, 'name': 'Daily Reminder', 'name_ar': 'تذكير يومي'},
            {'id': NOTIF_STREAK_MILESTONE, 'name': 'Streak Milestone', 'name_ar': 'إنجاز متتابع'},
            {'id': NOTIF_MOTIVATIONAL, 'name': 'Motivational Message', 'name_ar': 'رسالة تحفيزية'},
            {'id': NOTIF_EDUCATIONAL, 'name': 'Educational Content', 'name_ar': 'محتوى تعليمي'}
        ]
        
        return jsonify({'notification_types': types}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/send-bulk', methods=['POST'])
def send_bulk_notifications():
    """Send notification to multiple users (admin function)"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('user_ids') or not data.get('notification_type') or not data.get('title') or not data.get('message'):
            return jsonify({'error': 'user_ids (array), notification_type, title, and message are required'}), 400
        
        user_ids = data['user_ids']
        notification_type = data['notification_type']
        title = data['title']
        message = data['message']
        
        created_count = 0
        failed_count = 0
        
        for user_id in user_ids:
            # Check if user exists
            user = User.query.get(user_id)
            if not user:
                failed_count += 1
                continue
            
            # Create notification
            notification = Notification(
                user_id=user_id,
                notification_type=notification_type,
                title=title,
                message=message
            )
            db.session.add(notification)
            created_count += 1
        
        db.session.commit()
        
        return jsonify({
            'message': f'Sent {created_count} notifications',
            'created_count': created_count,
            'failed_count': failed_count
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/recent', methods=['GET'])
def get_recent_notifications():
    """Get recent notifications (last N days)"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get days parameter (default: 7)
        days = request.args.get('days', 7, type=int)
        days_ago = datetime.utcnow() - timedelta(days=days)
        
        notifications = Notification.query.filter(
            Notification.user_id == user_id,
            Notification.created_at >= days_ago
        ).order_by(
            desc(Notification.created_at)
        ).all()
        
        return jsonify({
            'recent_notifications': [notif.to_dict() for notif in notifications],
            'count': len(notifications),
            'days': days
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/clear-old', methods=['DELETE'])
def clear_old_notifications():
    """Clear old read notifications (older than N days)"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get days parameter (default: 30)
        days = request.args.get('days', 30, type=int)
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        # Delete old read notifications
        old_notifications = Notification.query.filter(
            Notification.user_id == user_id,
            Notification.is_read == True,
            Notification.created_at < cutoff_date
        ).all()
        
        count = len(old_notifications)
        for notification in old_notifications:
            db.session.delete(notification)
        
        db.session.commit()
        
        return jsonify({
            'message': f'Deleted {count} old notifications',
            'count': count,
            'older_than_days': days
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500