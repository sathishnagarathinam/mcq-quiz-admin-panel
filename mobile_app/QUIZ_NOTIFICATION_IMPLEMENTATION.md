# 🎯 Quiz Notification Implementation Guide

## ✅ IMPLEMENTATION COMPLETED

The app now supports complete quiz notification flow with proper navigation and payment handling.

## 🔗 How It Works

### 1. **Notification Flow**
1. User receives notification with quiz link
2. User taps notification → navigates to quiz instructions
3. Quiz instructions show:
   - **Free Quiz**: "Start Quiz" button (green)
   - **Paid Quiz (not purchased)**: "Start Payment" button (orange)
   - **Paid Quiz (purchased)**: "Start Quiz" button (green)

### 2. **FCM Message Structure for Quiz Notifications**

```json
{
  "notification": {
    "title": "🎯 New SSC CGL Quiz Available!",
    "body": "50 questions • 60 minutes • Quantitative Aptitude"
  },
  "data": {
    "actionType": "quiz",
    "actionUrl": "/quiz/ssc_cgl_quant_2024/instructions",
    "quizId": "ssc_cgl_quant_2024",
    "category": "quiz_update",
    "priority": "high",
    "examType": "SSC CGL",
    "subject": "Quantitative Aptitude",
    "numberOfQuestions": "50",
    "timeLimit": "60"
  },
  "topic": "ssc_students"
}
```

### 3. **Key Data Fields**

| Key | Value | Required | Description |
|-----|-------|----------|-------------|
| `actionType` | `"quiz"` | ✅ | Identifies quiz notification |
| `actionUrl` | `/quiz/{quizId}/instructions` | ✅ | Quiz instructions page URL |
| `quizId` | `"actual_quiz_id"` | ✅ | Specific quiz document ID |
| `category` | `"quiz_update"` | ✅ | Notification category |
| `priority` | `"high"` | ❌ | Notification priority |

## 🚀 Sending Quiz Notifications

### Method 1: Using Cloud Functions API

```javascript
const response = await fetch(`${functionsUrl}/notifications/send-to-topic`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    topic: 'quiz_updates',
    notification: {
      title: "🎯 Banking Quiz Available!",
      body: "New IBPS PO quiz with latest pattern"
    },
    data: {
      "actionType": "quiz",
      "actionUrl": "/quiz/ibps_po_2024/instructions",
      "quizId": "ibps_po_2024",
      "category": "quiz_update",
      "examType": "IBPS PO",
      "numberOfQuestions": "100",
      "timeLimit": "120"
    }
  }),
});
```

### Method 2: Using Firebase Admin SDK

```javascript
const message = {
  notification: {
    title: "📚 Post Office Quiz Ready!",
    body: "50 questions • 60 minutes • General Knowledge"
  },
  data: {
    "actionType": "quiz",
    "actionUrl": "/quiz/post_office_gk_2024/instructions",
    "quizId": "post_office_gk_2024",
    "category": "quiz_update",
    "priority": "high"
  },
  topic: "all_users"
};

const response = await admin.messaging().send(message);
```

### Method 3: Using Web Admin Panel

```typescript
await NotificationService.createNotification({
  title: "🎯 New Quiz Available!",
  body: "Test your Railway exam preparation",
  actionUrl: "/quiz/railway_ntpc_2024/instructions",
  actionType: "quiz"
}, {
  type: "all_users"
}, "admin_user_id", {
  category: "quiz_update",
  priority: "high"
});
```

## 📱 Mobile App Handling

### 1. **Notification Tap Navigation**
- FCM service captures notification tap
- Extracts quiz ID from `actionUrl` or `quizId`
- Navigates to quiz instructions page
- Shows appropriate button based on quiz status

### 2. **Quiz Instructions Page**
- **Free Quiz**: Shows "Start Quiz" (green button)
- **Paid Quiz (not purchased)**: Shows "Start Payment" (orange button)
- **Paid Quiz (purchased)**: Shows "Start Quiz" (green button)

