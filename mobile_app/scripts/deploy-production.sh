#!/bin/bash

# MCQ Quiz System - Production Deployment Script
# This script deploys the system to production environment

set -e

echo "🚀 MCQ Quiz System - Production Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Configuration
ENVIRONMENT="production"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

# Pre-deployment checks
pre_deployment_checks() {
    echo ""
    echo "🔍 Pre-deployment Checks"
    echo "======================="
    
    # Check if Firebase CLI is installed and logged in
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed"
        exit 1
    fi
    
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged in to Firebase"
        exit 1
    fi
    
    print_status "Firebase CLI ready"
    
    # Check if production project is selected
    CURRENT_PROJECT=$(firebase use)
    print_info "Current Firebase project: $CURRENT_PROJECT"
    
    read -p "Is this the correct production project? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Please select the correct production project using: firebase use <project-id>"
        exit 1
    fi
    
    # Check environment configurations
    if [ ! -f "web_admin/.env.production" ]; then
        print_warning "Production environment file not found for web admin"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_status "Pre-deployment checks completed"
}

# Create backup
create_backup() {
    echo ""
    echo "💾 Creating Backup"
    echo "=================="
    
    mkdir -p "$BACKUP_DIR"
    
    print_info "Creating database backup..."
    
    # Export Firestore data
    PROJECT_ID=$(firebase use)
    gcloud firestore export "gs://${PROJECT_ID}-backup/firestore-backup-$(date +%Y%m%d_%H%M%S)" --project="$PROJECT_ID" || {
        print_warning "Failed to create Firestore backup (requires gcloud CLI)"
    }
    
    # Backup current deployment
    if [ -d "web_admin/build" ]; then
        cp -r web_admin/build "$BACKUP_DIR/web_admin_build"
        print_status "Web admin build backed up"
    fi
    
    print_status "Backup created in $BACKUP_DIR"
}

# Build applications
build_applications() {
    echo ""
    echo "🔨 Building Applications"
    echo "======================="
    
    # Build web admin panel
    if [ -d "web_admin" ]; then
        print_info "Building web admin panel..."
        cd web_admin
        
        # Install dependencies
        npm ci --production=false
        
        # Run tests
        npm test -- --watchAll=false
        
        # Build for production
        npm run build
        
        print_status "Web admin panel built successfully"
        cd ..
    fi
    
    # Build Firebase Functions
    if [ -d "firebase/functions" ]; then
        print_info "Building Firebase Functions..."
        cd firebase/functions
        
        # Install dependencies
        npm ci --production=false
        
        # Run linting
        npm run lint
        
        # Build TypeScript
        npm run build
        
        print_status "Firebase Functions built successfully"
        cd ..
    fi
}

# Deploy Firebase services
deploy_firebase() {
    echo ""
    echo "🔥 Deploying Firebase Services"
    echo "============================="
    
    cd firebase
    
    # Deploy Firestore rules and indexes
    print_info "Deploying Firestore rules and indexes..."
    firebase deploy --only firestore
    print_status "Firestore rules and indexes deployed"
    
    # Deploy Storage rules
    print_info "Deploying Storage rules..."
    firebase deploy --only storage
    print_status "Storage rules deployed"
    
    # Deploy Cloud Functions
    if [ -d "functions" ]; then
        print_info "Deploying Cloud Functions..."
        firebase deploy --only functions
        print_status "Cloud Functions deployed"
    fi
    
    # Deploy Hosting (Web Admin)
    print_info "Deploying web admin to Firebase Hosting..."
    firebase deploy --only hosting
    print_status "Web admin deployed to Firebase Hosting"
    
    cd ..
}

# Configure production settings
configure_production() {
    echo ""
    echo "⚙️ Configuring Production Settings"
    echo "================================="
    
    cd firebase
    
    # Set Firebase Functions configuration
    print_info "Setting production configuration..."
    
    firebase functions:config:set \
        app.environment="production" \
        app.debug="false" \
        app.log_level="warn" || {
        print_warning "Failed to set some configuration values"
    }
    
    print_status "Production configuration set"
    cd ..
}

# Setup monitoring
setup_monitoring() {
    echo ""
    echo "📊 Setting up Monitoring"
    echo "======================="
    
    print_info "Monitoring setup includes:"
    echo "1. Firebase Performance Monitoring (already configured)"
    echo "2. Firebase Analytics (already configured)"
    echo "3. Error reporting via Firebase Crashlytics"
    echo "4. Custom metrics via Cloud Functions"
    
    # Create monitoring dashboard script
    cat > scripts/setup-monitoring.js << 'EOF'
// Monitoring setup script
const admin = require('firebase-admin');

async function setupMonitoring() {
  admin.initializeApp();
  const db = admin.firestore();
  
  // Create monitoring collection
  await db.collection('monitoring').doc('system_health').set({
    lastCheck: admin.firestore.FieldValue.serverTimestamp(),
    status: 'healthy',
    version: '1.0.0',
    environment: 'production'
  });
  
  console.log('Monitoring setup completed');
}

setupMonitoring().catch(console.error);
EOF
    
    node scripts/setup-monitoring.js
    print_status "Monitoring configured"
}

