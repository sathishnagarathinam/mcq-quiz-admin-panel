import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  User,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  sendPasswordResetEmail,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../config/firebase';
import toast from 'react-hot-toast';

interface AdminUser {
  uid: string;
  email: string;
  name: string;
  role: 'admin' | 'super_admin' | 'system_admin';
  createdAt: any;
  lastLogin?: any;
  isActive: boolean;
  status?: 'pending' | 'approved' | 'rejected';
  approvedBy?: string;
  approvedAt?: any;
}

interface AuthContextType {
  user: User | null;
  adminUser: AdminUser | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, name: string) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!isMounted) return;

      setUser(user);

      if (user) {
        // Fetch admin user data from Firestore
        try {
          const adminDocRef = doc(db, 'admin_users', user.uid);
          const adminDoc = await getDoc(adminDocRef);

          if (!isMounted) return;

          if (adminDoc.exists()) {
            const adminData = adminDoc.data() as AdminUser;
            setAdminUser(adminData);

            // Update last login only for approved users (don't await to avoid blocking)
            if (adminData.isActive && adminData.status === 'approved') {
              setDoc(adminDocRef, {
                lastLogin: serverTimestamp()
              }, { merge: true }).catch(error => {
                console.warn('Failed to update last login:', error);
              });
            }
          } else {
            // User exists in Auth but not in admin_users collection
            console.warn('User not found in admin_users collection');
            setAdminUser(null);
          }
        } catch (error) {
          console.error('Error fetching admin user data:', error);
          if (isMounted) {
            setAdminUser(null);
          }
        }
      } else {
        if (isMounted) {
          setAdminUser(null);
        }
      }

      if (isMounted) {
        setLoading(false);
      }
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      setLoading(true);
      const result = await signInWithEmailAndPassword(auth, email, password);

      // Check if user exists in admin_users collection
      const adminDocRef = doc(db, 'admin_users', result.user.uid);
      const adminDoc = await getDoc(adminDocRef);

      if (!adminDoc.exists()) {
        // User exists in Auth but not authorized as admin
        await firebaseSignOut(auth);
        throw new Error('Access denied. You are not authorized to access the admin panel.');
      }

      const adminData = adminDoc.data() as AdminUser;

      // Check if account is pending approval
      if (!adminData.isActive) {
        await firebaseSignOut(auth);
        throw new Error('Your account is pending approval. Please wait for a system administrator to approve your account before you can login.');
      }

      // Additional check for approved status (if exists)
      if (adminData.status === 'pending') {
        await firebaseSignOut(auth);
        throw new Error('Your account registration is pending approval. A system administrator needs to approve your account before you can access the admin panel.');
      }

      toast.success('Successfully signed in!');
    } catch (error: any) {
      console.error('Sign in error:', error);

      // Handle specific Firebase errors
      let errorMessage = 'Failed to sign in';
      if (error.code === 'auth/network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (error.code === 'auth/user-not-found') {
        errorMessage = 'No account found with this email address.';
      } else if (error.code === 'auth/wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (error.code === 'auth/user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signUp = async (email: string, password: string, name: string) => {
    try {
      setLoading(true);

      // Create user in Firebase Auth
      const result = await createUserWithEmailAndPassword(auth, email, password);

      // Update user profile with name
      await updateProfile(result.user, {
        displayName: name
      });

      // Create admin user document in Firestore (pending approval)
      const adminUserData = {
        uid: result.user.uid,
        email: email,
        name: name,
        role: 'admin', // Default role, can be changed by system_admin
        createdAt: serverTimestamp(),
        isActive: false, // Inactive until approved
        status: 'pending', // Pending approval
        // Note: omitting lastLogin, approvedBy, approvedAt until they have values
      };

      await setDoc(doc(db, 'admin_users', result.user.uid), adminUserData);

      // Sign out the user immediately after registration
      await firebaseSignOut(auth);

      toast.success('Registration successful! Your account is pending approval. A system administrator will review and approve your account before you can login.');
    } catch (error: any) {
      console.error('Sign up error:', error);

      // Handle specific Firebase errors
      let errorMessage = 'Failed to create account';
      if (error.code === 'auth/network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (error.code === 'auth/email-already-in-use') {
        errorMessage = 'An account with this email address already exists.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'Invalid email address format.';
      } else if (error.code === 'auth/weak-password') {
        errorMessage = 'Password is too weak. Please choose a stronger password.';
      } else if (error.message) {
        errorMessage = error.message;
      }

      toast.error(errorMessage);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    try {
      await firebaseSignOut(auth);
      toast.success('Successfully signed out!');
    } catch (error: any) {
      console.error('Sign out error:', error);
      toast.error(error.message || 'Failed to sign out');
      throw error;
    }
  };

  const resetPassword = async (email: string) => {
    try {
      await sendPasswordResetEmail(auth, email);
      toast.success('Password reset email sent!');
    } catch (error: any) {
      console.error('Password reset error:', error);
      toast.error(error.message || 'Failed to send password reset email');
      throw error;
    }
  };

  const value = {
    user,
    adminUser,
    loading,
    signIn,
    signUp,
    signOut,
    resetPassword,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
