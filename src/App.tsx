import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { QueryClient, QueryClientProvider } from 'react-query';
// import { ReactQueryDevtools } from 'react-query/devtools';
import { Toaster } from 'react-hot-toast';
import { HelmetProvider } from 'react-helmet-async';

import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { Layout } from './components/layout/Layout';
import ErrorBoundary from './components/ErrorBoundary';

// Pages
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import QuestionsPage from './pages/questions/QuestionsPage';
import CategoriesPage from './pages/categories/CategoriesPage';
import UsersPage from './pages/users/UsersPage';
import AnalyticsPage from './pages/analytics/AnalyticsPage';
import MobileUsersPage from './pages/mobile-users/MobileUsersPage';
import SettingsPage from './pages/settings/SettingsPage';
import PaymentSettingsPage from './pages/settings/PaymentSettingsPage';
import ForceUpdateSettingsPage from './pages/settings/ForceUpdateSettingsPage';
import UserVersionManagementPage from './pages/settings/UserVersionManagementPage';
import BulkUploadPage from './pages/bulk-upload/BulkUploadPage';
import FirebaseTestPage from './pages/test/FirebaseTestPage';
import ConfigTestPage from './pages/test/ConfigTestPage';
import DataStructureTestPage from './pages/test/DataStructureTestPage';
import TestDataGeneratorPage from './pages/test/TestDataGeneratorPage';
import UserQuizMappingTestPage from './pages/test/UserQuizMappingTestPage';
import AnalyticsRefreshPage from './pages/test/AnalyticsRefreshPage';
import UserManagementPage from './pages/user-management/UserManagementPage';
import BannerManagement from './pages/banner-management/BannerManagement';
import IntegrationTestPage from './pages/test/IntegrationTestPage';
import UploadDebugPage from './pages/test/UploadDebugPage';
import UploadDiagnosticPage from './pages/test/UploadDiagnosticPage';
import ExamHubPage from './pages/exam-hub/ExamHubPage';
import NewsManagementPage from './pages/exam-hub/NewsManagementPage';
import TipsManagementPage from './pages/exam-hub/TipsManagementPage';
import PapersManagementPage from './pages/exam-hub/PapersManagementPage';
import ResultsManagementPage from './pages/exam-hub/ResultsManagementPage';
import NotificationSenderPage from './pages/notifications/NotificationSenderPage';
import NotificationManagementPage from './pages/notifications/NotificationManagementPage';
import NotificationTestPage from './pages/test/NotificationTestPage';
import FirebaseConnectionTestPage from './pages/test/FirebaseConnectionTestPage';
import CreateTestUsersPage from './pages/test/CreateTestUsersPage';
import UserCountDiagnosticPage from './pages/test/UserCountDiagnosticPage';
import FCMTokenManagerPage from './pages/test/FCMTokenManagerPage';
import FeedbackManagementPage from './pages/feedback/FeedbackManagementPage';
import PaymentManagementPage from './pages/payments/PaymentManagementPage';
import FreeQuizAccessPage from './pages/free-quiz-access/FreeQuizAccessPage';
import RatingsManagementPage from './pages/ratings/RatingsManagementPage';
import LiveTestRegistrationsPage from './pages/live-test-registrations/LiveTestRegistrationsPage';
import InterstitialAdManagementPage from './pages/interstitial-ads/InterstitialAdManagementPage';
import ChatbotManagementPage from './pages/chatbot/ChatbotManagementPage';
import { useAuth } from './contexts/AuthContext';

// Paths allowed for the 'user' role
const USER_ROLE_ALLOWED_PATHS = ['/dashboard', '/questions', '/categories', '/bulk-upload', '/ratings', '/live-test-registrations'];

// Role-based route protection component
const RoleGuard: React.FC<{ path: string; children: React.ReactElement }> = ({ path, children }) => {
  const { adminUser } = useAuth();
  if (adminUser?.role === 'user' && !USER_ROLE_ALLOWED_PATHS.includes(`/${path}`)) {
    return <Navigate to="/dashboard" replace />;
  }
  return children;
};

