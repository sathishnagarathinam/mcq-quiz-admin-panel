/// Supabase Configuration
/// 
/// This file contains the Supabase project configuration.
/// You'll need to replace these values with your actual Supabase project details.
class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://rkstmcvgafjppzwyqsxd.supabase.co';
  
  // TODO: Replace with your actual Supabase anon key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrc3RtY3ZnYWZqcHB6d3lxc3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0MjY3ODUsImV4cCI6MjA2NzAwMjc4NX0.3LCmmT4j8n4nCDn2UdQwNKBYM6nb3wdlA35EMhPyRJ4';
  
  // Database table names
  static const String mobileUsersTable = 'mobile_users';
  static const String adminUsersTable = 'admin_users';
  static const String quizzesTable = 'quizzes';
  static const String questionsTable = 'questions';
  static const String userQuizResultsTable = 'user_quiz_results';
  
  // Auth configuration
  static const bool enableEmailConfirmation = true;
  static const bool enablePasswordRecovery = true;
  
  // Session configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const bool persistSession = true;
}

/// Instructions for setting up Supabase:
/// 
/// 1. Go to https://supabase.com and create a new project
/// 2. Get your project URL and anon key from Settings > API
/// 3. Replace the values above with your actual Supabase credentials
/// 4. Set up the database tables (see migration guide)
/// 5. Configure authentication settings in Supabase dashboard
/// 
/// Database Schema:
/// 
/// mobile_users table:
/// - id (uuid, primary key, default: gen_random_uuid())
/// - email (text, unique, not null)
/// - name (text, not null)
/// - phone_number (text)
/// - office_name (text)
/// - designation (text)
/// - user_type (text, default: 'mobile_user')
/// - email_verified (boolean, default: false)
/// - profile_complete (boolean, default: true)
/// - is_active (boolean, default: true)
/// - quizzes_taken (integer, default: 0)
/// - total_score (integer, default: 0)
/// - average_score (real, default: 0.0)
/// - preferences (jsonb, default: '{"notifications": true, "darkMode": false, "language": "en"}')
/// - created_at (timestamp with time zone, default: now())
/// - updated_at (timestamp with time zone, default: now())
/// 
/// Row Level Security (RLS) Policies:
/// 
/// mobile_users:
/// - Users can read their own data: auth.uid() = id
/// - Users can update their own data: auth.uid() = id
/// - Users can insert their own data during registration
/// 
/// Authentication Settings in Supabase Dashboard:
/// - Enable email authentication
/// - Configure email templates
/// - Set up redirect URLs for password reset
/// - Configure session settings
