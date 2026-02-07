# 💾 Chat History Database Integration

## ✅ What's Done

Your Flask backend already has:
- ✅ PostgreSQL database running
- ✅ `chat_sessions` table for conversations
- ✅ `chat_messages` table for messages
- ✅ Routes at `/chat/session` and `/chat/message`

## 🔧 What I Just Updated

### 1. Flask Backend (`app/routes/chat.py`)
**Lines 177-180 replaced** - Now calls your RAG API instead of placeholder:
```python
# Calls: https://shawana-knurly-merrill.ngrok-free.dev/query
# Saves: User message + AI response to database automatically
# Stores: RAG metadata (intent, confidence, sources) in message_metadata column
```

### 2. Flutter App
**Created:** `chat_backend_service.dart` - New service to call Flask backend
**Updated:** `chat_page.dart` - Now uses backend instead of direct ngrok

## 🚀 How It Works Now

```
User Message
    ↓
Flutter App (chat_page.dart)
    ↓
Flask Backend (localhost:5000/chat/message)
    ↓
RAG API (ngrok/query) ← Your Kaggle notebook
    ↓
PostgreSQL Database ← Messages saved here!
    ↓
Response back to Flutter
```

## 📝 Configuration

### Flask Backend
**File:** `app/routes/chat.py` (Line 13)
```python
RAG_API_URL = 'https://shawana-knurly-merrill.ngrok-free.dev/query'
```
**Update this** when your ngrok URL changes! Or set environment variable:
```bash
$env:RAG_API_URL = "https://your-new-ngrok-url.ngrok-free.dev/query"
```

### Flutter App
**File:** `lib/core/network/url_data.dart`
```dart
const BASE_URL = "http://10.54.58.29:5000";  // Your Flask backend
```

## 🧪 Testing

### 1. Check Database Tables
```bash
cd D:\downloads\2026\nlp_app\nlp_app\backend
python -m sai_backend.test_db_connection
```

### 2. Test Backend API
```powershell
# Test session creation
Invoke-WebRequest -Uri "http://10.54.58.29:5000/chat/session" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"user_id": 1, "session_title": "Test Chat"}'

# Test sending message (replace session_id)
Invoke-WebRequest -Uri "http://10.54.58.29:5000/chat/message" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"session_id": 1, "message": "كيفاش نقلع على التدخين؟"}'
```

### 3. Test Flutter App
1. **Restart Flutter app** (hot reload won't pick up new service)
2. **Send a message** in chat
3. **Check logs** - should see session creation and message saving

## 📊 Database Schema

### chat_sessions
```sql
id, user_id, session_title, started_at, last_message_at, 
is_active, message_count
```

### chat_messages
```sql
id, session_id, sender_type ('user' or 'assistant'), 
message_text, message_metadata (JSON with RAG info),
sentiment_score, flagged, created_at
```

## 🔍 View Chat History

### From Python:
```python
from app.models.chat import ChatSession, ChatMessage

# Get user's sessions
sessions = ChatSession.query.filter_by(user_id=1).all()

# Get messages in a session
messages = ChatMessage.query.filter_by(session_id=1).order_by(ChatMessage.created_at).all()
for msg in messages:
    print(f"{msg.sender_type}: {msg.message_text}")
```

### From Flutter (already implemented):
```dart
final service = ChatBackendService();

// Get all user sessions
final sessions = await service.getSessions(userId);

// Get messages in a session
final data = await service.getMessages(sessionId);
final messages = data['messages'];
```

## 🎯 Key Features

✅ **Auto-saves** - Every message saved to database
✅ **Session management** - Conversations grouped by session
✅ **RAG metadata** - Intent, confidence, sources stored
✅ **Fallback** - If RAG API fails, uses placeholder response
✅ **Error handling** - Graceful handling of network issues
✅ **Pagination** - Message history supports pagination

## 🐛 Troubleshooting

**Problem:** "Failed to create session"
- **Check:** Flask backend is running (`python run.py`)
- **Check:** PostgreSQL is running
- **Check:** `url_data.dart` has correct backend URL

**Problem:** "RAG API returned non-200"
- **Check:** ngrok URL in `chat.py` line 13
- **Check:** Kaggle notebook Cell 22 is running
- **Update:** Run Cell 22, get new ngrok URL, update Flask

**Problem:** Messages not saving
- **Check:** Database connection in Flask logs
- **Check:** No errors in Flask terminal
- **Query:** `SELECT * FROM chat_messages ORDER BY created_at DESC LIMIT 10;`

## 🔄 When Ngrok URL Changes

1. **Stop Cell 22** in Kaggle
2. **Re-run Cell 22** - Get new ngrok URL
3. **Update Flask:** `app/routes/chat.py` line 13
4. **Restart Flask backend**
5. **Test:** Send message from Flutter

No need to update Flutter - it talks to Flask, Flask talks to ngrok!

## 📱 User ID Management

**Current:** Hardcoded `userId = 1` in `chat_page.dart` line 20

**Production:** Get from authentication/shared preferences:
```dart
// Add to chat_page.dart
final prefs = await SharedPreferences.getInstance();
final userId = prefs.getInt('user_id') ?? 1;
```

## 🎉 What You Get

- ✅ Full chat history saved per user
- ✅ Multiple conversation sessions
- ✅ RAG responses with metadata tracking
- ✅ Message statistics and analytics
- ✅ Session management (create, list, delete)
- ✅ Proper error handling and fallbacks
