from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.tracking import SmokingRecord
from app.models.user import User, UserProfile
from datetime import datetime, timedelta
from sqlalchemy import func, desc
from app.models.notification import Notification
bp = Blueprint('tracking', __name__)

CIGARETTE_PRICE = 25  # ✅ CONSTANT PRICE

# -------------------- CREATE RECORD --------------------
@bp.route('/record', methods=['POST'])
def create_record():
    try:
        data = request.get_json() or {}

        if not data.get('user_id') or not data.get('record_date') or data.get('cigarettes_smoked') is None:
            return jsonify({'error': 'user_id, record_date, and cigarettes_smoked are required'}), 400

        user_id = data['user_id']
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        record_date = datetime.strptime(data['record_date'], '%Y-%m-%d').date()

        existing_record = SmokingRecord.query.filter_by(
            user_id=user_id, record_date=record_date
        ).first()
        if existing_record:
            return jsonify({'error': 'Record already exists for this date. Use PUT to update.'}), 400

        new_record = SmokingRecord(
            user_id=user_id,
            record_date=record_date,
            cigarettes_smoked=data['cigarettes_smoked'],
            cravings_count=data.get('cravings_count', 0),
            mood=data.get('mood'),
            triggers=data.get('triggers'),
            notes=data.get('notes')
        )
        db.session.add(new_record)

        profile = UserProfile.query.filter_by(user_id=user_id).first()
        if not profile:
            profile = UserProfile(user_id=user_id)
            db.session.add(profile)

        # ---- STREAK LOGIC ----
        if data['cigarettes_smoked'] == 0:
            profile.current_streak_days = (profile.current_streak_days or 0) + 1
            profile.longest_streak_days = max(
                profile.longest_streak_days or 0,
                profile.current_streak_days
            )
        else:
            profile.current_streak_days = 0

        # ---- MONEY & AVOIDED CALCULATION (BACKEND ONLY) ----
        cigarettes_per_day = profile.cigarettes_per_day or 0
        avoided = max(cigarettes_per_day - data['cigarettes_smoked'], 0)

        profile.total_cigarettes_avoided = (profile.total_cigarettes_avoided or 0) + avoided
        profile.total_money_saved = (profile.total_money_saved or 0) + (avoided * CIGARETTE_PRICE)

        profile.updated_at = datetime.utcnow()
        
        # FIRST COMMIT - Save record and profile updates
        db.session.commit()

        # -------------------- CHECK ACHIEVEMENTS --------------------
        from app.models.achievement import Achievement, UserAchievement
        all_achievements = Achievement.query.all()
        earned_ids = [id[0] for id in db.session.query(UserAchievement.achievement_id).filter_by(user_id=user_id).all()]
        newly_earned = []

        for achievement in all_achievements:
            if achievement.id in earned_ids:
                continue

            earned = False

            if achievement.criteria_type == 'days_smoke_free' and profile:
                if profile.longest_streak_days and profile.longest_streak_days >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'money_saved' and profile:
                if profile.total_money_saved >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'goals_completed':
                from app.models.goal import Goal
                completed_goals = Goal.query.filter_by(user_id=user_id, status='completed').count()
                if completed_goals >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'content_completed':
                from app.models.content import UserContentProgress
                completed_content = UserContentProgress.query.filter_by(user_id=user_id, completed=True).count()
                if completed_content >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'total_records':
                total_records = SmokingRecord.query.filter_by(user_id=user_id).count()
                if total_records >= achievement.criteria_value:
                    earned = True

            if earned:
                # Add achievement
                user_achievement = UserAchievement(user_id=user_id, achievement_id=achievement.id)
                db.session.add(user_achievement)
                
                # ADD NOTIFICATION HERE
                notification = Notification(
                    user_id=user_id,
                    notification_type='achievement_earned',
                    title='New Achievement!',
                    message=f"Congratulations! You earned: {achievement.name}",
                    is_read=False,
                    created_at=datetime.utcnow()
                )
                db.session.add(notification)
                
                print(f"NOTIFICATION: Created notification for achievement: {achievement.name}")
                
                newly_earned.append(achievement.to_dict())

        if newly_earned:
            # SECOND COMMIT - Save achievements and notifications
            db.session.commit()
            print(f"NOTIFICATION: Committed {len(newly_earned)} achievements and notifications")

        return jsonify({
            'message': 'Record created successfully',
            'record': new_record.to_dict(),
            'profile': profile.to_dict(),
            'newly_earned_achievements': newly_earned
        }), 201

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in create_record: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# -------------------- GET ALL RECORDS --------------------
@bp.route('/records/<int:user_id>', methods=['GET'])
def get_records(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)

        query = SmokingRecord.query.filter_by(user_id=user_id).order_by(desc(SmokingRecord.record_date))
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)

        return jsonify({
            'records': [record.to_dict() for record in pagination.items],
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page,
            'per_page': per_page
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# -------------------- GET SPECIFIC RECORD --------------------
@bp.route('/records/<int:record_id>', methods=['GET'])
def get_record(record_id):
    try:
        record = SmokingRecord.query.get(record_id)
        if not record:
            return jsonify({'error': 'Record not found'}), 404

        return jsonify({'record': record.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/records/update/<int:record_id>', methods=['PUT'])
def update_record(record_id):
    try:
        data = request.get_json() or {}
        record = SmokingRecord.query.get(record_id)
        if not record:
            return jsonify({'error': 'Record not found'}), 404

        profile = UserProfile.query.filter_by(user_id=record.user_id).first()
        if not profile:
            profile = UserProfile(user_id=record.user_id)
            db.session.add(profile)

        old_cigarettes = record.cigarettes_smoked or 0
        new_cigarettes = data.get('cigarettes_smoked', old_cigarettes) or 0
        record.cigarettes_smoked = new_cigarettes

        # ---- STREAK UPDATE ----
        if old_cigarettes > 0 and new_cigarettes == 0:
            profile.current_streak_days = (profile.current_streak_days or 0) + 1
            profile.longest_streak_days = max(profile.longest_streak_days or 0, profile.current_streak_days)
        elif old_cigarettes == 0 and new_cigarettes > 0:
            profile.current_streak_days = 0

        cigarettes_per_day = profile.cigarettes_per_day or 0
        old_avoided = max(cigarettes_per_day - old_cigarettes, 0)
        new_avoided = max(cigarettes_per_day - new_cigarettes, 0)

        profile.total_cigarettes_avoided = (
            (profile.total_cigarettes_avoided or 0) - old_avoided + new_avoided
        )

        profile.total_money_saved = (
            (profile.total_money_saved or 0)
            - (old_avoided * CIGARETTE_PRICE)
            + (new_avoided * CIGARETTE_PRICE)
        )

        for field in ['cravings_count', 'mood', 'triggers', 'notes']:
            if field in data:
                setattr(record, field, data[field])

        profile.updated_at = datetime.utcnow()
        
        # FIRST COMMIT - Save record updates
        db.session.commit()

        # -------------------- CHECK ACHIEVEMENTS --------------------
        from app.models.achievement import Achievement, UserAchievement
        all_achievements = Achievement.query.all()
        earned_ids = [id[0] for id in db.session.query(UserAchievement.achievement_id).filter_by(user_id=record.user_id).all()]
        newly_earned = []

        for achievement in all_achievements:
            if achievement.id in earned_ids:
                continue

            earned = False

            if achievement.criteria_type == 'days_smoke_free' and profile:
                if profile.longest_streak_days and profile.longest_streak_days >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'money_saved' and profile:
                if profile.total_money_saved >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'goals_completed':
                from app.models.goal import Goal
                completed_goals = Goal.query.filter_by(user_id=record.user_id, status='completed').count()
                if completed_goals >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'content_completed':
                from app.models.content import UserContentProgress
                completed_content = UserContentProgress.query.filter_by(user_id=record.user_id, completed=True).count()
                if completed_content >= achievement.criteria_value:
                    earned = True

            elif achievement.criteria_type == 'total_records':
                total_records = SmokingRecord.query.filter_by(user_id=record.user_id).count()
                if total_records >= achievement.criteria_value:
                    earned = True

            if earned:
                # Add achievement
                user_achievement = UserAchievement(user_id=record.user_id, achievement_id=achievement.id)
                db.session.add(user_achievement)
                
                # ADD NOTIFICATION HERE
                notification = Notification(
                    user_id=record.user_id,
                    notification_type='achievement_earned',
                    title='New Achievement!',
                    message=f"Congratulations! You earned: {achievement.name}",
                    is_read=False,
                    created_at=datetime.utcnow()
                )
                db.session.add(notification)
                
                print(f"NOTIFICATION: Created notification for achievement: {achievement.name}")
                
                newly_earned.append(achievement.to_dict())

        if newly_earned:
            # SECOND COMMIT - Save achievements and notifications
            db.session.commit()
            print(f"NOTIFICATION: Committed {len(newly_earned)} achievements and notifications")

        return jsonify({
            'message': 'Record updated successfully',
            'record': record.to_dict(),
            'profile': profile.to_dict(),
            'newly_earned_achievements': newly_earned
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"ERROR in update_record: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


# -------------------- DELETE RECORD --------------------
@bp.route('/records/delete/<int:record_id>', methods=['DELETE'])
def delete_record(record_id):
    try:
        record = SmokingRecord.query.get(record_id)
        if not record:
            return jsonify({'error': 'Record not found'}), 404

        db.session.delete(record)
        db.session.commit()
        return jsonify({'message': 'Record deleted successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# -------------------- GET STATISTICS --------------------
@bp.route('/statistics/<int:user_id>', methods=['GET'])
def get_statistics(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        days = request.args.get('days', 30, type=int)
        start_date = datetime.utcnow().date() - timedelta(days=days)

        records = SmokingRecord.query.filter(
            SmokingRecord.user_id == user_id,
            SmokingRecord.record_date >= start_date
        ).order_by(SmokingRecord.record_date).all()

        profile = UserProfile.query.filter_by(user_id=user_id).first()

        if not records:
            return jsonify({
                'statistics': {
                    'total_records': 0,
                    'total_cigarettes': 0,
                    'average_per_day': 0,
                    'total_cravings': 0,
                    'smoke_free_days': 0,
                    'most_common_mood': None,
                    'most_common_trigger': None,
                    'total_money_saved': float(profile.total_money_saved or 0) if profile else 0,
                    'total_cigarettes_avoided': profile.total_cigarettes_avoided or 0 if profile else 0
                },
                'daily_data': []
            }), 200

        total_cigarettes = sum(r.cigarettes_smoked for r in records)
        total_cravings = sum(r.cravings_count for r in records)
        smoke_free_days = sum(1 for r in records if r.cigarettes_smoked == 0)

        moods = [r.mood for r in records if r.mood]
        most_common_mood = max(set(moods), key=moods.count) if moods else None

        all_triggers = [t.strip() for r in records if r.triggers for t in r.triggers.split(',')]
        most_common_trigger = max(set(all_triggers), key=all_triggers.count) if all_triggers else None

        daily_data = [
            {
                'date': r.record_date.isoformat(),
                'cigarettes': r.cigarettes_smoked,
                'cravings': r.cravings_count,
                'mood': r.mood
            } for r in records
        ]

        return jsonify({
            'statistics': {
                'total_records': len(records),
                'total_cigarettes': total_cigarettes,
                'average_per_day': round(total_cigarettes / len(records), 2),
                'total_cravings': total_cravings,
                'smoke_free_days': smoke_free_days,
                'most_common_mood': most_common_mood,
                'most_common_trigger': most_common_trigger,
                'days_analyzed': days,
                'total_money_saved': float(profile.total_money_saved or 0),
                'total_cigarettes_avoided': profile.total_cigarettes_avoided or 0
            },
            'daily_data': daily_data
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# -------------------- GET TRENDS --------------------
@bp.route('/trends/<int:user_id>', methods=['GET'])
def get_trends(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        thirty_days_ago = datetime.utcnow().date() - timedelta(days=30)
        records = SmokingRecord.query.filter(
            SmokingRecord.user_id == user_id,
            SmokingRecord.record_date >= thirty_days_ago
        ).order_by(SmokingRecord.record_date).all()

        if len(records) < 2:
            return jsonify({'trend': 'insufficient_data'}), 200

        weeks = []
        current_week = []
        week_start = records[0].record_date

        for record in records:
            if (record.record_date - week_start).days >= 7:
                weeks.append(sum(r.cigarettes_smoked for r in current_week) / len(current_week))
                current_week = [record]
                week_start = record.record_date
            else:
                current_week.append(record)

        if current_week:
            weeks.append(sum(r.cigarettes_smoked for r in current_week) / len(current_week))

        trend = 'stable'
        change = 0
        if len(weeks) >= 2:
            if weeks[-1] < weeks[0]:
                trend = 'improving'
                change = round(((weeks[0] - weeks[-1]) / weeks[0]) * 100, 1)
            elif weeks[-1] > weeks[0]:
                trend = 'worsening'
                change = round(((weeks[-1] - weeks[0]) / weeks[0]) * 100, 1)

        return jsonify({
            'trend': trend,
            'change_percentage': change,
            'weekly_averages': [round(w, 1) for w in weeks],
            'total_weeks_analyzed': len(weeks)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# -------------------- TODAY'S RECORD --------------------
@bp.route('/today/<int:user_id>', methods=['GET'])
def get_today_record(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        today = datetime.utcnow().date()
        record = SmokingRecord.query.filter_by(
            user_id=user_id, record_date=today
        ).first()

        if record:
            return jsonify({'has_record': True, 'record': record.to_dict()}), 200
        else:
            return jsonify({'has_record': False}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
