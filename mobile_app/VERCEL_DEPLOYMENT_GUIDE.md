# MCQ Quiz Admin Panel - Vercel Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Push to GitHub
```bash
# Navigate to web_admin directory
cd web_admin

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit changes
git commit -m "Initial commit: MCQ Quiz Admin Panel ready for Vercel deployment"

# Add GitHub remote (replace with your repository URL)
git remote add origin https://github.com/yourusername/mcq-quiz-admin-panel.git

# Push to GitHub
git push -u origin main
```

### 2. Deploy to Vercel

1. **Go to [vercel.com](https://vercel.com) and sign in with GitHub**

2. **Click "New Project"**

3. **Import your GitHub repository**

4. **Configure Environment Variables** in Vercel Dashboard:
   ```
   REACT_APP_FIREBASE_API_KEY=AIzaSyDIdFTL8Xl-E02bYB_HnuymfGBRRL6xBqk
   REACT_APP_FIREBASE_AUTH_DOMAIN=mcq-quiz-system.firebaseapp.com
   REACT_APP_FIREBASE_PROJECT_ID=mcq-quiz-system
   REACT_APP_FIREBASE_STORAGE_BUCKET=mcq-quiz-system.firebasestorage.app
   REACT_APP_FIREBASE_MESSAGING_SENDER_ID=109048215498
   REACT_APP_FIREBASE_APP_ID=1:109048215498:web:398b38704a2b075fb08133
   REACT_APP_FIREBASE_MEASUREMENT_ID=G-F5Z833J800
   REACT_APP_FUNCTIONS_URL=https://us-central1-mcq-quiz-system.cloudfunctions.net/api
   REACT_APP_ENABLE_REAL_FCM=true
   NODE_ENV=production
   REACT_APP_ENV=production
   ```

5. **Deploy!** - Vercel will automatically build and deploy your app

## 🔧 Configuration Details

### Build Settings
- **Framework Preset**: Create React App
- **Build Command**: `npm run build`
- **Output Directory**: `build`
- **Install Command**: `npm ci`

### Environment Variables
All Firebase configuration and Cloud Functions URLs are configured via environment variables for security.

### Cloud Functions
- **Production URL**: `https://us-central1-mcq-quiz-system.cloudfunctions.net/api`
- **Notification Endpoint**: `/api/notifications/send-fcm`

## 🧪 Testing After Deployment

1. **Access your deployed admin panel**
2. **Test authentication** with your admin account
3. **Test notification sending** to verify Cloud Functions integration
4. **Check browser console** for any errors

## 🔄 Automatic Deployments

Once connected to GitHub, Vercel will automatically deploy:
- **Production**: When you push to `main` branch
- **Preview**: When you create pull requests

## 📱 Mobile App Integration

The deployed admin panel will work with your mobile app for:
- ✅ User management
- ✅ Quiz creation and management
- ✅ Push notifications
- ✅ Analytics and reporting

## 🛠 Troubleshooting

### Common Issues:
1. **Build Errors**: Check environment variables are set correctly
2. **Firebase Errors**: Verify Firebase configuration
3. **Notification Errors**: Ensure Cloud Functions are deployed
4. **CORS Errors**: Should be resolved with Cloud Functions

### Support:
- Check Vercel deployment logs
- Verify Firebase Cloud Functions are running
- Test notification endpoints directly
