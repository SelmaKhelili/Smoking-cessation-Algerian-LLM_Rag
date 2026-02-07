# ============================================
# FILE: app/routes/content.py
# Educational Content Routes
# ============================================
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.content import EducationalContent, UserContentProgress
from app.models.user import User
from app.utils.constants import (
    CONTENT_HEALTH_RISKS, CONTENT_CESSATION_STRATEGIES,
    CONTENT_COPING_MECHANISMS, CONTENT_SUCCESS_STORIES,
    CONTENT_FINANCIAL_IMPACT
)
from datetime import datetime
from sqlalchemy import desc, func

bp = Blueprint('content', __name__)


@bp.route('/', methods=['GET'])
def get_all_content():
    """Get all published educational content"""
    try:
        # Get filter parameters
        category = request.args.get('category')
        language = request.args.get('language')
        content_type = request.args.get('content_type')
        
        # Pagination
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # Build query - only published content
        query = EducationalContent.query.filter_by(is_published=True)
        
        if category:
            query = query.filter_by(category=category)
        if language:
            query = query.filter_by(language=language)
        if content_type:
            query = query.filter_by(content_type=content_type)
        
        # Order by creation date (newest first)
        query = query.order_by(desc(EducationalContent.created_at))
        
        # Paginate
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        content_list = pagination.items
        
        return jsonify({
            'content': [content.to_dict() for content in content_list],
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:content_id>', methods=['GET'])
def get_content(content_id):
    """Get a specific educational content"""
    try:
        content = EducationalContent.query.get(content_id)
        if not content:
            return jsonify({'error': 'Content not found'}), 404
        
        if not content.is_published:
            return jsonify({'error': 'Content is not published'}), 403
        
        return jsonify({'content': content.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/category/<category>', methods=['GET'])
def get_by_category(category):
    """Get content by category"""
    try:
        # Pagination
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # Query published content in category
        pagination = EducationalContent.query.filter_by(
            category=category,
            is_published=True
        ).order_by(
            desc(EducationalContent.created_at)
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        content_list = pagination.items
        
        return jsonify({
            'category': category,
            'content': [content.to_dict() for content in content_list],
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/categories', methods=['GET'])
def get_categories():
    """Get all available content categories"""
    try:
        categories = [
            {'id': CONTENT_HEALTH_RISKS, 'name': 'Health Risks', 'name_ar': 'المخاطر الصحية'},
            {'id': CONTENT_CESSATION_STRATEGIES, 'name': 'Cessation Strategies', 'name_ar': 'استراتيجيات الإقلاع'},
            {'id': CONTENT_COPING_MECHANISMS, 'name': 'Coping Mechanisms', 'name_ar': 'آليات التكيف'},
            {'id': CONTENT_SUCCESS_STORIES, 'name': 'Success Stories', 'name_ar': 'قصص نجاح'},
            {'id': CONTENT_FINANCIAL_IMPACT, 'name': 'Financial Impact', 'name_ar': 'التأثير المالي'}
        ]
        
        # Count content in each category
        for category in categories:
            count = EducationalContent.query.filter_by(
                category=category['id'],
                is_published=True
            ).count()
            category['content_count'] = count
        
        return jsonify({'categories': categories}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:content_id>/progress', methods=['POST'])
def update_progress(content_id):
    """Update user's progress on content"""
    try:
        data = request.get_json()
        
        if not data.get('user_id'):
            return jsonify({'error': 'user_id is required'}), 400
        
        user_id = data['user_id']
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Check if content exists
        content = EducationalContent.query.get(content_id)
        if not content:
            return jsonify({'error': 'Content not found'}), 404
        
        # Check if progress record exists
        progress = UserContentProgress.query.filter_by(
            user_id=user_id,
            content_id=content_id
        ).first()
        
        if not progress:
            # Create new progress record
            progress = UserContentProgress(
                user_id=user_id,
                content_id=content_id,
                progress_percentage=data.get('progress_percentage', 0),
                completed=data.get('completed', False)
            )
            db.session.add(progress)
        else:
            # Update existing progress
            if 'progress_percentage' in data:
                progress.progress_percentage = data['progress_percentage']
            if 'completed' in data:
                progress.completed = data['completed']
            progress.last_accessed = datetime.utcnow()
        
        # Auto-complete if progress >= 100
        if progress.progress_percentage >= 100:
            progress.completed = True
        
        db.session.commit()
        
        return jsonify({
            'message': 'Progress updated successfully',
            'progress': progress.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/progress/<int:user_id>', methods=['GET'])
def get_user_progress(user_id):
    """Get all content progress for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get all progress records with content details
        progress_list = db.session.query(
            UserContentProgress, EducationalContent
        ).join(
            EducationalContent,
            UserContentProgress.content_id == EducationalContent.id
        ).filter(
            UserContentProgress.user_id == user_id
        ).order_by(
            desc(UserContentProgress.last_accessed)
        ).all()
        
        result = []
        for progress, content in progress_list:
            progress_dict = progress.to_dict()
            progress_dict['content'] = content.to_dict()
            result.append(progress_dict)
        
        return jsonify({
            'progress': result,
            'total': len(result)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/recommended', methods=['GET'])
def get_recommended():
    """Get personalized content recommendations"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get content user hasn't completed
        completed_ids = db.session.query(UserContentProgress.content_id).filter_by(
            user_id=user_id,
            completed=True
        ).all()
        completed_ids = [id[0] for id in completed_ids]
        
        # Get published content not yet completed
        query = EducationalContent.query.filter(
            EducationalContent.is_published == True,
            ~EducationalContent.id.in_(completed_ids) if completed_ids else True
        )
        
        # Simple recommendation: prioritize by category order
        # TODO: Add smarter recommendation logic based on user profile
        recommended = query.order_by(
            EducationalContent.category,
            desc(EducationalContent.created_at)
        ).limit(10).all()
        
        return jsonify({
            'recommended': [content.to_dict() for content in recommended],
            'total': len(recommended)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_content_statistics(user_id):
    """Get content consumption statistics for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Total content available
        total_content = EducationalContent.query.filter_by(is_published=True).count()
        
        # Content accessed by user
        accessed_count = UserContentProgress.query.filter_by(user_id=user_id).count()
        
        # Completed content
        completed_count = UserContentProgress.query.filter_by(
            user_id=user_id,
            completed=True
        ).count()
        
        # Average progress on uncompleted content
        uncompleted = UserContentProgress.query.filter_by(
            user_id=user_id,
            completed=False
        ).all()
        
        avg_progress = 0
        if uncompleted:
            total_progress = sum(p.progress_percentage for p in uncompleted)
            avg_progress = round(total_progress / len(uncompleted), 1)
        
        # Completion rate
        completion_rate = 0
        if accessed_count > 0:
            completion_rate = round((completed_count / accessed_count) * 100, 1)
        
        # Completed by category
        completed_by_category = db.session.query(
            EducationalContent.category,
            func.count(UserContentProgress.id)
        ).join(
            UserContentProgress,
            EducationalContent.id == UserContentProgress.content_id
        ).filter(
            UserContentProgress.user_id == user_id,
            UserContentProgress.completed == True
        ).group_by(
            EducationalContent.category
        ).all()
        
        category_stats = {cat: count for cat, count in completed_by_category}
        
        return jsonify({
            'statistics': {
                'total_available': total_content,
                'accessed_count': accessed_count,
                'completed_count': completed_count,
                'in_progress': accessed_count - completed_count,
                'completion_rate': completion_rate,
                'avg_progress_uncompleted': avg_progress,
                'completed_by_category': category_stats
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/create', methods=['POST'])
def create_content():
    """Create new educational content (admin function)"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('title'):
            return jsonify({'error': 'title is required'}), 400
        
        new_content = EducationalContent(
            title=data['title'],
            content_type=data.get('content_type'),
            content_text=data.get('content_text'),
            content_url=data.get('content_url'),
            category=data.get('category'),
            language=data.get('language', 'ar-dz'),
            reading_time=data.get('reading_time'),
            is_published=data.get('is_published', False)
        )
        
        db.session.add(new_content)
        db.session.commit()
        
        return jsonify({
            'message': 'Content created successfully',
            'content': new_content.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:content_id>', methods=['PUT'])
def update_content(content_id):
    """Update educational content (admin function)"""
    try:
        data = request.get_json()
        
        content = EducationalContent.query.get(content_id)
        if not content:
            return jsonify({'error': 'Content not found'}), 404
        
        # Update fields
        if 'title' in data:
            content.title = data['title']
        if 'content_type' in data:
            content.content_type = data['content_type']
        if 'content_text' in data:
            content.content_text = data['content_text']
        if 'content_url' in data:
            content.content_url = data['content_url']
        if 'category' in data:
            content.category = data['category']
        if 'language' in data:
            content.language = data['language']
        if 'reading_time' in data:
            content.reading_time = data['reading_time']
        if 'is_published' in data:
            content.is_published = data['is_published']
        
        content.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Content updated successfully',
            'content': content.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/<int:content_id>', methods=['DELETE'])
def delete_content(content_id):
    """Delete educational content (admin function)"""
    try:
        content = EducationalContent.query.get(content_id)
        if not content:
            return jsonify({'error': 'Content not found'}), 404
        
        db.session.delete(content)
        db.session.commit()
        
        return jsonify({'message': 'Content deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/search', methods=['GET'])
def search_content():
    """Search educational content"""
    try:
        query_text = request.args.get('q', '')
        if not query_text:
            return jsonify({'error': 'Search query (q) is required'}), 400
        
        # Search in title and content_text
        results = EducationalContent.query.filter(
            EducationalContent.is_published == True,
            db.or_(
                EducationalContent.title.ilike(f'%{query_text}%'),
                EducationalContent.content_text.ilike(f'%{query_text}%')
            )
        ).order_by(desc(EducationalContent.created_at)).limit(20).all()
        
        return jsonify({
            'query': query_text,
            'results': [content.to_dict() for content in results],
            'total': len(results)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500