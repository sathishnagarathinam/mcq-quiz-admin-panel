# MCQ Quiz System - Deployment Guide

This guide covers the deployment process for the complete MCQ Quiz System across different environments.

## Prerequisites

Before deploying, ensure you have:
- Firebase CLI installed and configured
- Node.js 16+ for web admin panel
- Flutter SDK for mobile app
- Google Cloud Platform account
- Apple Developer account (for iOS)
- Google Play Console account (for Android)

## Environment Setup

### 1. Development Environment
```bash
# Clone the repository
git clone <repository-url>
cd MCQ

# Install dependencies
cd mobile_app && flutter pub get
cd ../web_admin && npm install
cd ../firebase/functions && npm install
```

### 2. Staging Environment
- Use Firebase staging project
- Deploy with staging configuration
- Test all features thoroughly

### 3. Production Environment
- Use Firebase production project
- Enable monitoring and analytics
- Set up proper security rules

## Firebase Deployment

### 1. Initialize Firebase
```bash
cd firebase
firebase login
firebase use --add  # Select your project
```

### 2. Deploy Firestore Rules and Indexes
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 3. Deploy Storage Rules
```bash
firebase deploy --only storage
```

### 4. Deploy Cloud Functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

### 5. Deploy Hosting (Web Admin)
```bash
cd ../web_admin
npm run build
firebase deploy --only hosting
```

## Web Admin Panel Deployment

### 1. Environment Configuration
Create production environment file:
```bash
# web_admin/.env.production
REACT_APP_FIREBASE_API_KEY=your_production_api_key
REACT_APP_FIREBASE_AUTH_DOMAIN=your_production_auth_domain
REACT_APP_FIREBASE_PROJECT_ID=your_production_project_id
REACT_APP_FIREBASE_STORAGE_BUCKET=your_production_storage_bucket
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_production_sender_id
REACT_APP_FIREBASE_APP_ID=your_production_app_id
REACT_APP_ENVIRONMENT=production
```

### 2. Build for Production
```bash
cd web_admin
npm run build
```

### 3. Deploy to Firebase Hosting
```bash
firebase deploy --only hosting:web-admin
```

### 4. Alternative Deployment Options

#### Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build
```

#### Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

#### AWS S3 + CloudFront
```bash
# Build the app
npm run build

# Upload to S3
aws s3 sync build/ s3://your-bucket-name --delete

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Mobile App Deployment

### Android Deployment

#### 1. Prepare for Release
```bash
cd mobile_app

# Generate keystore (first time only)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create key.properties file
echo "storePassword=your_store_password" > android/key.properties
echo "keyPassword=your_key_password" >> android/key.properties
echo "keyAlias=upload" >> android/key.properties
echo "storeFile=~/upload-keystore.jks" >> android/key.properties
```

#### 2. Update android/app/build.gradle
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 3. Build Release APK/AAB
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### 4. Upload to Google Play Console
1. Go to Google Play Console
2. Create new app or select existing
3. Upload the AAB file
4. Fill in app details, screenshots, descriptions
5. Set up pricing and distribution
6. Submit for review

### iOS Deployment

#### 1. Prepare for Release
```bash
cd mobile_app

# Update iOS configuration
flutter build ios --release
```

#### 2. Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project
3. Update Bundle Identifier
4. Set Team and Signing Certificate
5. Update version and build number
6. Configure App Store Connect

#### 3. Build and Archive
1. In Xcode: Product → Archive
2. Upload to App Store Connect
3. Wait for processing

#### 4. App Store Connect
1. Create new app version
2. Add app information, screenshots
3. Set pricing and availability
4. Submit for App Store review

## CI/CD Pipeline

### GitHub Actions

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy MCQ Quiz System

on:
  push:
    branches: [main]

jobs:
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd web_admin
          npm ci
      
      - name: Build
        run: |
          cd web_admin
          npm run build
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: your-project-id

  deploy-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd firebase/functions
          npm ci
      
      - name: Deploy Functions
        run: |
          cd firebase
          npm install -g firebase-tools
          firebase deploy --only functions --token ${{ secrets.FIREBASE_TOKEN }}

  test-mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - name: Install dependencies
        run: |
          cd mobile_app
          flutter pub get
      
      - name: Run tests
        run: |
          cd mobile_app
          flutter test
      
      - name: Build APK
        run: |
          cd mobile_app
          flutter build apk --release