// Theme configuration
const theme = createTheme({
  palette: {
    primary: {
      main: '#6366F1',
      light: '#8B5CF6',
      dark: '#4F46E5',
    },
    secondary: {
      main: '#06B6D4',
      light: '#67E8F9',
      dark: '#0891B2',
    },
    success: {
      main: '#10B981',
      light: '#34D399',
      dark: '#059669',
    },
    warning: {
      main: '#F59E0B',
      light: '#FCD34D',
      dark: '#D97706',
    },
    error: {
      main: '#EF4444',
      light: '#F87171',
      dark: '#DC2626',
    },
    background: {
      default: '#F8FAFC',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#1E293B',
      secondary: '#64748B',
    },
  },
  typography: {
    fontFamily: '"Poppins", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontSize: '2.5rem',
      fontWeight: 700,
      lineHeight: 1.2,
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 600,
      lineHeight: 1.3,
    },
    h3: {
      fontSize: '1.75rem',
      fontWeight: 600,
      lineHeight: 1.3,
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 600,
      lineHeight: 1.4,
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 600,
      lineHeight: 1.4,
    },
    h6: {
      fontSize: '1rem',
      fontWeight: 600,
      lineHeight: 1.5,
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.6,
    },
    body2: {
      fontSize: '0.875rem',
      lineHeight: 1.6,
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          padding: '12px 24px',
          fontSize: '0.875rem',
          fontWeight: 600,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 12,
          },
        },
      },
    },
  },
});

// React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

