# Firebase Data Structure

## Collections Overview

### 1. Users Collection (`/users/{userId}`)
```json
{
  "uid": "string",
  "email": "string",
  "phoneNumber": "string",
  "displayName": "string",
  "profileImageUrl": "string",
  "role": "user|admin|master_admin",
  "isActive": true,
  "preferences": {
    "darkMode": false,
    "notifications": true,
    "language": "en"
  },
  "stats": {
    "totalQuizzes": 0,
    "totalScore": 0,
    "averageScore": 0,
    "currentStreak": 0,
    "longestStreak": 0,
    "totalTimeSpent": 0
  },
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 2. Questions Collection (`/questions/{questionId}`)
```json
{
  "id": "string",
  "question": "string",
  "options": [
    {
      "id": "A",
      "text": "string",
      "isCorrect": false
    },
    {
      "id": "B", 
      "text": "string",
      "isCorrect": true
    },
    {
      "id": "C",
      "text": "string", 
      "isCorrect": false
    },
    {
      "id": "D",
      "text": "string",
      "isCorrect": false
    }
  ],
  "correctAnswer": "B",
  "explanation": "string",
  "category": "string",
  "subCategory": "string",
  "examPattern": "MTS|POSTMAN|POSTAL_ASSISTANT|IPO|GROUP_B",
  "difficulty": "easy|medium|hard",
  "tags": ["tag1", "tag2"],
  "imageUrl": "string",
  "timeLimit": 60,
  "isActive": true,
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "stats": {
    "totalAttempts": 0,
    "correctAttempts": 0,
    "averageTime": 0
  }
}
```

### 3. Categories Collection (`/categories/{categoryId}`)
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "iconUrl": "string",
  "bannerUrl": "string",
  "color": "#6366F1",
  "isActive": true,
  "order": 1,
  "subCategories": [
    {
      "id": "string",
      "name": "string",
      "description": "string"
    }
  ],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4. Quiz Sessions Collection (`/quiz_sessions/{sessionId}`)
```json
{
  "id": "string",
  "userId": "string",
  "category": "string",
  "examPattern": "string",
  "questionIds": ["questionId1", "questionId2"],
  "totalQuestions": 10,
  "timeLimit": 600,
  "isTimedQuiz": true,
  "status": "started|paused|completed|abandoned",
  "currentQuestionIndex": 0,
  "answers": {
    "questionId1": {
      "selectedOption": "A",
      "timeSpent": 45,
      "isCorrect": true,
      "answeredAt": "timestamp"
    }
  },
  "startedAt": "timestamp",
  "completedAt": "timestamp",
  "pausedAt": "timestamp",
  "totalTimeSpent": 0,
  "securityEvents": [
    {
      "type": "screenshot_attempt|app_switch|screen_lock",
      "timestamp": "timestamp",
      "details": "string"
    }
  ]
}
```

### 5. Quiz Results Collection (`/quiz_results/{resultId}`)
```json
{
  "id": "string",
  "userId": "string",
  "sessionId": "string",
  "category": "string",
  "examPattern": "string",
  "totalQuestions": 10,
  "correctAnswers": 8,
  "wrongAnswers": 2,
  "score": 80,
  "percentage": 80.0,
  "timeSpent": 480,
  "averageTimePerQuestion": 48,
  "difficulty": "medium",
  "questionAnalysis": [
    {
      "questionId": "string",
      "isCorrect": true,
      "timeSpent": 45,
      "selectedOption": "A",
      "correctOption": "A"
    }
  ],
  "strengths": ["category1", "category2"],
  "weaknesses": ["category3"],
  "completedAt": "timestamp",
  "rank": 15,
  "totalParticipants": 100
}
```

### 6. Leaderboard Collection (`/leaderboard/{leaderboardId}`)
```json
{
  "id": "string",
  "userId": "string",
  "userName": "string",
  "profileImageUrl": "string",
  "category": "string",
  "examPattern": "string",
  "totalScore": 850,
  "totalQuizzes": 12,
  "averageScore": 70.8,
  "rank": 5,
  "badges": ["streak_master", "speed_demon"],
  "lastUpdated": "timestamp",
  "period": "daily|weekly|monthly|all_time"
}
```

### 7. Daily Challenges Collection (`/daily_challenges/{challengeId}`)
```json
{
  "id": "string",
  "date": "2024-01-15",
  "title": "Daily Challenge - General Knowledge",
  "description": "Test your knowledge with today's challenge",
  "questionIds": ["q1", "q2", "q3", "q4", "q5"],
  "category": "general_knowledge",
  "difficulty": "medium",
  "timeLimit": 300,
  "isActive": true,
  "participants": 150,
  "createdAt": "timestamp",
  "expiresAt": "timestamp"
}
```

### 8. User Bookmarks Collection (`/user_bookmarks/{userId}`)
```json
{
  "userId": "string",
  "bookmarkedQuestions": [
    {
      "questionId": "string",
      "category": "string",
      "difficulty": "string",
      "bookmarkedAt": "timestamp",
      "notes": "string"
    }
  ],
  "updatedAt": "timestamp"
}
```

### 9. Analytics Collection (`/analytics/{analyticsId}`)
```json
{
  "id": "string",
  "type": "daily|weekly|monthly",
  "date": "2024-01-15",
  "metrics": {
    "totalUsers": 1250,
    "activeUsers": 890,
    "newUsers": 45,
    "totalQuizzes": 3400,
    "averageScore": 72.5,
    "popularCategories": [
      {
        "category": "general_knowledge",
        "attempts": 1200
      }
    ],
    "questionPerformance": [
      {
        "questionId": "string",
        "attempts": 150,
        "correctRate": 0.65
      }
    ]
  },
  "createdAt": "timestamp"
}
```

### 10. App Settings Collection (`/app_settings/{settingId}`)
```json
{
  "id": "string",
  "key": "string",
  "value": "any",
  "description": "string",
  "isPublic": false,
  "updatedBy": "userId",
  "updatedAt": "timestamp"
}
```

## Security Rules Summary

- **Users**: Read/write own data, admins can read all
- **Questions**: Read for all authenticated users, write for admins only
- **Categories**: Read for all, write for admins only
- **Quiz Sessions**: Read/write own sessions, admins can read all
- **Quiz Results**: Read/write own results, admins can read all
- **Analytics**: Admin access only
- **Leaderboard**: Read for all, write for admins only
- **Daily Challenges**: Read for all, write for admins only
- **User Bookmarks**: Read/write own bookmarks only
- **App Settings**: Read for all, write for admins only

## Indexes

Composite indexes are created for:
- Questions by category, difficulty, and creation date
- Questions by exam pattern, active status, and creation date
- Quiz sessions by user and start date
- Quiz results by user, score, and completion date
- Leaderboard by category and total score
- Users by role, active status, and last login
