# ============================================
# FILE: app/routes/goals.py
# Goals Management Routes
# ============================================
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.goal import Goal
from app.models.user import User
from app.utils.constants import *
from datetime import datetime

bp = Blueprint('goals', __name__)


@bp.route('/', methods=['POST'])
def create_goal():
    """Create a new goal"""
    try:
        data = request.get_json()
        
        # Validate required fields (allow target_value = 0)
        if not data.get('user_id') or not data.get('goal_type') or data.get('target_value') is None or not data.get('start_date'):
            return jsonify({'error': 'user_id, goal_type, target_value, and start_date are required'}), 400
        
        user_id = data['user_id']
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Validate goal type
        if data['goal_type'] not in GOAL_TYPES:
            return jsonify({'error': f'Invalid goal_type. Must be one of: {", ".join(GOAL_TYPES)}'}), 400
        
        # Parse dates
        start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
        target_date = datetime.strptime(data['target_date'], '%Y-%m-%d').date() if data.get('target_date') else None
        
        # Validate target_date is after start_date
        if target_date and target_date <= start_date:
            return jsonify({'error': 'target_date must be after start_date'}), 400
        
        # Create new goal
        new_goal = Goal(
            user_id=user_id,
            goal_type=data['goal_type'],
            target_value=data['target_value'],
            current_value=data.get('current_value', 0),
            start_date=start_date,
            target_date=target_date,
            status=GOAL_STATUS_ACTIVE,
            description=data.get('description')
        )
        
        db.session.add(new_goal)
        db.session.commit()
        
        return jsonify({
            'message': 'Goal created successfully',
            'goal': new_goal.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/', methods=['GET'])
def get_all_goals():
    """Get all goals for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get filter parameters
        status = request.args.get('status')  # optional: 'active', 'completed', 'failed', 'paused'
        goal_type = request.args.get('goal_type')  # optional filter
        
        # Build query
        query = Goal.query.filter_by(user_id=user_id)
        
        if status:
            query = query.filter_by(status=status)
        if goal_type:
            query = query.filter_by(goal_type=goal_type)
        
        # Order by created_at descending
        goals = query.order_by(Goal.created_at.desc()).all()
        
        return jsonify({
            'goals': [goal.to_dict() for goal in goals],
            'total': len(goals)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>', methods=['GET'])
def get_goal(goal_id):
    """Get a specific goal"""
    try:
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        return jsonify({'goal': goal.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>', methods=['PUT'])
def update_goal(goal_id):
    """Update a goal"""
    try:
        data = request.get_json()
        
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        # Update fields (allow target_value = 0)
        if 'target_value' in data:
            goal.target_value = data['target_value']
        if 'target_date' in data:
            goal.target_date = datetime.strptime(data['target_date'], '%Y-%m-%d').date() if data['target_date'] else None
        if 'status' in data:
            goal.status = data['status']
            # Set completed_at if status is completed
            if data['status'] == GOAL_STATUS_COMPLETED and not goal.completed_at:
                goal.completed_at = datetime.utcnow()
        if 'description' in data:
            goal.description = data['description']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Goal updated successfully',
            'goal': goal.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>', methods=['DELETE'])
def delete_goal(goal_id):
    """Delete a goal"""
    try:
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        db.session.delete(goal)
        db.session.commit()
        
        return jsonify({'message': 'Goal deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>/progress', methods=['POST'])
def update_progress(goal_id):
    """Update goal progress"""
    try:
        data = request.get_json()
        
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        if 'current_value' not in data:
            return jsonify({'error': 'current_value is required'}), 400
        
        # Update current value
        goal.current_value = data['current_value']
        
        # Check if goal is completed
        if goal.current_value >= goal.target_value and goal.status == GOAL_STATUS_ACTIVE:
            goal.status = GOAL_STATUS_COMPLETED
            goal.completed_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Progress updated successfully',
            'goal': goal.to_dict(),
            'completed': goal.status == GOAL_STATUS_COMPLETED
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/active', methods=['GET'])
def get_active_goals():
    """Get all active goals for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        goals = Goal.query.filter_by(
            user_id=user_id,
            status=GOAL_STATUS_ACTIVE
        ).order_by(Goal.created_at.desc()).all()
        
        return jsonify({
            'active_goals': [goal.to_dict() for goal in goals],
            'total': len(goals)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/completed', methods=['GET'])
def get_completed_goals():
    """Get all completed goals for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        goals = Goal.query.filter_by(
            user_id=user_id,
            status=GOAL_STATUS_COMPLETED
        ).order_by(Goal.completed_at.desc()).all()
        
        return jsonify({
            'completed_goals': [goal.to_dict() for goal in goals],
            'total': len(goals)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_goal_statistics(user_id):
    """Get goal statistics for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Count goals by status
        total_goals = Goal.query.filter_by(user_id=user_id).count()
        active_goals = Goal.query.filter_by(user_id=user_id, status=GOAL_STATUS_ACTIVE).count()
        completed_goals = Goal.query.filter_by(user_id=user_id, status=GOAL_STATUS_COMPLETED).count()
        failed_goals = Goal.query.filter_by(user_id=user_id, status=GOAL_STATUS_FAILED).count()
        paused_goals = Goal.query.filter_by(user_id=user_id, status=GOAL_STATUS_PAUSED).count()
        
        # Calculate completion rate
        completion_rate = 0
        if total_goals > 0:
            completion_rate = round((completed_goals / total_goals) * 100, 1)
        
        # Get goals by type
        goals_by_type = {}
        for goal_type in GOAL_TYPES:
            count = Goal.query.filter_by(user_id=user_id, goal_type=goal_type).count()
            goals_by_type[goal_type] = count
        
        # Get average progress of active goals
        active_goal_list = Goal.query.filter_by(user_id=user_id, status=GOAL_STATUS_ACTIVE).all()
        avg_progress = 0
        if active_goal_list:
            total_progress = sum(
                (goal.current_value / goal.target_value * 100) if goal.target_value > 0 else 0
                for goal in active_goal_list
            )
            avg_progress = round(total_progress / len(active_goal_list), 1)
        
        return jsonify({
            'statistics': {
                'total_goals': total_goals,
                'active_goals': active_goals,
                'completed_goals': completed_goals,
                'failed_goals': failed_goals,
                'paused_goals': paused_goals,
                'completion_rate': completion_rate,
                'average_active_progress': avg_progress,
                'goals_by_type': goals_by_type
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>/complete', methods=['POST'])
def mark_complete(goal_id):
    """Mark a goal as completed"""
    try:
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        goal.status = GOAL_STATUS_COMPLETED
        goal.completed_at = datetime.utcnow()
        goal.current_value = goal.target_value
        
        db.session.commit()
        
        return jsonify({
            'message': 'Goal marked as completed',
            'goal': goal.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>/pause', methods=['POST'])
def pause_goal(goal_id):
    """Pause a goal"""
    try:
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        goal.status = GOAL_STATUS_PAUSED
        db.session.commit()
        
        return jsonify({
            'message': 'Goal paused',
            'goal': goal.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:goal_id>/resume', methods=['POST'])
def resume_goal(goal_id):
    """Resume a paused goal"""
    try:
        goal = Goal.query.get(goal_id)
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        if goal.status != GOAL_STATUS_PAUSED:
            return jsonify({'error': 'Goal is not paused'}), 400
        
        goal.status = GOAL_STATUS_ACTIVE
        db.session.commit()
        
        return jsonify({
            'message': 'Goal resumed',
            'goal': goal.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500



@bp.route('/<int:goal_id>/mark_notified', methods=['PATCH'])
def mark_goal_notified(goal_id):
    goal = Goal.query.get(goal_id)
    if not goal:
        return jsonify({'error': 'Goal not found'}), 404
    
    goal.notification_sent = True
    db.session.commit()
    return jsonify({'message': 'Goal notification marked as sent'}), 200
