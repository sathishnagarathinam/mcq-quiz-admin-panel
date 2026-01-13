# MCQ Quiz System - API Documentation

This document describes the API endpoints and data structures for the MCQ Quiz System.

## Base URL
```
Production: https://api.mcqquiz.com
Development: http://localhost:5001
```

## Authentication

All API requests require authentication using Firebase Auth tokens.

### Headers
```
Authorization: Bearer <firebase_auth_token>
Content-Type: application/json
```

## User Management

### Get Current User
```http
GET /api/users/me
```

**Response:**
```json
{
  "uid": "string",
  "email": "string",
  "phoneNumber": "string",
  "displayName": "string",
  "role": "user|admin|master_admin",
  "stats": {
    "totalQuizzes": 0,
    "totalScore": 0,
    "averageScore": 0
  }
}
```

### Update User Profile
```http
PUT /api/users/me
```

**Request Body:**
```json
{
  "displayName": "string",
  "preferences": {
    "darkMode": false,
    "notifications": true
  }
}
```

### Get All Users (Admin Only)
```http
GET /api/users?page=1&limit=20&role=user
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)
- `role`: Filter by role (optional)
- `search`: Search by name or email (optional)

## Question Management

### Get Questions
```http
GET /api/questions?category=general&difficulty=medium&page=1&limit=20
```

**Query Parameters:**
- `category`: Filter by category
- `difficulty`: easy|medium|hard
- `examPattern`: MTS|POSTMAN|POSTAL_ASSISTANT|IPO|GROUP_B
- `page`: Page number
- `limit`: Items per page
- `search`: Search in question text

**Response:**
```json
{
  "questions": [
    {
      "id": "string",
      "question": "string",
      "options": [
        {
          "id": "A",
          "text": "string",
          "isCorrect": false
        }
      ],
      "correctAnswer": "A",
      "explanation": "string",
      "category": "string",
      "difficulty": "medium",
      "examPattern": "MTS",
      "tags": ["tag1"],
      "stats": {
        "totalAttempts": 100,
        "correctAttempts": 75
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 500,
    "totalPages": 25
  }
}
```

### Create Question (Admin Only)
```http
POST /api/questions
```

**Request Body:**
```json
{
  "question": "string",
  "options": [
    {
      "id": "A",
      "text": "string",
      "isCorrect": false
    }
  ],
  "explanation": "string",
  "category": "string",
  "difficulty": "medium",
  "examPattern": "MTS",
  "tags": ["tag1"],
  "timeLimit": 60
}
```

### Update Question (Admin Only)
```http
PUT /api/questions/{questionId}
```

### Delete Question (Admin Only)
```http
DELETE /api/questions/{questionId}
```

### Bulk Upload Questions (Admin Only)
```http
POST /api/questions/bulk-upload
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: CSV or Excel file
- `category`: Default category
- `examPattern`: Default exam pattern

## Category Management

### Get Categories
```http
GET /api/categories
```

**Response:**
```json
{
  "categories": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "iconUrl": "string",
      "color": "#6366F1",
      "questionCount": 150,
      "isActive": true
    }
  ]
}
```

### Create Category (Admin Only)
```http
POST /api/categories
```

**Request Body:**
```json
{
  "name": "string",
  "description": "string",
  "color": "#6366F1",
  "iconUrl": "string"
}
```

## Quiz Management

### Start Quiz Session
```http
POST /api/quiz-sessions
```

**Request Body:**
```json
{
  "category": "string",
  "examPattern": "MTS",
  "difficulty": "medium",
  "questionCount": 10,
  "timeLimit": 600,
  "isTimedQuiz": true
}
```

**Response:**
```json
{
  "sessionId": "string",
  "questions": [
    {
      "id": "string",
      "question": "string",
      "options": [
        {
          "id": "A",
          "text": "string"
        }
      ],
      "timeLimit": 60
    }
  ],
  "totalQuestions": 10,
  "timeLimit": 600
}
```

### Submit Answer
```http
POST /api/quiz-sessions/{sessionId}/answers
```

**Request Body:**
```json
{
  "questionId": "string",
  "selectedOption": "A",
  "timeSpent": 45
}
```

### Complete Quiz
```http
POST /api/quiz-sessions/{sessionId}/complete
```

**Response:**
```json
{
  "resultId": "string",
  "score": 80,
  "percentage": 80.0,
  "correctAnswers": 8,
  "wrongAnswers": 2,
  "timeSpent": 480,
  "rank": 15,
  "totalParticipants": 100,
  "questionAnalysis": [
    {
      "questionId": "string",
      "isCorrect": true,
      "timeSpent": 45,
      "selectedOption": "A",
      "correctOption": "A"
    }
  ]
}
```

## Analytics

### Get Dashboard Stats (Admin Only)
```http
GET /api/analytics/dashboard
```

**Response:**
```json
{
  "totalUsers": 1234,
  "totalQuestions": 5678,
  "totalQuizzes": 12345,
  "averageScore": 78.5,
  "userGrowth": [
    {
      "date": "2024-01-01",
      "count": 100
    }
  ],
  "categoryStats": [
    {
      "category": "General Knowledge",
      "attempts": 1200,
      "averageScore": 75.5
    }
  ]
}
```

### Get User Performance
```http
GET /api/analytics/users/{userId}/performance
```

**Response:**
```json
{
  "totalQuizzes": 25,
  "averageScore": 78.5,
  "bestScore": 95,
  "currentStreak": 5,
  "categoryPerformance": [
    {
      "category": "General Knowledge",
      "averageScore": 80,
      "totalQuizzes": 10
    }
  ],
  "progressOverTime": [
    {
      "date": "2024-01-01",
      "score": 75
    }
  ]
}
```

### Export Analytics (Admin Only)
```http
GET /api/analytics/export?format=csv&startDate=2024-01-01&endDate=2024-01-31
```

**Query Parameters:**
- `format`: csv|excel|pdf
- `startDate`: Start date (YYYY-MM-DD)
- `endDate`: End date (YYYY-MM-DD)
- `category`: Filter by category (optional)

## Leaderboard

### Get Leaderboard
```http
GET /api/leaderboard?period=weekly&category=general&limit=50
```

**Query Parameters:**
- `period`: daily|weekly|monthly|all_time
- `category`: Filter by category (optional)
- `limit`: Number of results (default: 50)

**Response:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "string",
      "userName": "string",
      "profileImageUrl": "string",
      "totalScore": 850,
      "totalQuizzes": 12,
      "averageScore": 70.8
    }
  ],
  "userRank": {
    "rank": 25,
    "totalScore": 650
  }
}
```

## Daily Challenges

### Get Today's Challenge
```http
GET /api/daily-challenges/today
```

**Response:**
```json
{
  "id": "string",
  "title": "Daily Challenge - General Knowledge",
  "description": "string",
  "questionIds": ["q1", "q2", "q3"],
  "timeLimit": 300,
  "participants": 150,
  "userParticipated": false
}
```

### Participate in Challenge
```http
POST /api/daily-challenges/{challengeId}/participate
```

## Bookmarks

### Get User Bookmarks
```http
GET /api/bookmarks
```

### Add Bookmark
```http
POST /api/bookmarks
```

**Request Body:**
```json
{
  "questionId": "string",
  "notes": "string"
}
```

### Remove Bookmark
```http
DELETE /api/bookmarks/{questionId}
```

## Error Responses

All endpoints return errors in the following format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  }
}
```

