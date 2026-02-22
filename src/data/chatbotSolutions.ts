/**
 * Pre-configured Chatbot Solutions for MCQ Quiz App
 * These solutions can be seeded into the support_solutions Firestore collection
 */

export interface ChatbotSolution {
  title: string;
  description: string;
  keywords: string[];
  patterns: string[];
  category: 'general' | 'payment' | 'quiz' | 'account' | 'technical' | 'exam' | 'subscription' | 'other';
  priority: number;
  isActive: boolean;
  triggerCount: number;
}

export const chatbotSolutions: ChatbotSolution[] = [
  // ========== GENERAL (5 solutions) ==========
  {
    title: 'Welcome & How to Use App',
    description: '👋 Welcome to MCQ Quiz App! Here\'s how to get started:\n\n1. **Browse Exams**: Go to Home tab to see available exams\n2. **Select a Quiz**: Tap on any exam card to view quiz details\n3. **Start Quiz**: Click "Start Quiz" to begin\n4. **Track Progress**: View your results in Profile section\n\nNeed more help? Feel free to ask! 📚',
    keywords: ['hello', 'hi', 'help', 'start', 'how', 'use', 'app', 'guide', 'tutorial', 'begin'],
    patterns: ['how to use', 'how to start', 'help me', 'get started', 'new user'],
    category: 'general',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'App Navigation Guide',
    description: '🧭 **App Navigation Guide**:\n\n• **Home** 🏠 - Browse and filter exams by category\n• **Quiz** 📝 - View your ongoing quizzes\n• **Exam** 📊 - Access exam history and results\n• **Profile** 👤 - Manage account, settings, and view progress\n• **Chatbot** 🤖 - Get instant help (You\'re here!)\n\nUse the bottom navigation bar to switch between sections.',
    keywords: ['navigate', 'navigation', 'menu', 'tabs', 'sections', 'where', 'find', 'home', 'profile'],
    patterns: ['how to navigate', 'where is', 'find the', 'app sections', 'main menu'],
    category: 'general',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Contact Support',
    description: '📧 **Need Additional Help?**\n\nIf this chatbot couldn\'t resolve your issue, you can:\n\n1. **Email us**: support@mcqquiz.com\n2. **Response time**: Within 24-48 hours\n3. **Include**: Your registered phone number and detailed description\n\nOur support team is here to help! 🙌',
    keywords: ['contact', 'support', 'email', 'human', 'agent', 'talk', 'person', 'reach', 'call'],
    patterns: ['contact support', 'talk to human', 'speak to agent', 'email support', 'customer service'],
    category: 'general',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'App Version & Updates',
    description: '📱 **App Updates**:\n\nTo ensure the best experience:\n\n1. **Check version**: Go to Profile → Settings → About\n2. **Update app**: Visit Play Store/App Store and tap "Update"\n3. **Auto-update**: Enable auto-updates for latest features\n\n💡 New features and bug fixes are released regularly!',
    keywords: ['version', 'update', 'latest', 'new', 'features', 'upgrade', 'store', 'download'],
    patterns: ['app version', 'update app', 'latest version', 'new features', 'how to update'],
    category: 'general',
    priority: 5,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Feedback & Suggestions',
    description: '💬 **We Value Your Feedback!**\n\nShare your thoughts:\n\n1. **In-app**: Profile → Rate Us → Leave a review\n2. **Email**: feedback@mcqquiz.com\n3. **Suggestions**: We read every suggestion!\n\nYour feedback helps us improve the app for everyone. Thank you! ⭐',
    keywords: ['feedback', 'suggestion', 'review', 'rate', 'improve', 'feature', 'request', 'idea'],
    patterns: ['give feedback', 'suggest feature', 'rate app', 'improvement', 'new feature request'],
    category: 'general',
    priority: 5,
    isActive: true,
    triggerCount: 0,
  },

  // ========== PAYMENT (5 solutions) ==========
  {
    title: 'Payment Failed',
    description: '💳 **Payment Failed? Here\'s what to do:**\n\n1. **Check balance**: Ensure sufficient funds in your account\n2. **Retry payment**: Wait 5 minutes and try again\n3. **Try another method**: Use UPI, Card, or Net Banking\n4. **Bank issue**: Contact your bank if amount was debited\n\n⏰ If debited but not activated, wait 30 mins for auto-refund or contact support.',
    keywords: ['payment', 'failed', 'error', 'not', 'working', 'declined', 'rejected', 'transaction'],
    patterns: ['payment failed', 'payment not working', 'transaction failed', 'payment error', 'payment declined'],
    category: 'payment',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Request Refund',
    description: '💰 **Refund Policy:**\n\n**Eligible for refund:**\n• Double payment for same quiz\n• Technical issue preventing access\n• Within 7 days of purchase\n\n**How to request:**\n1. Email: refunds@mcqquiz.com\n2. Include: Transaction ID, Phone number, Reason\n\n⏱️ Refunds processed within 5-7 business days.',
    keywords: ['refund', 'money', 'back', 'return', 'cancel', 'reimbursement', 'payment', 'reverse'],
    patterns: ['want refund', 'refund money', 'get refund', 'money back', 'cancel payment'],
    category: 'payment',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Payment Methods Available',
    description: '💳 **Accepted Payment Methods:**\n\n• **UPI**: GPay, PhonePe, Paytm, BHIM\n• **Cards**: Visa, Mastercard, RuPay (Credit/Debit)\n• **Net Banking**: All major banks\n• **Wallets**: Paytm, Amazon Pay\n\n🔒 All payments are 100% secure with bank-grade encryption.',
    keywords: ['payment', 'method', 'upi', 'card', 'debit', 'credit', 'netbanking', 'wallet', 'gpay', 'paytm'],
    patterns: ['payment methods', 'how to pay', 'accept upi', 'pay with card', 'payment options'],
    category: 'payment',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Double Payment / Charged Twice',
    description: '⚠️ **Charged Twice?**\n\nDon\'t worry! Here\'s what happens:\n\n1. **Auto-refund**: Duplicate payments are auto-refunded within 24-48 hours\n2. **Check status**: One payment activates your quiz, other gets refunded\n3. **Not received?**: Email refunds@mcqquiz.com with both Transaction IDs\n\n📧 Include: Phone number, Transaction IDs, Payment screenshots',
    keywords: ['double', 'twice', 'duplicate', 'charged', 'two', 'multiple', 'again', 'repeat'],
    patterns: ['charged twice', 'double payment', 'paid twice', 'duplicate charge', 'double charged'],
    category: 'payment',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Quiz Not Activated After Payment',
    description: '🔓 **Quiz Not Activated?**\n\nIf you paid but quiz shows as locked:\n\n1. **Wait**: Allow 5-10 minutes for activation\n2. **Restart app**: Close and reopen the app\n3. **Check internet**: Ensure stable connection\n4. **Pull to refresh**: On home screen, pull down to refresh\n\n⚠️ Still not working? Screenshot your payment confirmation and contact support.',
    keywords: ['activate', 'activation', 'locked', 'paid', 'access', 'unlock', 'purchased', 'bought'],
    patterns: ['quiz not activated', 'paid but locked', 'not unlocked', 'cant access after payment', 'purchased but locked'],
    category: 'payment',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },

  // ========== QUIZ (5 solutions) ==========
  {
    title: 'How to Start a Quiz',
    description: '📝 **Starting a Quiz:**\n\n1. **Find exam**: Browse Home screen or use search\n2. **View details**: Tap on exam card\n3. **Read instructions**: Check time limit, question count\n4. **Start quiz**: Tap "Start Quiz" button\n5. **Answer questions**: Select options and navigate\n\n💡 Tip: You can review answers before submitting!',
    keywords: ['start', 'begin', 'quiz', 'attempt', 'take', 'play', 'initiate', 'launch'],
    patterns: ['start quiz', 'how to start', 'begin quiz', 'take quiz', 'attempt quiz'],
    category: 'quiz',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Quiz Time Limit',
    description: '⏱️ **Quiz Time Limits:**\n\n• Time limit is shown on quiz instruction page\n• Timer starts when you click "Start Quiz"\n• Timer is visible at top of quiz screen\n• Quiz auto-submits when time runs out\n\n⚠️ **Important**: You cannot pause the timer once started. Make sure you have enough time before starting!',
    keywords: ['time', 'limit', 'timer', 'duration', 'minutes', 'hours', 'long', 'expire', 'timeout'],
    patterns: ['time limit', 'how much time', 'quiz duration', 'timer', 'how long'],
    category: 'quiz',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Free Questions in Quiz',
    description: '🆓 **Free Questions (Freemium Model):**\n\n• First 5 questions are FREE in all quizzes\n• Remaining questions require payment\n• View free questions to evaluate quality\n• Purchase to unlock full quiz\n\n💡 This lets you try before you buy!',
    keywords: ['free', 'questions', 'freemium', 'trial', 'sample', 'limited', 'five', '5'],
    patterns: ['free questions', 'how many free', 'freemium', 'try before buy', 'free trial'],
    category: 'quiz',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Navigate Questions in Quiz',
    description: '🔀 **Navigating During Quiz:**\n\n• **Next/Previous**: Use arrow buttons at bottom\n• **Jump to question**: Tap question number in grid\n• **Mark for review**: Flag questions to revisit\n• **Question status**: Green (answered), Red (unanswered)\n\n📌 You can change answers anytime before submitting!',
    keywords: ['navigate', 'next', 'previous', 'jump', 'question', 'skip', 'move', 'switch'],
    patterns: ['navigate questions', 'next question', 'skip question', 'go back', 'change answer'],
    category: 'quiz',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Submit Quiz',
    description: '✅ **Submitting Your Quiz:**\n\n1. **Finish answering**: Complete all questions or mark for later\n2. **Review**: Click "Review" to check your answers\n3. **Submit**: Click "Submit Quiz" button\n4. **Confirm**: Confirm submission in the popup\n\n⚠️ Once submitted, you cannot change answers. Review carefully!',
    keywords: ['submit', 'finish', 'complete', 'end', 'done', 'final', 'confirm'],
    patterns: ['submit quiz', 'finish quiz', 'complete quiz', 'how to submit', 'end quiz'],
    category: 'quiz',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },

  // ========== ACCOUNT (5 solutions) ==========
  {
    title: 'Login Issues',
    description: '🔐 **Cannot Login?**\n\n1. **Check phone number**: Ensure correct number with country code\n2. **OTP not received**: Wait 60 seconds, then resend\n3. **OTP expired**: Request a new OTP\n4. **Network issue**: Check your internet connection\n5. **Try later**: Server might be busy, try after few minutes\n\n📱 Make sure SMS permissions are enabled!',
    keywords: ['login', 'signin', 'sign', 'otp', 'access', 'enter', 'authenticate', 'verification'],
    patterns: ['cannot login', 'login problem', 'otp not received', 'login failed', 'cant sign in'],
    category: 'account',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Change Phone Number',
    description: '📱 **Change Registered Phone Number:**\n\nTo update your phone number:\n\n1. **Email support**: accounts@mcqquiz.com\n2. **Include**: Old number, New number, Reason\n3. **Verification**: We\'ll verify ownership\n4. **Processing**: 24-48 hours after verification\n\n⚠️ Your quiz purchases will be transferred to the new number.',
    keywords: ['change', 'phone', 'number', 'mobile', 'update', 'new', 'transfer', 'different'],
    patterns: ['change phone', 'update number', 'new phone number', 'change mobile', 'transfer account'],
    category: 'account',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Account Registered on Another Device',
    description: '📲 **Device Verification Error:**\n\nThis means your account is linked to a different device.\n\n**Solutions:**\n1. Use your original device to login\n2. If you changed phones, email: accounts@mcqquiz.com\n3. Include: Phone number, Old device info, New device info\n\n🔒 This is a security feature to prevent unauthorized access.',
    keywords: ['device', 'another', 'different', 'registered', 'linked', 'new', 'phone', 'verification'],
    patterns: ['another device', 'different device', 'device error', 'registered on another', 'new phone'],
    category: 'account',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Delete Account',
    description: '🗑️ **Delete Your Account:**\n\nTo permanently delete your account:\n\n1. **Email**: accounts@mcqquiz.com\n2. **Subject**: "Account Deletion Request"\n3. **Include**: Registered phone number\n4. **Processing**: Within 7 days\n\n⚠️ **Warning**: This action is irreversible! All quiz history and purchases will be lost.',
    keywords: ['delete', 'remove', 'close', 'account', 'terminate', 'deactivate', 'permanent'],
    patterns: ['delete account', 'remove account', 'close account', 'delete my data', 'deactivate account'],
    category: 'account',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Update Profile Information',
    description: '👤 **Update Your Profile:**\n\n1. Go to **Profile** tab\n2. Tap **Edit Profile** button\n3. Update your name, email, or photo\n4. Tap **Save** to confirm changes\n\n💡 Some information like phone number cannot be changed directly for security reasons.',
    keywords: ['profile', 'update', 'edit', 'name', 'email', 'photo', 'picture', 'information'],
    patterns: ['update profile', 'edit profile', 'change name', 'update email', 'profile picture'],
    category: 'account',
    priority: 6,
    isActive: true,
    triggerCount: 0,
  },

  // ========== TECHNICAL (5 solutions) ==========
  {
    title: 'App Crash / Force Close',
    description: '💥 **App Crashing?**\n\nTry these fixes:\n\n1. **Force close**: Close app completely and reopen\n2. **Clear cache**: Settings → Apps → MCQ Quiz → Clear Cache\n3. **Update app**: Check Play Store/App Store for updates\n4. **Restart phone**: Sometimes a restart helps\n5. **Reinstall**: Uninstall and reinstall app\n\n📧 If issue persists, email: tech@mcqquiz.com with device details.',
    keywords: ['crash', 'close', 'force', 'stop', 'freeze', 'hang', 'stuck', 'not', 'opening'],
    patterns: ['app crashes', 'app closing', 'force close', 'app freezes', 'app not opening'],
    category: 'technical',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Slow Loading / Performance Issues',
    description: '🐌 **App Running Slow?**\n\n**Quick fixes:**\n1. Check your internet speed\n2. Close other apps running in background\n3. Clear app cache\n4. Ensure enough storage space (500MB+)\n5. Update to latest app version\n\n📶 For best experience, use WiFi or strong 4G/5G connection.',
    keywords: ['slow', 'loading', 'lag', 'speed', 'performance', 'buffer', 'taking', 'time'],
    patterns: ['app slow', 'loading slow', 'takes too long', 'very slow', 'performance issue'],
    category: 'technical',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Images Not Loading',
    description: '🖼️ **Images Not Displaying?**\n\n1. **Check internet**: Ensure stable connection\n2. **Wait**: Some images take time to load\n3. **Pull to refresh**: Refresh the current page\n4. **Clear cache**: Clear app cache and retry\n5. **Update app**: Get latest version\n\n💡 Questions with images require more bandwidth.',
    keywords: ['image', 'picture', 'photo', 'loading', 'display', 'show', 'blank', 'missing'],
    patterns: ['image not loading', 'pictures not showing', 'cant see images', 'blank images', 'images missing'],
    category: 'technical',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Network / Connection Error',
    description: '🌐 **Connection Problems?**\n\n1. **Check internet**: Try opening a website in browser\n2. **Switch network**: Try WiFi or mobile data\n3. **Restart router**: If on WiFi, restart your router\n4. **Airplane mode**: Toggle airplane mode on/off\n5. **Wait**: Server might be under maintenance\n\n⏰ If widespread, check our social media for updates.',
    keywords: ['network', 'connection', 'internet', 'offline', 'error', 'connect', 'wifi', 'data'],
    patterns: ['network error', 'no connection', 'cant connect', 'internet problem', 'connection failed'],
    category: 'technical',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Bug Report',
    description: '🐛 **Found a Bug?**\n\nThank you for reporting! Please email:\n📧 bugs@mcqquiz.com\n\n**Include:**\n• Device model and OS version\n• App version (Settings → About)\n• Steps to reproduce the bug\n• Screenshots or screen recording\n\nWe fix bugs in priority order. Thank you! 🙏',
    keywords: ['bug', 'issue', 'problem', 'error', 'wrong', 'broken', 'report', 'glitch'],
    patterns: ['report bug', 'found bug', 'something wrong', 'bug report', 'app bug'],
    category: 'technical',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Review Answers After Quiz',
    description: '📖 **Review Your Answers:**\n\nAfter submitting a quiz:\n\n1. You\'ll see the result page\n2. Tap **"Review Answers"**\n3. See correct answers with explanations\n4. Green = Correct, Red = Wrong\n\n📚 Use this to learn from your mistakes!',
    keywords: ['review', 'answers', 'explanation', 'correct', 'wrong', 'solution', 'check'],
    patterns: ['review answers', 'see correct answers', 'check answers', 'view solutions', 'answer explanation'],
    category: 'exam',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Quiz Difficulty Levels',
    description: '📊 **Difficulty Levels:**\n\n• **Easy** 🟢 - Basic concepts, ideal for beginners\n• **Medium** 🟡 - Intermediate, good for practice\n• **Hard** 🔴 - Advanced, exam-level difficulty\n\n💡 Start with Easy and progress to Hard for best learning!',
    keywords: ['difficulty', 'level', 'easy', 'medium', 'hard', 'tough', 'simple', 'advanced'],
    patterns: ['difficulty level', 'how hard', 'easy quiz', 'hard quiz', 'quiz levels'],
    category: 'exam',
    priority: 6,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'View Quiz Results',
    description: '📊 **View Your Results:**\n\n1. Go to **Profile** tab\n2. Tap **Quiz History**\n3. Select the quiz to view details\n4. See: Score, correct/incorrect answers, time taken\n\n📈 Track your progress over time with our analytics!',
    keywords: ['result', 'score', 'marks', 'view', 'check', 'see', 'performance', 'history'],
    patterns: ['view results', 'check score', 'my results', 'quiz result', 'see marks'],
    category: 'exam',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Retake Quiz',
    description: '🔄 **Retake a Quiz:**\n\n• **Free quizzes**: Unlimited retakes\n• **Paid quizzes**: Retakes based on your purchase\n• **Practice mode**: Some quizzes offer practice mode\n\n**How to retake:**\n1. Go to Quiz History\n2. Find the quiz\n3. Tap "Retake Quiz"\n\n💡 Retaking helps improve your score!',
    keywords: ['retake', 'again', 'repeat', 'redo', 'restart', 'another', 'attempt', 'retry'],
    patterns: ['retake quiz', 'take again', 'retry quiz', 'repeat quiz', 'another attempt'],
    category: 'exam',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Quiz Scoring System',
    description: '📐 **How Scoring Works:**\n\n• **Correct answer**: +1 point (or as mentioned)\n• **Wrong answer**: 0 or negative marking (quiz-specific)\n• **Unanswered**: No points\n• **Total score**: Sum of all correct answers\n• **Percentage**: (Your score / Total marks) × 100\n\n📝 Check quiz instructions for specific marking scheme.',
    keywords: ['score', 'scoring', 'marks', 'marking', 'calculate', 'points', 'system', 'negative'],
    patterns: ['how scoring works', 'negative marking', 'scoring system', 'how marks calculated', 'point system'],
    category: 'exam',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },

  // ========== SUBSCRIPTION (5 solutions) ==========
  {
    title: 'Premium Features',
    description: '⭐ **Premium Benefits:**\n\n• **Unlimited access**: All quizzes unlocked\n• **Ad-free**: No interruptions\n• **Detailed analytics**: Track performance\n• **Priority support**: Faster responses\n• **Exclusive content**: Premium-only quizzes\n\n💎 Upgrade from Profile → Premium section!',
    keywords: ['premium', 'features', 'benefits', 'paid', 'pro', 'vip', 'exclusive', 'upgrade'],
    patterns: ['premium features', 'what is premium', 'premium benefits', 'why upgrade', 'premium advantages'],
    category: 'subscription',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Subscription Plans & Pricing',
    description: '💰 **Our Plans:**\n\n• **Per Quiz**: Pay only for quizzes you need\n• **Monthly**: ₹199/month - All quizzes\n• **Yearly**: ₹999/year - Best value (58% off)\n\n**What\'s included:**\n- Full quiz access\n- Detailed explanations\n- Performance analytics\n\n👉 View plans: Profile → Subscription',
    keywords: ['plan', 'pricing', 'price', 'cost', 'subscription', 'monthly', 'yearly', 'annual'],
    patterns: ['subscription plans', 'how much', 'pricing', 'subscription cost', 'plan prices'],
    category: 'subscription',
    priority: 9,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Cancel Subscription',
    description: '❌ **Cancel Subscription:**\n\n1. Go to **Profile** → **Subscription**\n2. Tap **"Manage Subscription"**\n3. Select **"Cancel Subscription"**\n4. Confirm cancellation\n\n📝 **Note**: Access continues until subscription period ends. No partial refunds.',
    keywords: ['cancel', 'subscription', 'stop', 'unsubscribe', 'end', 'terminate', 'discontinue'],
    patterns: ['cancel subscription', 'stop subscription', 'unsubscribe', 'end subscription', 'cancel premium'],
    category: 'subscription',
    priority: 8,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Subscription Not Working',
    description: '⚠️ **Subscription Issues?**\n\nIf premium features aren\'t available:\n\n1. **Verify payment**: Check bank statement\n2. **Restart app**: Force close and reopen\n3. **Restore purchase**: Profile → Subscription → Restore\n4. **Check expiry**: Your plan might have expired\n\n📧 Still issues? Email: subscriptions@mcqquiz.com',
    keywords: ['subscription', 'not', 'working', 'premium', 'access', 'locked', 'issue', 'problem'],
    patterns: ['subscription not working', 'premium not active', 'still locked', 'subscription problem', 'cant access premium'],
    category: 'subscription',
    priority: 10,
    isActive: true,
    triggerCount: 0,
  },
  {
    title: 'Upgrade / Downgrade Plan',
    description: '🔄 **Change Your Plan:**\n\n**Upgrade:**\n1. Profile → Subscription → Change Plan\n2. Select new plan\n3. Pay difference (prorated)\n\n**Downgrade:**\n- Takes effect after current period ends\n- No partial refunds\n\n💡 Upgrade anytime, downgrade at renewal!',
    keywords: ['upgrade', 'downgrade', 'change', 'plan', 'switch', 'different', 'modify'],
    patterns: ['upgrade plan', 'downgrade plan', 'change subscription', 'switch plan', 'modify subscription'],
    category: 'subscription',
    priority: 7,
    isActive: true,
    triggerCount: 0,
  },
];

/**
 * Seed function to add all solutions to Firestore
 * Can be called from admin panel or run as a script
 */
export const seedChatbotSolutions = async (
  addDoc: (collection: any, data: any) => Promise<any>,
  collection: (db: any, name: string) => any,
  db: any,
  Timestamp: any,
  adminEmail: string
): Promise<{ success: number; failed: number }> => {
  let success = 0;
  let failed = 0;

  for (const solution of chatbotSolutions) {
    try {
      await addDoc(collection(db, 'support_solutions'), {
        ...solution,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        createdBy: adminEmail,
      });
      success++;
    } catch (error) {
      console.error(`Failed to add solution: ${solution.title}`, error);
      failed++;
    }
  }

  return { success, failed };
};

/**
 * Get solutions count by category
 */
export const getSolutionStats = (): Record<string, number> => {
  const stats: Record<string, number> = {};
  for (const solution of chatbotSolutions) {
    stats[solution.category] = (stats[solution.category] || 0) + 1;
  }
  return stats;
};

// Export total count
export const TOTAL_SOLUTIONS = chatbotSolutions.length;
