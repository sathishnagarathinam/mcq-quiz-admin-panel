import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { storage, auth, db } from '../../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { doc, getDoc } from 'firebase/firestore';
import toast from 'react-hot-toast';

interface DiagnosticResult {
  test: string;
  status: 'pass' | 'fail' | 'warning';
  message: string;
  details?: any;
}

const UploadDiagnosticPage: React.FC = () => {
  const { adminUser } = useAuth();
  const [results, setResults] = useState<DiagnosticResult[]>([]);
  const [isRunning, setIsRunning] = useState(false);

  const addResult = (result: DiagnosticResult) => {
    setResults(prev => [...prev, result]);
  };

  const runDiagnostics = async () => {
    setIsRunning(true);
    setResults([]);

    try {
      // Test 1: Check authentication
      addResult({
        test: 'Authentication Check',
        status: auth.currentUser ? 'pass' : 'fail',
        message: auth.currentUser ? `Authenticated as: ${auth.currentUser.email}` : 'Not authenticated',
        details: { uid: auth.currentUser?.uid }
      });

      // Test 2: Check admin user document
      if (auth.currentUser) {
        try {
          const adminDocRef = doc(db, 'admin_users', auth.currentUser.uid);
          const adminDoc = await getDoc(adminDocRef);
          
          if (adminDoc.exists()) {
            const adminData = adminDoc.data();
            addResult({
              test: 'Admin User Document',
              status: 'pass',
              message: `Admin user found with role: ${adminData.role}`,
              details: adminData
            });
          } else {
            addResult({
              test: 'Admin User Document',
              status: 'fail',
              message: 'Admin user document not found in Firestore',
            });
          }
        } catch (error) {
          addResult({
            test: 'Admin User Document',
            status: 'fail',
            message: `Error fetching admin user: ${error}`,
          });
        }
      }

      // Test 3: Check Firebase Storage configuration
      try {
        const testRef = ref(storage, 'test/diagnostic-test.txt');
        addResult({
          test: 'Storage Configuration',
          status: 'pass',
          message: 'Firebase Storage is configured and accessible',
          details: { bucket: storage.app.options.storageBucket }
        });
      } catch (error) {
        addResult({
          test: 'Storage Configuration',
          status: 'fail',
          message: `Storage configuration error: ${error}`,
        });
      }

      // Test 4: Test file upload permissions
      try {
        const testFile = new File(['test content'], 'diagnostic-test.txt', { type: 'text/plain' });
        const testRef = ref(storage, 'exam_hub/papers/diagnostic-test.txt');
        
        await uploadBytes(testRef, testFile);
        const downloadURL = await getDownloadURL(testRef);
        
        addResult({
          test: 'Upload Permissions',
          status: 'pass',
          message: 'Successfully uploaded test file to exam_hub/papers/',
          details: { downloadURL }
        });
      } catch (error: any) {
        addResult({
          test: 'Upload Permissions',
          status: 'fail',
          message: `Upload failed: ${error.message}`,
          details: { 
            code: error.code,
            fullError: error
          }
        });
      }

      // Test 5: Test PDF file validation
      try {
        const testPdfFile = new File(['%PDF-1.4 test'], 'test.pdf', { type: 'application/pdf' });
        const testRef = ref(storage, 'exam_hub/papers/diagnostic-test.pdf');
        
        await uploadBytes(testRef, testPdfFile);
        
        addResult({
          test: 'PDF Upload Test',
          status: 'pass',
          message: 'Successfully uploaded test PDF file',
        });
      } catch (error: any) {
        addResult({
          test: 'PDF Upload Test',
          status: 'fail',
          message: `PDF upload failed: ${error.message}`,
          details: { 
            code: error.code,
            fullError: error
          }
        });
      }

    } catch (error) {
      addResult({
        test: 'General Error',
        status: 'fail',
        message: `Unexpected error during diagnostics: ${error}`,
      });
    } finally {
      setIsRunning(false);
    }
  };

  const getStatusColor = (status: DiagnosticResult['status']) => {
    switch (status) {
      case 'pass': return 'text-green-600';
      case 'fail': return 'text-red-600';
      case 'warning': return 'text-yellow-600';
      default: return 'text-gray-600';
    }
  };

  const getStatusIcon = (status: DiagnosticResult['status']) => {
    switch (status) {
      case 'pass': return '✅';
      case 'fail': return '❌';
      case 'warning': return '⚠️';
      default: return '❓';
    }
  };

  return (
    <div className="p-6">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Upload Diagnostic Tool</h1>
        
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">System Diagnostics</h2>
            <button
              onClick={runDiagnostics}
              disabled={isRunning}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              {isRunning ? 'Running...' : 'Run Diagnostics'}
            </button>
          </div>

          {results.length > 0 && (
            <div className="space-y-4">
              {results.map((result, index) => (
                <div key={index} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="font-medium">{result.test}</h3>
                    <span className={`flex items-center gap-2 ${getStatusColor(result.status)}`}>
                      {getStatusIcon(result.status)}
                      {result.status.toUpperCase()}
                    </span>
                  </div>
                  <p className="text-gray-700 mb-2">{result.message}</p>
                  {result.details && (
                    <details className="mt-2">
                      <summary className="cursor-pointer text-sm text-gray-500">Show Details</summary>
                      <pre className="mt-2 text-xs bg-gray-100 p-2 rounded overflow-auto">
                        {JSON.stringify(result.details, null, 2)}
                      </pre>
                    </details>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <h3 className="font-medium text-yellow-800 mb-2">Instructions:</h3>
          <ol className="list-decimal list-inside text-sm text-yellow-700 space-y-1">
            <li>Make sure Firebase Storage is enabled in the Firebase Console</li>
            <li>Ensure you're logged in as an admin user</li>
            <li>Check that storage rules are properly deployed</li>
            <li>Run diagnostics to identify specific issues</li>
          </ol>
        </div>
      </div>
    </div>
  );
};

export default UploadDiagnosticPage;