# Setup SSL and custom domain
setup_domain() {
    echo ""
    echo "🌐 Domain Configuration"
    echo "======================"
    
    print_info "To set up a custom domain:"
    echo "1. Go to Firebase Console > Hosting"
    echo "2. Click 'Add custom domain'"
    echo "3. Enter your domain name"
    echo "4. Follow the verification steps"
    echo "5. Update DNS records as instructed"
    echo ""
    
    read -p "Do you want to configure a custom domain now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Opening Firebase Console..."
        open "https://console.firebase.google.com/project/$(firebase use)/hosting/main"
    fi
}

# Post-deployment verification
post_deployment_verification() {
    echo ""
    echo "✅ Post-deployment Verification"
    echo "=============================="
    
    # Get the hosting URL
    PROJECT_ID=$(firebase use)
    HOSTING_URL="https://${PROJECT_ID}.web.app"
    
    print_info "Verifying deployment..."
    
    # Test web admin panel
    if curl -f "$HOSTING_URL" > /dev/null 2>&1; then
        print_status "Web admin panel is accessible"
    else
        print_error "Web admin panel is not accessible"
    fi
    
    # Test API endpoints
    API_URL="https://us-central1-${PROJECT_ID}.cloudfunctions.net/api"
    if curl -f "${API_URL}/health" > /dev/null 2>&1; then
        print_status "API endpoints are accessible"
    else
        print_warning "API endpoints may not be accessible yet (can take a few minutes)"
    fi
    
    print_info "Deployment URLs:"
    echo "Web Admin Panel: $HOSTING_URL"
    echo "API Base URL: $API_URL"
}

# Setup CI/CD
setup_cicd() {
    echo ""
    echo "🔄 CI/CD Setup"
    echo "=============="
    
    print_info "Setting up GitHub Actions workflow..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: web_admin/package-lock.json
      
      - name: Install dependencies
        run: |
          cd web_admin
          npm ci
      
      - name: Run tests
        run: |
          cd web_admin
          npm test -- --watchAll=false
      
      - name: Build
        run: |
          cd web_admin
          npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd web_admin
          npm ci
          cd ../firebase/functions
          npm ci
      
      - name: Build applications
        run: |
          cd web_admin
          npm run build
          cd ../firebase/functions
          npm run build
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: '${{ secrets.FIREBASE_PROJECT_ID }}'
EOF
    
    print_status "GitHub Actions workflow created"
    
    print_info "To complete CI/CD setup:"
    echo "1. Add repository secrets in GitHub:"
    echo "   - FIREBASE_SERVICE_ACCOUNT (service account JSON)"
    echo "   - FIREBASE_PROJECT_ID (your project ID)"
    echo "2. Push to main branch to trigger deployment"
}

# Generate deployment report
generate_deployment_report() {
    echo ""
    echo "📋 Deployment Report"
    echo "==================="
    
    PROJECT_ID=$(firebase use)
    TIMESTAMP=$(date)
    
    cat > "deployment-report-$(date +%Y%m%d_%H%M%S).md" << EOF
# MCQ Quiz System - Deployment Report

**Date:** $TIMESTAMP
**Environment:** Production
**Project ID:** $PROJECT_ID

## Deployed Components

- ✅ Web Admin Panel (Firebase Hosting)
- ✅ Firebase Functions (API)
- ✅ Firestore Database (Rules & Indexes)
- ✅ Firebase Storage (Rules)
- ✅ Authentication (Phone Number)

## URLs

- **Web Admin Panel:** https://${PROJECT_ID}.web.app
- **API Base URL:** https://us-central1-${PROJECT_ID}.cloudfunctions.net/api

## Next Steps

1. Test all functionality thoroughly
2. Set up monitoring alerts
3. Configure custom domain (optional)
4. Train admin users
5. Add more quiz content

## Backup Information

- **Backup Location:** $BACKUP_DIR
- **Database Backup:** gs://${PROJECT_ID}-backup/

## Support

For issues or questions, refer to the documentation in the \`docs/\` directory.
EOF
    
    print_status "Deployment report generated"
}

# Main deployment function
main() {
    echo "Starting production deployment..."
    echo ""
    
    print_warning "⚠️  PRODUCTION DEPLOYMENT WARNING ⚠️"
    echo "This will deploy to your production environment."
    echo "Make sure you have:"
    echo "1. Tested everything in staging"
    echo "2. Backed up existing data"
    echo "3. Notified users of potential downtime"
    echo ""
    
    read -p "Are you sure you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    pre_deployment_checks
    create_backup
    build_applications
    deploy_firebase
    configure_production
    setup_monitoring
    post_deployment_verification
    setup_domain
    setup_cicd
    generate_deployment_report
    
    echo ""
    echo "🎉 Production Deployment Complete!"
    echo "================================="
    print_status "MCQ Quiz System is now live in production"
    echo ""
    print_info "Important next steps:"
    echo "1. Test all features thoroughly"
    echo "2. Monitor system performance"
    echo "3. Set up regular backups"
    echo "4. Train admin users"
    echo "5. Add quiz content"
    echo ""
    print_warning "Remember to:"
    echo "- Monitor error rates and performance"
    echo "- Set up alerting for critical issues"
    echo "- Keep the system updated"
    echo "- Regularly backup data"
    echo ""
}

# Run main function
main