```

### GitLab CI/CD

Create `.gitlab-ci.yml`:
```yaml
stages:
  - test
  - build
  - deploy

variables:
  FLUTTER_VERSION: "3.10.0"

test_web:
  stage: test
  image: node:18
  script:
    - cd web_admin
    - npm ci
    - npm run test
    - npm run lint

test_mobile:
  stage: test
  image: cirrusci/flutter:$FLUTTER_VERSION
  script:
    - cd mobile_app
    - flutter pub get
    - flutter test
    - flutter analyze

build_web:
  stage: build
  image: node:18
  script:
    - cd web_admin
    - npm ci
    - npm run build
  artifacts:
    paths:
      - web_admin/build/

deploy_production:
  stage: deploy
  image: node:18
  script:
    - npm install -g firebase-tools
    - cd firebase
    - firebase deploy --token $FIREBASE_TOKEN
  only:
    - main
```

## Monitoring and Analytics

### 1. Firebase Performance Monitoring
```typescript
// Add to mobile app
import { getPerformance } from 'firebase/performance';

const perf = getPerformance();
```

### 2. Firebase Analytics
```typescript
// Add to both mobile and web
import { getAnalytics, logEvent } from 'firebase/analytics';

const analytics = getAnalytics();
logEvent(analytics, 'quiz_completed', {
  category: 'engagement',
  score: 85
});
```

### 3. Error Tracking
```typescript
// Add Crashlytics for mobile
import crashlytics from '@react-native-firebase/crashlytics';

crashlytics().recordError(new Error('Something went wrong'));
```

### 4. Performance Monitoring
```typescript
// Add performance monitoring
import { trace } from 'firebase/performance';

const t = trace(perf, 'quiz_load_time');
t.start();
// ... load quiz
t.stop();
```

## Security Configuration

### 1. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Production rules with strict validation
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId
        && validateUserData(request.resource.data);
    }
  }
}
```

### 2. Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /uploads/{allPaths=**} {
      allow read, write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

### 3. API Security
- Enable CORS for specific domains
- Implement rate limiting
- Use HTTPS only
- Validate all inputs
- Sanitize user data

## Performance Optimization

### 1. Web Performance
- Enable gzip compression
- Use CDN for static assets
- Implement code splitting
- Optimize images
- Enable caching headers

### 2. Mobile Performance
- Optimize app size
- Use ProGuard for Android
- Optimize images and assets
- Implement lazy loading
- Use efficient state management

### 3. Database Performance
- Create proper indexes
- Optimize queries
- Use pagination
- Implement caching
- Monitor query performance

## Backup and Recovery

### 1. Database Backup
```bash
# Export Firestore data
gcloud firestore export gs://your-backup-bucket/backup-$(date +%Y%m%d)
```

### 2. Storage Backup
```bash
# Backup Firebase Storage
gsutil -m cp -r gs://your-project.appspot.com gs://your-backup-bucket/storage-backup-$(date +%Y%m%d)
```

### 3. Recovery Procedures
- Document recovery steps
- Test backup restoration
- Set up automated backups
- Monitor backup integrity

## Post-Deployment Checklist

### Immediate Tasks
- [ ] Verify all services are running
- [ ] Test critical user flows
- [ ] Check error rates and performance
- [ ] Verify security rules are active
- [ ] Test push notifications
- [ ] Validate analytics tracking

### Within 24 Hours
- [ ] Monitor user feedback
- [ ] Check crash reports
- [ ] Review performance metrics
- [ ] Verify backup systems
- [ ] Update documentation
- [ ] Notify stakeholders

### Within 1 Week
- [ ] Analyze user adoption
- [ ] Review performance trends
- [ ] Plan optimization improvements
- [ ] Update monitoring alerts
- [ ] Conduct security review

## Troubleshooting

### Common Issues
1. **Build failures**: Check dependencies and versions
2. **Deployment errors**: Verify Firebase configuration
3. **Performance issues**: Review database queries
4. **Security errors**: Check Firestore rules
5. **Mobile app crashes**: Review crash reports

### Support Resources
- Firebase Documentation
- Flutter Documentation
- React Documentation
- Stack Overflow
- GitHub Issues

## Maintenance

### Regular Tasks
- Update dependencies monthly
- Review security rules quarterly
- Backup data weekly
- Monitor performance daily
- Update documentation as needed

### Version Updates
- Plan update cycles
- Test in staging first
- Communicate changes to users
- Monitor post-update metrics
- Rollback plan if needed