### 3. **Payment Flow**
1. User taps "Start Payment"
2. Payment confirmation dialog appears
3. PhonePe payment process initiated
4. After successful payment → access granted
5. Button changes to "Start Quiz"

## 🔧 Implementation Details

### Enhanced FCM Service
- ✅ Proper notification tap handling
- ✅ Quiz ID extraction from URLs
- ✅ Navigation to quiz instructions
- ✅ Fallback handling for invalid data

### Quiz Instruction Screen
- ✅ Dynamic button text based on quiz status
- ✅ Dynamic button color (green/orange)
- ✅ Proper payment flow integration
- ✅ Access status validation

### Notification Service
- ✅ Quiz-specific navigation handling
- ✅ URL parsing for quiz IDs
- ✅ Fallback to quiz list if invalid

## 📋 Testing Checklist

### Free Quiz Notifications
- [ ] Send notification with free quiz link
- [ ] Tap notification → navigates to instructions
- [ ] Shows "Start Quiz" button (green)
- [ ] Tapping button starts quiz immediately

### Paid Quiz Notifications (Not Purchased)
- [ ] Send notification with paid quiz link
- [ ] Tap notification → navigates to instructions
- [ ] Shows "Start Payment" button (orange)
- [ ] Tapping button opens payment dialog
- [ ] Complete payment → button changes to "Start Quiz"

### Paid Quiz Notifications (Already Purchased)
- [ ] Send notification with purchased quiz link
- [ ] Tap notification → navigates to instructions
- [ ] Shows "Start Quiz" button (green)
- [ ] Tapping button starts quiz immediately

## 🎯 Example Quiz Notifications

### SSC CGL Quiz
```json
{
  "notification": {
    "title": "🎯 SSC CGL Quantitative Aptitude",
    "body": "50 new questions added. Practice now!"
  },
  "data": {
    "actionType": "quiz",
    "actionUrl": "/quiz/ssc_cgl_quant_2024/instructions",
    "quizId": "ssc_cgl_quant_2024",
    "category": "quiz_update"
  }
}
```

### Banking Quiz
```json
{
  "notification": {
    "title": "🏦 IBPS PO Mock Test",
    "body": "Complete mock test with latest pattern"
  },
  "data": {
    "actionType": "quiz",
    "actionUrl": "/quiz/ibps_po_mock_2024/instructions",
    "quizId": "ibps_po_mock_2024",
    "category": "quiz_update"
  }
}
```

### Railway Quiz
```json
{
  "notification": {
    "title": "🚂 Railway NTPC Quiz",
    "body": "General Awareness • 100 questions"
  },
  "data": {
    "actionType": "quiz",
    "actionUrl": "/quiz/railway_ntpc_ga_2024/instructions",
    "quizId": "railway_ntpc_ga_2024",
    "category": "quiz_update"
  }
}
```

## 🔗 Quiz Link Generation

### Get Quiz ID from Firestore
```javascript
// Get specific quiz
const quizDoc = await admin.firestore()
  .collection('exams')
  .doc('quiz_id_here')
  .get();

if (quizDoc.exists) {
  const quizId = quizDoc.id;
  const actionUrl = `/quiz/${quizId}/instructions`;
}
```

### Generate Link for Notification
```javascript
function generateQuizNotificationLink(quizId) {
  return `/quiz/${quizId}/instructions`;
}

// Usage
const quizLink = generateQuizNotificationLink('ssc_cgl_2024');
// Result: "/quiz/ssc_cgl_2024/instructions"
```

## ✅ Benefits

### For Users
- **Direct Access**: Tap notification → go straight to quiz
- **Clear Status**: Know if quiz is free or requires payment
- **Smooth Flow**: Seamless payment integration
- **No Confusion**: Clear button text and colors

### For Admins
- **Easy Targeting**: Send to specific user groups
- **Rich Data**: Include quiz metadata in notifications
- **Analytics**: Track notification engagement
- **Flexible**: Support for different quiz types

## 🚀 Next Steps

1. **Test with real quiz data**
2. **Monitor notification delivery rates**
3. **Track user engagement metrics**
4. **Add notification scheduling features**
5. **Implement A/B testing for notification content**
