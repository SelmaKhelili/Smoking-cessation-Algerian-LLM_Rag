# app/check_goals.py
from datetime import date
from app.extensions import db
from app.models.goal import Goal
from app.models.notification import Notification

def check_goals_on_startup():
    """Check for due goals when app starts and send notifications"""
    print("🔍 Checking for due goals on app startup...")
    
    try:
        today = date.today()
        
        # Find goals that are due today and not notified yet
        goals = Goal.query.filter(
            Goal.target_date == today,
            Goal.notification_sent == False
        ).all()
        
        if not goals:
            print("✅ No due goals found today.")
            return
        
        print(f"📅 Found {len(goals)} goal(s) due today.")
        
        for goal in goals:
            # Create notification
            notification = Notification(
                user_id=goal.user_id,
                notification_type='goal_reminder',
                title='Goal Deadline Today!',
                message=f'Today is the deadline for your goal: {goal.goal_type.replace("_", " ").title()}'
            )
            db.session.add(notification)
            
            # Mark as notified
            goal.notification_sent = True
            print(f"   ✓ Sent notification for goal: {goal.goal_type} (User {goal.user_id})")
        
        # Save everything to database
        db.session.commit()
        print(f"✅ Successfully sent {len(goals)} notification(s).")
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Error checking goals: {str(e)}")