import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getStorage, connectStorageEmulator } from 'firebase/storage';
import { getAnalytics } from 'firebase/analytics';
import { getFunctions, connectFunctionsEmulator } from 'firebase/functions';

// Firebase configuration
// These values come from environment variables (.env.local or .env)
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
  measurementId: process.env.REACT_APP_FIREBASE_MEASUREMENT_ID
};

// Debug: Log Firebase config (without sensitive data)
console.log('🔥 Firebase Config Status:', {
  hasApiKey: !!firebaseConfig.apiKey,
  hasAuthDomain: !!firebaseConfig.authDomain,
  hasProjectId: !!firebaseConfig.projectId,
  hasStorageBucket: !!firebaseConfig.storageBucket,
  hasMessagingSenderId: !!firebaseConfig.messagingSenderId,
  hasAppId: !!firebaseConfig.appId,
  projectId: firebaseConfig.projectId, // Safe to log
  authDomain: firebaseConfig.authDomain, // Safe to log
});

// Validate required Firebase config
const requiredFields = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId'];
const missingFields = requiredFields.filter(field => !firebaseConfig[field as keyof typeof firebaseConfig]);

if (missingFields.length > 0) {
  console.error('❌ Missing Firebase environment variables:', missingFields);
  throw new Error(`Missing Firebase configuration: ${missingFields.join(', ')}`);
}

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const functions = getFunctions(app);

// Initialize Analytics (only in production)
export const analytics = typeof window !== 'undefined' && process.env.NODE_ENV === 'production' 
  ? getAnalytics(app) 
  : null;

// Connect to emulators in development (only if explicitly enabled)
if (process.env.NODE_ENV === 'development' && process.env.REACT_APP_USE_EMULATORS === 'true') {
  const isEmulatorConnected = {
    auth: false,
    firestore: false,
    storage: false,
    functions: false
  };

  console.log('🔧 Connecting to Firebase emulators...');

  // Auth emulator
  if (!isEmulatorConnected.auth) {
    try {
      connectAuthEmulator(auth, 'http://localhost:9099');
      isEmulatorConnected.auth = true;
      console.log('✅ Connected to Auth emulator');
    } catch (error) {
      console.warn('⚠️ Failed to connect to Auth emulator:', error);
    }
  }

  // Firestore emulator
  if (!isEmulatorConnected.firestore) {
    try {
      connectFirestoreEmulator(db, 'localhost', 8080);
      isEmulatorConnected.firestore = true;
      console.log('✅ Connected to Firestore emulator');
    } catch (error) {
      console.warn('⚠️ Failed to connect to Firestore emulator:', error);
    }
  }

  // Storage emulator
  if (!isEmulatorConnected.storage) {
    try {
      connectStorageEmulator(storage, 'localhost', 9199);
      isEmulatorConnected.storage = true;
      console.log('✅ Connected to Storage emulator');
    } catch (error) {
      console.warn('⚠️ Failed to connect to Storage emulator:', error);
    }
  }

  // Functions emulator
  if (!isEmulatorConnected.functions) {
    try {
      connectFunctionsEmulator(functions, 'localhost', 5001);
      isEmulatorConnected.functions = true;
      console.log('✅ Connected to Functions emulator');
    } catch (error) {
      console.warn('⚠️ Failed to connect to Functions emulator:', error);
    }
  }
} else {
  console.log('🔥 Using production Firebase services');
}

// Export the app instance
export default app;

// Helper function to check if Firebase is properly configured
export const isFirebaseConfigured = (): boolean => {
  const hasAllRequiredFields = !!(
    firebaseConfig.apiKey &&
    firebaseConfig.authDomain &&
    firebaseConfig.projectId &&
    firebaseConfig.storageBucket &&
    firebaseConfig.messagingSenderId &&
    firebaseConfig.appId
  );
  
  const hasValidValues = !!(
    firebaseConfig.apiKey !== 'your-web-api-key-here' &&
    !firebaseConfig.apiKey?.includes('your-') &&
    !firebaseConfig.apiKey?.includes('YOUR_')
  );
  
  return hasAllRequiredFields && hasValidValues;
};

// Helper function to get current environment
export const getEnvironment = (): 'development' | 'staging' | 'production' => {
  if (process.env.NODE_ENV === 'development') return 'development';
  if (process.env.REACT_APP_ENVIRONMENT === 'staging') return 'staging';
  return 'production';
};

// Firebase configuration validation
if (!isFirebaseConfigured()) {
  console.error('🔥 Firebase configuration is incomplete or using placeholder values!');
  console.error('📋 To fix this:');
  console.error('1. Go to https://console.firebase.google.com/');
  console.error('2. Select your project: mcq-quiz-system');
  console.error('3. Go to Project Settings → General → Your apps');
  console.error('4. Copy the config values to your .env.local file');
  console.error('5. Required environment variables:');
  console.error('   - REACT_APP_FIREBASE_API_KEY');
  console.error('   - REACT_APP_FIREBASE_AUTH_DOMAIN');
  console.error('   - REACT_APP_FIREBASE_PROJECT_ID');
  console.error('   - REACT_APP_FIREBASE_STORAGE_BUCKET');
  console.error('   - REACT_APP_FIREBASE_MESSAGING_SENDER_ID');
  console.error('   - REACT_APP_FIREBASE_APP_ID');
  console.error('6. Restart your development server after updating');
}

// Log current configuration (without sensitive data)
console.log('Firebase initialized for environment:', getEnvironment());
console.log('Project ID:', firebaseConfig.projectId);
console.log('Auth Domain:', firebaseConfig.authDomain);
