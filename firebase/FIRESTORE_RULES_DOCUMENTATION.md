# Firebase Firestore Security Rules Documentation

## Overview
This document explains the Firebase security rules for the MCQ Quiz Flutter app, specifically focusing on exam data access and security.

## Collections and Access Patterns

### 1. Exams Collection (`/exams/{examId}`)

**Purpose**: Main collection storing exam/quiz data with questions, metadata, and configuration.

**Data Structure**:
```javascript
{
  id: "exam_id",
  name: "Exam Name",
  examType: "Postal guide" | "Postal Volumes" | "Custom",
  customName: "Custom Exam Name (optional)",
  numberOfQuestions: 50,
  timeLimit: 60, // minutes
  suitableFor: ["MTS", "Postman", "PA", "IP", "Group B"],
  questions: [
    {
      id: "question_id",
      question: "Question text",
      options: ["Option 1", "Option 2", "Option 3", "Option 4"],
      correctAnswer: 0, // index of correct option
      explanation: "Explanation text (optional)"
    }
  ],
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Access Rules**:
- **Read (Active Exams)**: All authenticated users can read exams where `isActive == true`
- **Read (Inactive Exams)**: Only admin users (mobile app admins or web admin users)
- **Create/Update**: Mobile app admin users or web admin users
- **Delete**: Only web admin users

### 2. Exam Results Collection (`/exam_results/{resultId}`)

**Purpose**: Stores individual exam attempt results and scores.

**Access Rules**:
- **Read/Write**: Users can only access their own results (`userId == request.auth.uid`)
- **Read (All)**: Admin users can read all results for analytics

### 3. User Progress Collection (`/user_progress/{userId}`)

**Purpose**: Tracks user progress, streaks, and performance metrics.

**Access Rules**:
- **Read/Write**: Users can only access their own progress
- **Read (All)**: Admin users can read all progress for analytics

### 4. Exam Statistics Collection (`/exam_stats/{statId}`)

**Purpose**: Cached aggregated statistics for performance optimization.

**Access Rules**:
- **Read**: All authenticated users
- **Write**: Only admin users

## Security Features

### 1. Authentication Requirements
- All rules require `request.auth != null` (user must be authenticated)
- No anonymous access allowed

### 2. Role-Based Access Control

**Mobile App Users** (`/users/{userId}`):
- Regular users: Can read active exams, manage their own results/progress
- Admin users (`role: 'admin'` or `'master_admin'`): Can create/update exams and read all data

**Web Admin Users** (`/admin_users/{userId}`):
- Must have `isActive: true` status
- Can create/update/delete exams
- Can read all user data for analytics

### 3. Data Visibility Controls
- **Active Exams**: Visible to all authenticated users
- **Inactive Exams**: Only visible to admin users
- **User Data**: Users can only see their own data (except admins)

### 4. Write Permissions
- **Exam Creation**: Only admin users
- **Exam Updates**: Only admin users
- **Exam Deletion**: Only web admin users
- **User Results**: Users can only write their own results

## Flutter App Integration

### Required Authentication
Your Flutter app should ensure users are authenticated before accessing exam data:

```dart
// Check authentication before fetching exams
if (FirebaseAuth.instance.currentUser != null) {
  final exams = await ExamService.getActiveExams();
}
```

### Error Handling
Handle permission errors gracefully:

```dart
try {
  final exams = await ExamService.getActiveExams();
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    // Handle permission denied - user not authenticated or not authorized
    // Redirect to login or show appropriate message
  }
}
```

### Offline Support
Firebase rules work with offline persistence:

```dart
// Enable offline persistence (usually in main.dart)
await FirebaseFirestore.instance.enablePersistence();
```

## Best Practices

### 1. Minimize Data Exposure
- Only fetch active exams for regular users
- Use field-level security where needed
- Implement pagination for large datasets

### 2. Efficient Queries
- Use compound queries with proper indexing
- Filter by `isActive` field first
- Order by `createdAt` for recent exams

### 3. Real-time Updates
- Use streams for real-time exam updates
- Handle connection state changes
- Implement proper error handling

### 4. Testing Rules
Test your rules using Firebase Emulator:

```bash
firebase emulators:start --only firestore
```

## Common Query Patterns

### 1. Get Active Exams
```dart
FirebaseFirestore.instance
  .collection('exams')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get()
```

### 2. Get Exams for Specific Role
```dart
FirebaseFirestore.instance
  .collection('exams')
  .where('isActive', isEqualTo: true)
  .where('suitableFor', arrayContains: 'MTS')
  .get()
```

### 3. Get Featured Exams (Recent)
```dart
FirebaseFirestore.instance
  .collection('exams')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .limit(5)
  .get()
```

## Security Considerations

### 1. Sensitive Data
- Never store answer keys in client-accessible fields
- Consider server-side validation for critical operations
- Use Cloud Functions for sensitive operations

### 2. Rate Limiting
- Implement client-side rate limiting
- Use Firebase App Check for additional security
- Monitor usage patterns

### 3. Data Validation
- Validate data structure on write operations
- Use custom claims for additional role information
- Implement proper input sanitization

## Deployment

Deploy rules using Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

Test rules before deployment:

```bash
firebase emulators:start --only firestore
```
