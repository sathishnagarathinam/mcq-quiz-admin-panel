<<<<<<< HEAD
# mcq_quiz_app

A new Flutter project.
=======
# MCQ Quiz Admin Panel

A comprehensive admin panel for managing MCQ quiz applications built with React, TypeScript, and Firebase.

## 🚀 Live Demo
**Ready for Vercel Deployment** - Your URL will be here after deployment!

## 🚀 Features

- **Dashboard**: Overview of system statistics and quick actions
- **Question Management**: Create, edit, and organize quiz questions
- **Category Management**: Manage quiz categories and difficulty levels
- **User Management**: Manage mobile app users and admin accounts
- **Analytics**: Real-time user performance and system analytics
- **Bulk Upload**: Import questions from CSV files
- **Live Test Management**: Schedule and manage timed exams
- **Banner Management**: Control promotional banners in mobile app
- **Firebase Integration**: Complete backend with Firestore and Authentication

## 🛠️ Tech Stack

- **Frontend**: React 18 + TypeScript
- **UI Framework**: Material-UI (MUI) v5
- **State Management**: React Context + Hooks
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Charts**: Recharts for analytics visualization
- **File Processing**: XLSX for bulk uploads
- **Deployment**: Vercel

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sathishnagarathinam/mcq-quiz-admin-panel.git
   cd mcq-quiz-admin-panel
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Firebase:**
   - Copy `.env.example` to `.env.local`
   - Add your Firebase configuration values:
   ```env
   REACT_APP_FIREBASE_API_KEY=your-api-key
   REACT_APP_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   REACT_APP_FIREBASE_PROJECT_ID=your-project-id
   REACT_APP_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
   REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
   REACT_APP_FIREBASE_APP_ID=your-app-id
   REACT_APP_FIREBASE_MEASUREMENT_ID=your-measurement-id
   ```

4. **Start development server:**
   ```bash
   npm start
   ```

## 🚀 Deployment

### Vercel Deployment

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **Deploy to Vercel:**
   - Go to [vercel.com](https://vercel.com)
   - Import your GitHub repository
   - Add environment variables in Vercel dashboard
   - Deploy automatically

3. **Environment Variables for Vercel:**
   Add these in Vercel Dashboard → Settings → Environment Variables:
   - `REACT_APP_FIREBASE_API_KEY`
   - `REACT_APP_FIREBASE_AUTH_DOMAIN`
   - `REACT_APP_FIREBASE_PROJECT_ID`
   - `REACT_APP_FIREBASE_STORAGE_BUCKET`
   - `REACT_APP_FIREBASE_MESSAGING_SENDER_ID`
   - `REACT_APP_FIREBASE_APP_ID`
   - `REACT_APP_FIREBASE_MEASUREMENT_ID`

## 📁 Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── admin/          # Admin-specific components
│   ├── auth/           # Authentication components
│   ├── dashboard/      # Dashboard components
│   └── layout/         # Layout components
├── pages/              # Page components
│   ├── analytics/      # Analytics pages
│   ├── auth/           # Authentication pages
│   ├── dashboard/      # Dashboard pages
│   ├── questions/      # Question management
│   └── users/          # User management
├── config/             # Configuration files
├── contexts/           # React contexts
├── services/           # API services
└── utils/              # Utility functions
```

## 🔧 Available Scripts

- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier

## 🔐 Authentication

The admin panel uses Firebase Authentication with email/password. Admin users must be approved by system administrators before gaining access.

## 📊 Firebase Setup

1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Set up security rules (see `firebase/` directory)
5. Configure web app and get config values

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation in the `docs/` directory
- Review Firebase setup guides in the project

## 🔄 Updates

This admin panel is actively maintained and regularly updated with new features and improvements.
>>>>>>> b3e57b02a339c4ca60c7a7c601911d8fd453f96a