function App() {
  return (
    <ErrorBoundary>
      <HelmetProvider>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider theme={theme}>
            <CssBaseline />
            <AuthProvider>
            <Router>
              <Routes>
                {/* Public Routes */}
                <Route path="/login" element={<LoginPage />} />
                <Route path="/register" element={<RegisterPage />} />
                <Route path="/forgot-password" element={<ForgotPasswordPage />} />

                {/* Protected Routes */}
                <Route
                  path="/"
                  element={
                    <ProtectedRoute>
                      <Layout />
                    </ProtectedRoute>
                  }
                >
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  {/* Routes accessible to all roles including 'user' */}
                  <Route path="dashboard" element={<DashboardPage />} />
                  <Route path="questions" element={<QuestionsPage />} />
                  <Route path="categories" element={<CategoriesPage />} />
                  <Route path="bulk-upload" element={<BulkUploadPage />} />
                  <Route path="ratings" element={<RatingsManagementPage />} />
                  <Route path="live-test-registrations" element={<LiveTestRegistrationsPage />} />
                  {/* Routes restricted from 'user' role */}
                  <Route path="users" element={<RoleGuard path="users"><UsersPage /></RoleGuard>} />
                  <Route path="analytics" element={<RoleGuard path="analytics"><AnalyticsPage /></RoleGuard>} />
                  <Route path="mobile-users" element={<RoleGuard path="mobile-users"><MobileUsersPage /></RoleGuard>} />
                  <Route path="feedback" element={<RoleGuard path="feedback"><FeedbackManagementPage /></RoleGuard>} />
                  <Route path="settings" element={<RoleGuard path="settings"><SettingsPage /></RoleGuard>} />
                  <Route path="settings/payments" element={<RoleGuard path="settings/payments"><PaymentSettingsPage /></RoleGuard>} />
                  <Route path="settings/force-update" element={<RoleGuard path="settings/force-update"><ForceUpdateSettingsPage /></RoleGuard>} />
                  <Route path="settings/user-versions" element={<RoleGuard path="settings/user-versions"><UserVersionManagementPage /></RoleGuard>} />
                  <Route path="test-firebase" element={<RoleGuard path="test-firebase"><FirebaseTestPage /></RoleGuard>} />
                  <Route path="config-test" element={<RoleGuard path="config-test"><ConfigTestPage /></RoleGuard>} />
                  <Route path="data-structure-test" element={<RoleGuard path="data-structure-test"><DataStructureTestPage /></RoleGuard>} />
                  <Route path="test-data-generator" element={<RoleGuard path="test-data-generator"><TestDataGeneratorPage /></RoleGuard>} />
                  <Route path="user-quiz-mapping" element={<RoleGuard path="user-quiz-mapping"><UserQuizMappingTestPage /></RoleGuard>} />
                  <Route path="analytics-refresh" element={<RoleGuard path="analytics-refresh"><AnalyticsRefreshPage /></RoleGuard>} />
                  <Route path="user-management" element={<RoleGuard path="user-management"><UserManagementPage /></RoleGuard>} />
                  <Route path="banner-management" element={<RoleGuard path="banner-management"><BannerManagement /></RoleGuard>} />
                  <Route path="integration-test" element={<RoleGuard path="integration-test"><IntegrationTestPage /></RoleGuard>} />
                  <Route path="upload-debug" element={<RoleGuard path="upload-debug"><UploadDebugPage /></RoleGuard>} />
                  <Route path="upload-diagnostic" element={<RoleGuard path="upload-diagnostic"><UploadDiagnosticPage /></RoleGuard>} />
                  <Route path="notifications" element={<RoleGuard path="notifications"><NotificationManagementPage /></RoleGuard>} />
                  <Route path="notifications/send" element={<RoleGuard path="notifications/send"><NotificationSenderPage /></RoleGuard>} />
                  <Route path="notification-test" element={<RoleGuard path="notification-test"><NotificationTestPage /></RoleGuard>} />
                  <Route path="firebase-connection-test" element={<RoleGuard path="firebase-connection-test"><FirebaseConnectionTestPage /></RoleGuard>} />
                  <Route path="create-test-users" element={<RoleGuard path="create-test-users"><CreateTestUsersPage /></RoleGuard>} />
                  <Route path="user-count-diagnostic" element={<RoleGuard path="user-count-diagnostic"><UserCountDiagnosticPage /></RoleGuard>} />
                  <Route path="fcm-token-manager" element={<RoleGuard path="fcm-token-manager"><FCMTokenManagerPage /></RoleGuard>} />
                  <Route path="exam-hub" element={<RoleGuard path="exam-hub"><ExamHubPage /></RoleGuard>} />
                  <Route path="exam-hub/news" element={<RoleGuard path="exam-hub/news"><NewsManagementPage /></RoleGuard>} />
                  <Route path="exam-hub/tips" element={<RoleGuard path="exam-hub/tips"><TipsManagementPage /></RoleGuard>} />
                  <Route path="exam-hub/papers" element={<RoleGuard path="exam-hub/papers"><PapersManagementPage /></RoleGuard>} />
                  <Route path="exam-hub/results" element={<RoleGuard path="exam-hub/results"><ResultsManagementPage /></RoleGuard>} />
                  <Route path="payments" element={<RoleGuard path="payments"><PaymentManagementPage /></RoleGuard>} />
                  <Route path="free-quiz-access" element={<RoleGuard path="free-quiz-access"><FreeQuizAccessPage /></RoleGuard>} />
                  <Route path="interstitial-ads" element={<RoleGuard path="interstitial-ads"><InterstitialAdManagementPage /></RoleGuard>} />
                  <Route path="chatbot" element={<RoleGuard path="chatbot"><ChatbotManagementPage /></RoleGuard>} />
                </Route>

                {/* Catch all route */}
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </Router>
          </AuthProvider>
          
          {/* Toast notifications */}
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              style: {
                background: '#FFFFFF',
                color: '#1E293B',
                borderRadius: '12px',
                boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
              },
              success: {
                iconTheme: {
                  primary: '#10B981',
                  secondary: '#FFFFFF',
                },
              },
              error: {
                iconTheme: {
                  primary: '#EF4444',
                  secondary: '#FFFFFF',
                },
              },
            }}
          />
          
          {/* React Query Devtools */}
          {/* <ReactQueryDevtools initialIsOpen={false} /> */}
        </ThemeProvider>
      </QueryClientProvider>
    </HelmetProvider>
    </ErrorBoundary>
  );
}

export default App;
