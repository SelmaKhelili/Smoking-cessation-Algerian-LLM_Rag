from app.extensions import db
from app.models.achievement import Achievement

def seed_achievements():
    achievements = [
        # ===== Beginner =====
        {
            "name": "One Smoke-Free Day",
            "description": "Stay smoke-free for one full day",
            "icon_url": "assets/icons/one_day.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 1,
            "points": 10
        },
        {
            "name": "Two Smoke-Free Days",
            "description": "Stay smoke-free for two days",
            "icon_url": "assets/icons/two_days.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 2,
            "points": 15
        },
        {
            "name": "Three Day Fighter",
            "description": "Stay smoke-free for three days",
            "icon_url": "assets/icons/three_days.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 3,
            "points": 20
        },
        {
            "name": "Daily Check Pro",
            "description": "Complete daily check-ins consistently",
            "icon_url": "assets/icons/check_pro.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 3,
            "points": 20
        },
        {
            "name": "Four Smoke-Free Days",
            "description": "Stay smoke-free for four days",
            "icon_url": "assets/icons/four_days.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 4,
            "points": 25
        },
        {
            "name": "Five Days Fighter",
            "description": "Stay smoke-free for five days",
            "icon_url": "assets/icons/five_days.png",
            "badge_type": "beginner",
            "criteria_type": "days_smoke_free",
            "criteria_value": 5,
            "points": 30
        },

        # ===== Intermediate =====
        {
            "name": "One Week Warrior",
            "description": "Stay smoke-free for one week",
            "icon_url": "assets/icons/one_week.png",
            "badge_type": "intermediate",
            "criteria_type": "days_smoke_free",
            "criteria_value": 7,
            "points": 50
        },
        {
            "name": "Calm Night",
            "description": "Reach 10 smoke-free days",
            "icon_url": "assets/icons/calm_night.png",
            "badge_type": "intermediate",
            "criteria_type": "days_smoke_free",
            "criteria_value": 10,
            "points": 60
        },
        {
            "name": "Two Weeks Champion",
            "description": "Stay smoke-free for two weeks",
            "icon_url": "assets/icons/two_weeks.png",
            "badge_type": "intermediate",
            "criteria_type": "days_smoke_free",
            "criteria_value": 14,
            "points": 80
        },
        {
            "name": "Good Listener",
            "description": "Reach 18 smoke-free days",
            "icon_url": "assets/icons/listener.png",
            "badge_type": "intermediate",
            "criteria_type": "days_smoke_free",
            "criteria_value": 18,
            "points": 90
        },
        {
            "name": "Three Weeks Clear",
            "description": "Stay smoke-free for three weeks",
            "icon_url": "assets/icons/three_weeks.png",
            "badge_type": "intermediate",
            "criteria_type": "days_smoke_free",
            "criteria_value": 21,
            "points": 100
        },

        # ===== Advanced =====
        {
            "name": "One Month Milestone",
            "description": "Stay smoke-free for one month",
            "icon_url": "assets/icons/one_month.png",
            "badge_type": "advanced",
            "criteria_type": "days_smoke_free",
            "criteria_value": 30,
            "points": 150
        },
        {
            "name": "Two Months Strong",
            "description": "Stay smoke-free for two months",
            "icon_url": "assets/icons/two_months.png",
            "badge_type": "advanced",
            "criteria_type": "days_smoke_free",
            "criteria_value": 60,
            "points": 200
        },
        {
            "name": "Stress Master",
            "description": "Reach 75 smoke-free days",
            "icon_url": "assets/icons/stress_master.png",
            "badge_type": "advanced",
            "criteria_type": "days_smoke_free",
            "criteria_value": 75,
            "points": 250
        },
        {
            "name": "Three Months Champion",
            "description": "Stay smoke-free for three months",
            "icon_url": "assets/icons/three_months.png",
            "badge_type": "advanced",
            "criteria_type": "days_smoke_free",
            "criteria_value": 90,
            "points": 300
        },
        {
            "name": "Almost Free",
            "description": "Reach 120 smoke-free days",
            "icon_url": "assets/icons/almost_free.png",
            "badge_type": "advanced",
            "criteria_type": "days_smoke_free",
            "criteria_value": 120,
            "points": 400
        },
    ]

    for data in achievements:
        exists = Achievement.query.filter_by(
            name=data["name"]
        ).first()

        if not exists:
            db.session.add(Achievement(**data))

    db.session.commit()
    print("✅ Achievements seeded successfully")
