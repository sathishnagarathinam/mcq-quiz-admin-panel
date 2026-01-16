#!/bin/bash

# MCQ Quiz System - Web Admin Setup Script
# This script helps you set up the React web admin panel

set -e

echo "🌐 MCQ Quiz System - Web Admin Setup"
echo "===================================="
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

# Check if Node.js is installed
check_nodejs() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        echo "Please install Node.js from: https://nodejs.org/"
        exit 1
    fi
    print_status "Node.js is installed"
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d 'v' -f 2)
    print_info "Node.js version: $NODE_VERSION"
    
    # Check if version is 16.0.0 or higher
    if [[ $(echo "$NODE_VERSION 16.0.0" | tr " " "\n" | sort -V | head -n 1) != "16.0.0" ]]; then
        print_warning "Node.js version should be 16.0.0 or higher for best compatibility"
    else
        print_status "Node.js version is compatible"
    fi
}

# Check if npm is installed
check_npm() {
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        echo "Please install npm (usually comes with Node.js)"
        exit 1
    fi
    print_status "npm is installed"
    
    NPM_VERSION=$(npm --version)
    print_info "npm version: $NPM_VERSION"
}

# Install dependencies
install_dependencies() {
    echo ""
    echo "📦 Installing Dependencies"
    echo "========================="
    
    cd web_admin
    
    print_info "Installing npm packages..."
    npm install
    print_status "Dependencies installed successfully"
    
    cd ..
}

# Create environment configuration
create_environment_config() {
    echo ""
    echo "⚙️ Creating Environment Configuration"
    echo "===================================="
    
    cd web_admin
    
    # Create .env.local file
    print_info "Creating environment configuration..."
    
    read -p "Enter your Firebase API Key: " FIREBASE_API_KEY
    read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID
    read -p "Enter your Firebase Auth Domain (${FIREBASE_PROJECT_ID}.firebaseapp.com): " FIREBASE_AUTH_DOMAIN
    read -p "Enter your Firebase Storage Bucket (${FIREBASE_PROJECT_ID}.appspot.com): " FIREBASE_STORAGE_BUCKET
    read -p "Enter your Firebase Messaging Sender ID: " FIREBASE_MESSAGING_SENDER_ID
    read -p "Enter your Firebase App ID: " FIREBASE_APP_ID
    read -p "Enter your Firebase Measurement ID (optional): " FIREBASE_MEASUREMENT_ID
    
    # Set defaults if empty
    FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-"${FIREBASE_PROJECT_ID}.firebaseapp.com"}
    FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-"${FIREBASE_PROJECT_ID}.appspot.com"}
    
    cat > .env.local << EOF
# Firebase Configuration
REACT_APP_FIREBASE_API_KEY=$FIREBASE_API_KEY
REACT_APP_FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN
REACT_APP_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
REACT_APP_FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID
REACT_APP_FIREBASE_APP_ID=$FIREBASE_APP_ID
REACT_APP_FIREBASE_MEASUREMENT_ID=$FIREBASE_MEASUREMENT_ID

# Environment
REACT_APP_ENVIRONMENT=development
REACT_APP_DEBUG=true

# Development Configuration
REACT_APP_ENABLE_EMULATOR=true
EOF
    
    print_status "Environment configuration created"
    
    # Create production environment file
    cat > .env.production << EOF
# Firebase Configuration (Production)
REACT_APP_FIREBASE_API_KEY=$FIREBASE_API_KEY
REACT_APP_FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN
REACT_APP_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
REACT_APP_FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID
REACT_APP_FIREBASE_APP_ID=$FIREBASE_APP_ID
REACT_APP_FIREBASE_MEASUREMENT_ID=$FIREBASE_MEASUREMENT_ID

# Environment
REACT_APP_ENVIRONMENT=production
REACT_APP_DEBUG=false

# Production Configuration
REACT_APP_ENABLE_EMULATOR=false
EOF
    
    print_status "Production environment configuration created"
    
    cd ..
}

# Setup Firebase hosting
setup_firebase_hosting() {
    echo ""
    echo "🔥 Setting up Firebase Hosting"
    echo "=============================="
    
    cd firebase
    
    # Check if firebase.json exists and has hosting config
    if grep -q "hosting" firebase.json; then
        print_status "Firebase hosting already configured"
    else
        print_info "Adding hosting configuration to firebase.json..."
        
        # This would require more complex JSON manipulation
        print_warning "Please manually add hosting configuration to firebase.json"
        print_info "Add this to your firebase.json:"
        echo '{
  "hosting": {
    "public": "../web_admin/build",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}'
    fi
    
    cd ..
}

