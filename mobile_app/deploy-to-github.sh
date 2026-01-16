#!/bin/bash

# MCQ Quiz Admin Panel - GitHub Deployment Script

echo "🚀 Deploying MCQ Quiz Admin Panel to GitHub for Vercel"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the web_admin directory."
    exit 1
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📁 Initializing Git repository..."
    git init
    echo "✅ Git repository initialized"
fi

# Add all files
echo "📦 Adding files to Git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit"
else
    # Commit changes
    echo "💾 Committing changes..."
    git commit -m "Deploy MCQ Quiz Admin Panel to Vercel

Features:
- Complete admin panel for MCQ quiz management
- User management with approval system
- Push notifications via Firebase Cloud Functions
- Analytics dashboard
- Bulk upload functionality
- Live test management
- Ready for Vercel deployment

Tech Stack:
- React 18 + TypeScript
- Material-UI
- Firebase (Firestore, Auth, Cloud Functions)
- FCM for push notifications

Deployment:
- Configured for Vercel
- Environment variables documented
- Production Cloud Functions deployed"

    echo "✅ Changes committed"
fi

# Check if remote origin exists
if git remote get-url origin >/dev/null 2>&1; then
    echo "🔗 Remote origin already configured"
    echo "📤 Pushing to GitHub..."
    git push origin main
else
    echo "⚠️  Remote origin not configured"
    echo ""
    echo "Please add your GitHub repository as remote origin:"
    echo "git remote add origin https://github.com/yourusername/mcq-quiz-admin-panel.git"
    echo "git push -u origin main"
    echo ""
    echo "Then deploy to Vercel:"
    echo "1. Go to https://vercel.com"
    echo "2. Import your GitHub repository"
    echo "3. Configure environment variables (see VERCEL_DEPLOYMENT_GUIDE.md)"
    echo "4. Deploy!"
fi

echo ""
echo "🎉 Deployment preparation complete!"
echo ""
echo "Next steps:"
echo "1. Push to GitHub (if not done automatically)"
echo "2. Go to https://vercel.com"
echo "3. Import your repository"
echo "4. Configure environment variables"
echo "5. Deploy!"
echo ""
echo "📚 See VERCEL_DEPLOYMENT_GUIDE.md for detailed instructions"