### Error Codes
- `VALIDATION_ERROR`: Request validation failed
- `UNAUTHORIZED`: Authentication required
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error

## Rate Limiting

API requests are rate limited:
- Authenticated users: 1000 requests per hour
- Admin users: 5000 requests per hour
- Quiz submissions: 100 per hour per user

## Webhooks

### Quiz Completion Webhook
```http
POST /webhooks/quiz-completed
```

**Payload:**
```json
{
  "event": "quiz.completed",
  "userId": "string",
  "sessionId": "string",
  "score": 80,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## SDK Examples

### JavaScript/TypeScript
```typescript
import { MCQQuizAPI } from '@mcqquiz/api-client';

const api = new MCQQuizAPI({
  baseURL: 'https://api.mcqquiz.com',
  authToken: 'your_firebase_token'
});

// Get questions
const questions = await api.questions.list({
  category: 'general',
  difficulty: 'medium'
});

// Start quiz
const session = await api.quizSessions.create({
  category: 'general',
  questionCount: 10
});
```

### Flutter/Dart
```dart
import 'package:mcq_quiz_api/mcq_quiz_api.dart';

final api = MCQQuizAPI(
  baseUrl: 'https://api.mcqquiz.com',
  authToken: 'your_firebase_token',
);

// Get questions
final questions = await api.questions.list(
  category: 'general',
  difficulty: Difficulty.medium,
);

// Start quiz
final session = await api.quizSessions.create(
  category: 'general',
  questionCount: 10,
);
```