# Run tests
run_tests() {
    echo ""
    echo "🧪 Running Tests"
    echo "==============="
    
    cd web_admin
    
    print_info "Running tests..."
    npm test -- --watchAll=false
    print_status "Tests completed"
    
    print_info "Running linter..."
    npm run lint
    print_status "Linting completed"
    
    cd ..
}

# Build the application
build_application() {
    echo ""
    echo "🔨 Building Application"
    echo "======================"
    
    cd web_admin
    
    print_info "Building React application..."
    npm run build
    print_status "Build completed successfully"
    
    print_info "Build output is in the 'build' directory"
    
    cd ..
}

# Start development server
start_dev_server() {
    echo ""
    echo "🚀 Starting Development Server"
    echo "============================="
    
    cd web_admin
    
    echo ""
    read -p "Do you want to start the development server now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Starting development server..."
        print_info "The app will open at http://localhost:3000"
        npm start
    else
        print_info "You can start the development server later using: npm start"
    fi
    
    cd ..
}

# Setup VS Code configuration
setup_vscode() {
    echo ""
    echo "💻 Setting up VS Code Configuration"
    echo "==================================="
    
    cd web_admin
    
    # Create .vscode directory if it doesn't exist
    mkdir -p .vscode
    
    # Create settings.json
    cat > .vscode/settings.json << EOF
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "files.associations": {
    "*.tsx": "typescriptreact"
  }
}
EOF
    
    # Create extensions.json
    cat > .vscode/extensions.json << EOF
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense"
  ]
}
EOF
    
    print_status "VS Code configuration created"
    
    cd ..
}

# Create sample data script
create_sample_data_script() {
    echo ""
    echo "📊 Creating Sample Data Script"
    echo "============================="
    
    cat > scripts/add-sample-data.js << 'EOF'
// Sample data script for MCQ Quiz System
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Sample categories
const categories = [
  {
    id: 'volumes',
    name: 'Volumes',
    description: 'Volume-based questions for postal calculations',
    color: '#6366F1',
    isActive: true,
    order: 1
  },
  {
    id: 'po_guide',
    name: 'PO Guide',
    description: 'Post Office operational guidelines and procedures',
    color: '#8B5CF6',
    isActive: true,
    order: 2
  },
  {
    id: 'general_knowledge',
    name: 'General Knowledge',
    description: 'General awareness and current affairs',
    color: '#06B6D4',
    isActive: true,
    order: 3
  }
];

// Sample questions
const questions = [
  {
    question: 'What is the full form of PIN in PIN Code?',
    options: [
      { id: 'A', text: 'Postal Index Number', isCorrect: true },
      { id: 'B', text: 'Personal Identification Number', isCorrect: false },
      { id: 'C', text: 'Post Information Number', isCorrect: false },
      { id: 'D', text: 'Postal Information Network', isCorrect: false }
    ],
    correctAnswer: 'A',
    explanation: 'PIN stands for Postal Index Number, which is used to identify postal areas.',
    category: 'po_guide',
    difficulty: 'easy',
    examPattern: 'POSTMAN',
    isActive: true
  }
];

async function addSampleData() {
  try {
    // Add categories
    for (const category of categories) {
      await db.collection('categories').doc(category.id).set({
        ...category,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    // Add questions
    for (const question of questions) {
      await db.collection('questions').add({
        ...question,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        stats: {
          totalAttempts: 0,
          correctAttempts: 0,
          averageTime: 0
        }
      });
    }
    
    console.log('Sample data added successfully!');
  } catch (error) {
    console.error('Error adding sample data:', error);
  }
}

addSampleData();
EOF
    
    print_status "Sample data script created"
}

# Main setup function
main() {
    echo "Starting web admin setup for MCQ Quiz System..."
    echo ""
    
    check_nodejs
    check_npm
    install_dependencies
    create_environment_config
    setup_firebase_hosting
    setup_vscode
    run_tests
    build_application
    create_sample_data_script
    
    echo ""
    echo "🎉 Web Admin Setup Complete!"
    echo "============================"
    print_status "React web admin panel is ready for development"
    echo ""
    print_info "Next steps:"
    echo "1. Update Firebase configuration if needed"
    echo "2. Add sample data using the script in scripts/"
    echo "3. Test the admin panel functionality"
    echo "4. Deploy to Firebase Hosting or other platform"
    echo ""
    print_warning "Remember to:"
    echo "- Keep your environment files secure (.env.local)"
    echo "- Test all admin features thoroughly"
    echo "- Set up proper authentication for admin users"
    echo "- Configure CORS for production API calls"
    echo ""
    
    start_dev_server
}

# Run main function
main
