/**
 * Utility functions for handling errors consistently across the application
 */

/**
 * Extracts a readable error message from an unknown error object
 * @param error - The error object (can be Error, string, or unknown)
 * @param defaultMessage - Default message if no specific error message is found
 * @returns A readable error message string
 */
export function getErrorMessage(error: unknown, defaultMessage: string = 'An unknown error occurred'): string {
  if (error instanceof Error) {
    return error.message;
  }
  
  if (typeof error === 'string') {
    return error;
  }
  
  if (error && typeof error === 'object' && 'message' in error) {
    return String((error as any).message);
  }
  
  return defaultMessage;
}

/**
 * Handles Firebase-specific errors and returns user-friendly messages
 * @param error - The Firebase error object
 * @returns A user-friendly error message
 */
export function getFirebaseErrorMessage(error: unknown): string {
  const message = getErrorMessage(error);
  
  // Firebase Auth errors
  if (message.includes('auth/user-not-found')) {
    return 'No account found with this email address.';
  }
  
  if (message.includes('auth/wrong-password')) {
    return 'Incorrect password. Please try again.';
  }
  
  if (message.includes('auth/email-already-in-use')) {
    return 'An account with this email address already exists.';
  }
  
  if (message.includes('auth/weak-password')) {
    return 'Password is too weak. Please choose a stronger password.';
  }
  
  if (message.includes('auth/invalid-email')) {
    return 'Invalid email address format.';
  }
  
  if (message.includes('auth/network-request-failed')) {
    return 'Network error. Please check your internet connection and try again.';
  }
  
  if (message.includes('auth/too-many-requests')) {
    return 'Too many failed attempts. Please try again later.';
  }
  
  // Firestore errors
  if (message.includes('permission-denied')) {
    return 'Permission denied. You may not have access to this resource.';
  }
  
  if (message.includes('not-found')) {
    return 'The requested resource was not found.';
  }
  
  if (message.includes('already-exists')) {
    return 'The resource already exists.';
  }
  
  if (message.includes('failed-precondition')) {
    return 'Operation failed due to a precondition. Please try again.';
  }
  
  if (message.includes('unavailable')) {
    return 'Service temporarily unavailable. Please try again later.';
  }
  
  // Return the original message if no specific handling is found
  return message;
}

/**
 * Logs an error with context information
 * @param context - Context where the error occurred (e.g., 'UserManagement.fetchUsers')
 * @param error - The error object
 * @param additionalInfo - Additional context information
 */
export function logError(context: string, error: unknown, additionalInfo?: any): void {
  console.error(`❌ Error in ${context}:`, error);
  
  if (additionalInfo) {
    console.error('Additional context:', additionalInfo);
  }
  
  // In production, you might want to send this to an error tracking service
  // like Sentry, LogRocket, etc.
}

/**
 * Creates a standardized error handler for async operations
 * @param context - Context where the error occurred
 * @param onError - Optional callback to handle the error
 * @returns An error handler function
 */
export function createErrorHandler(
  context: string,
  onError?: (error: unknown) => void
) {
  return (error: unknown) => {
    logError(context, error);
    
    if (onError) {
      onError(error);
    }
  };
}

/**
 * Wraps an async function with error handling
 * @param fn - The async function to wrap
 * @param context - Context for error logging
 * @param onError - Optional error handler
 * @returns The wrapped function
 */
export function withErrorHandling<T extends any[], R>(
  fn: (...args: T) => Promise<R>,
  context: string,
  onError?: (error: unknown) => void
) {
  return async (...args: T): Promise<R | undefined> => {
    try {
      return await fn(...args);
    } catch (error) {
      logError(context, error);
      
      if (onError) {
        onError(error);
      }
      
      return undefined;
    }
  };
}
