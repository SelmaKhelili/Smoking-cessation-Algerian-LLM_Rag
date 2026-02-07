from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.chat import ChatSession, ChatMessage
from app.models.user import User, UserProfile
from app.utils.constants import SENDER_USER, SENDER_ASSISTANT
from datetime import datetime
from sqlalchemy import desc
import requests
import os

bp = Blueprint('chat', __name__)

# RAG API Configuration
RAG_API_URL = os.environ.get('RAG_API_URL', 'https://shawana-knurly-merrill.ngrok-free.dev/query')


@bp.route('/session', methods=['POST'])
def create_session():
    """Create a new chat session"""
    try:
        data = request.get_json()
        
        if not data.get('user_id'):
            return jsonify({'error': 'user_id is required'}), 400
        
        user_id = data['user_id']
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Create new session
        new_session = ChatSession(
            user_id=user_id,
            session_title=data.get('session_title', f'Chat - {datetime.utcnow().strftime("%Y-%m-%d %H:%M")}')
        )
        
        db.session.add(new_session)
        db.session.commit()
        
        return jsonify({
            'message': 'Chat session created successfully',
            'session': new_session.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions', methods=['GET'])
def get_sessions():
    """Get all chat sessions for a user"""
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'error': 'user_id is required'}), 400
        
        # Check if user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get filter parameters
        is_active = request.args.get('is_active', type=bool)
        
        # Build query
        query = ChatSession.query.filter_by(user_id=user_id)
        
        if is_active is not None:
            query = query.filter_by(is_active=is_active)
        
        # Order by last message (most recent first)
        sessions = query.order_by(desc(ChatSession.last_message_at)).all()
        
        return jsonify({
            'sessions': [session.to_dict() for session in sessions],
            'total': len(sessions)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions/<int:session_id>', methods=['GET'])
def get_session(session_id):
    """Get a specific chat session"""
    try:
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        return jsonify({'session': session.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions/<int:session_id>', methods=['PUT'])
def update_session(session_id):
    """Update chat session (e.g., rename, archive)"""
    try:
        data = request.get_json()
        
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        # Update fields
        if 'session_title' in data:
            session.session_title = data['session_title']
        if 'is_active' in data:
            session.is_active = data['is_active']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Session updated successfully',
            'session': session.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions/<int:session_id>', methods=['DELETE'])
def delete_session(session_id):
    """Delete a chat session (cascade deletes all messages)"""
    try:
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        db.session.delete(session)
        db.session.commit()
        
        return jsonify({'message': 'Session deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/message', methods=['POST'])
def send_message():
    """Send a message to the AI assistant"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('session_id') or not data.get('message'):
            return jsonify({'error': 'session_id and message are required'}), 400
        
        session_id = data['session_id']
        
        # Check if session exists
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        # Save user message
        user_message = ChatMessage(
            session_id=session_id,
            sender_type=SENDER_USER,
            message_text=data['message'],
            message_metadata=data.get('metadata')
        )
        
        db.session.add(user_message)
        
        # Update session
        session.last_message_at = datetime.utcnow()
        session.message_count += 1
        
        db.session.flush()  # Flush to get user_message.id
        
        # Call RAG API
        try:
            rag_response = requests.post(
                RAG_API_URL,
                json={'query': data['message']},
                timeout=30
            )
            
            if rag_response.status_code == 200:
                rag_data = rag_response.json()
                ai_response_text = rag_data.get('answer', 'عذرا، ما قدرتش نجاوب دابا.')
                # Store RAG metadata (sources, confidence, etc.)
                rag_metadata = {
                    'intent': rag_data.get('intent'),
                    'confidence': rag_data.get('confidence'),
                    'sources_used': len(rag_data.get('sources', [])),
                    'use_rag': rag_data.get('use_rag', False)
                }
            else:
                ai_response_text = 'عذرا، صار خلل في الخدمة. حاول مرة أخرى.'
                rag_metadata = {'error': 'RAG API returned non-200 status'}
        except requests.exceptions.Timeout:
            ai_response_text = 'عذرا، الطلب أخذ وقت طويل. حاول مرة أخرى.'
            rag_metadata = {'error': 'timeout'}
        except Exception as e:
            # Fallback to placeholder if RAG API fails
            ai_response_text = generate_placeholder_response(data['message'], session.user_id)
            rag_metadata = {'error': str(e), 'fallback': True}
        
        # Save AI response
        ai_message = ChatMessage(
            session_id=session_id,
            sender_type=SENDER_ASSISTANT,
            message_text=ai_response_text,
            message_metadata=rag_metadata  # Store RAG metadata
        )
        
        db.session.add(ai_message)
        
        # Update session again
        session.last_message_at = datetime.utcnow()
        session.message_count += 1
        
        db.session.commit()
        
        return jsonify({
            'message': 'Message sent successfully',
            'user_message': user_message.to_dict(),
            'ai_response': ai_message.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions/<int:session_id>/messages', methods=['GET'])
def get_messages(session_id):
    """Get all messages in a chat session"""
    try:
        # Check if session exists
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        # Get messages ordered by creation time
        pagination = ChatMessage.query.filter_by(
            session_id=session_id
        ).order_by(
            ChatMessage.created_at
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        messages = pagination.items
        
        return jsonify({
            'messages': [message.to_dict() for message in messages],
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page,
            'session': session.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/messages/<int:message_id>', methods=['GET'])
def get_message(message_id):
    """Get a specific message"""
    try:
        message = ChatMessage.query.get(message_id)
        if not message:
            return jsonify({'error': 'Message not found'}), 404
        
        return jsonify({'message': message.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/messages/<int:message_id>/flag', methods=['POST'])
def flag_message(message_id):
    """Flag a message for review (content moderation)"""
    try:
        message = ChatMessage.query.get(message_id)
        if not message:
            return jsonify({'error': 'Message not found'}), 404
        
        message.flagged = True
        db.session.commit()
        
        return jsonify({
            'message': 'Message flagged successfully',
            'flagged_message': message.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_chat_statistics(user_id):
    """Get chat statistics for a user"""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Count sessions
        total_sessions = ChatSession.query.filter_by(user_id=user_id).count()
        active_sessions = ChatSession.query.filter_by(user_id=user_id, is_active=True).count()
        
        # Count messages
        user_sessions = ChatSession.query.filter_by(user_id=user_id).all()
        session_ids = [s.id for s in user_sessions]
        
        total_messages = ChatMessage.query.filter(
            ChatMessage.session_id.in_(session_ids)
        ).count()
        
        user_messages = ChatMessage.query.filter(
            ChatMessage.session_id.in_(session_ids),
            ChatMessage.sender_type == SENDER_USER
        ).count()
        
        ai_messages = ChatMessage.query.filter(
            ChatMessage.session_id.in_(session_ids),
            ChatMessage.sender_type == SENDER_ASSISTANT
        ).count()
        
        # Average messages per session
        avg_messages_per_session = 0
        if total_sessions > 0:
            avg_messages_per_session = round(total_messages / total_sessions, 1)
        
        return jsonify({
            'statistics': {
                'total_sessions': total_sessions,
                'active_sessions': active_sessions,
                'total_messages': total_messages,
                'user_messages': user_messages,
                'ai_messages': ai_messages,
                'avg_messages_per_session': avg_messages_per_session
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/sessions/<int:session_id>/context', methods=['GET'])
def get_session_context(session_id):
    """Get context for a session (last N messages for LLM)"""
    try:
        session = ChatSession.query.get(session_id)
        if not session:
            return jsonify({'error': 'Session not found'}), 404
        
        # Get last N messages (default 10)
        limit = request.args.get('limit', 10, type=int)
        
        messages = ChatMessage.query.filter_by(
            session_id=session_id
        ).order_by(
            desc(ChatMessage.created_at)
        ).limit(limit).all()
        
        # Reverse to get chronological order
        messages.reverse()
        
        # Get user profile for context
        profile = UserProfile.query.filter_by(user_id=session.user_id).first()
        
        context = {
            'session': session.to_dict(),
            'messages': [message.to_dict() for message in messages],
            'user_profile': profile.to_dict() if profile else None
        }
        
        return jsonify(context), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============================================
# Helper Functions
# ============================================

def generate_placeholder_response(user_message, user_id):
    """
    Placeholder response generator
    TODO: Replace with actual LLM service call
    """
    
    # Get user profile for personalization
    profile = UserProfile.query.filter_by(user_id=user_id).first()
    
    user_message_lower = user_message.lower()
    
    # Simple keyword-based responses (placeholder)
    if 'help' in user_message_lower or 'مساعدة' in user_message_lower:
        return "مرحبا! أنا هنا لمساعدتك في رحلتك للإقلاع عن التدخين. كيف يمكنني مساعدتك اليوم؟"
    
    elif 'craving' in user_message_lower or 'رغبة' in user_message_lower:
        return "أفهم أنك تشعر برغبة في التدخين. جرب أخذ نفس عميق، اشرب الماء، أو قم بنشاط بدني قصير. الرغبة ستمر في غضون دقائق!"
    
    elif 'motivation' in user_message_lower or 'تحفيز' in user_message_lower:
        if profile and profile.current_streak_days > 0:
            return f"رائع! لديك {profile.current_streak_days} يوم بدون تدخين! استمر في هذا المجهود الرائع. أنت أقوى من الإدمان!"
        else:
            return "كل يوم بدون تدخين هو انتصار! أنت تستطيع فعل ذلك. فكر في صحتك وعائلتك."
    
    elif 'stress' in user_message_lower or 'توتر' in user_message_lower or 'قلق' in user_message_lower:
        return "التوتر طبيعي، لكن التدخين ليس الحل. جرب تقنيات التنفس، المشي، أو التحدث مع صديق. لديك القوة للتعامل مع التوتر بدون سجائر!"
    
    elif 'goal' in user_message_lower or 'هدف' in user_message_lower:
        return "تحديد أهداف واضحة مهم جدا! ما هو هدفك اليوم؟ يمكنني مساعدتك في تتبع تقدمك."
    
    else:
        return "شكرا لمشاركتك. أنا هنا لدعمك في رحلتك للإقلاع عن التدخين. هل لديك أي أسئلة محددة؟"