#!/bin/bash

# Deploy Firestore Rules Script
# Usage: ./deploy-firestore-rules.sh [dev|prod]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔥 Firestore Rules Deployment${NC}"
echo "=============================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Please install it using: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}🔐 Please login to Firebase...${NC}"
    firebase login
fi

# Get the environment argument
ENV=${1:-dev}

cd firebase

if [ "$ENV" = "dev" ]; then
    echo -e "${YELLOW}📋 Deploying DEVELOPMENT rules (more permissive)${NC}"
    
    # Backup current rules
    if [ -f "firestore.rules" ]; then
        cp firestore.rules firestore.rules.backup
        echo -e "${GREEN}✅ Backed up current rules to firestore.rules.backup${NC}"
    fi
    
    # Copy dev rules
    cp firestore.rules.dev firestore.rules
    echo -e "${GREEN}✅ Using development rules${NC}"
    
elif [ "$ENV" = "prod" ]; then
    echo -e "${BLUE}📋 Deploying PRODUCTION rules (secure)${NC}"
    
    # Restore from backup if exists
    if [ -f "firestore.rules.backup" ]; then
        cp firestore.rules.backup firestore.rules
        echo -e "${GREEN}✅ Restored production rules from backup${NC}"
    else
        echo -e "${YELLOW}⚠️  No backup found, using current firestore.rules${NC}"
    fi
    
else
    echo -e "${RED}❌ Invalid environment. Use 'dev' or 'prod'${NC}"
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Deploy the rules
echo -e "${BLUE}🚀 Deploying Firestore rules...${NC}"
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 Firestore rules deployed successfully!${NC}"
    
    if [ "$ENV" = "dev" ]; then
        echo -e "${YELLOW}⚠️  Development rules are active (more permissive)${NC}"
        echo -e "${YELLOW}   Remember to deploy production rules before going live!${NC}"
    else
        echo -e "${GREEN}✅ Production rules are active (secure)${NC}"
    fi
else
    echo -e "${RED}❌ Failed to deploy Firestore rules${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
if [ "$ENV" = "dev" ]; then
    echo "1. Test admin registration: http://localhost:3000/register"
    echo "2. Test Firebase connection: http://localhost:3000/test-firebase"
    echo "3. Deploy production rules when ready: $0 prod"
else
    echo "1. Test that authentication still works"
    echo "2. Verify admin users can access their data"
    echo "3. Check that unauthorized access is blocked"
fi
