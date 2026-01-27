import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../config/firebase';

// Sample banner data
export const sampleBanners = [
  {
    title: 'SPECIAL OFFER!',
    subtitle: 'GET 30% DISCOUNT ON PREMIUM',
    couponCode: 'EXP30',
    discount: '30%',
    primaryColor: '#E91E63',
    secondaryColor: '#9C27B0',
    iconName: 'lightbulb',
    isActive: true,
    startDate: new Date(),
    endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    targetUrl: '',
    priority: 10,
    createdBy: 'admin',
  },
  {
    title: 'LIMITED TIME!',
    subtitle: 'FREE PREMIUM ACCESS FOR NEW USERS',
    couponCode: 'FREE7',
    discount: '100%',
    primaryColor: '#4CAF50',
    secondaryColor: '#8BC34A',
    iconName: 'gift',
    isActive: true,
    startDate: new Date(),
    endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
    targetUrl: '',
    priority: 5,
    createdBy: 'admin',
  },
  {
    title: 'WEEKEND SALE!',
    subtitle: 'SAVE BIG ON ALL COURSES',
    couponCode: 'WEEKEND',
    discount: '50%',
    primaryColor: '#FF5722',
    secondaryColor: '#FF9800',
    iconName: 'sale',
    isActive: false,
    startDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
    endDate: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000), // 4 days from now
    targetUrl: '',
    priority: 8,
    createdBy: 'admin',
  },
];

// Sample live test data
export const sampleLiveTests = [
  {
    title: 'IBPS RRB Officer Prelims Live Test 10',
    description: 'Comprehensive test covering all topics for IBPS RRB Officer Prelims examination',
    examType: 'IBPS RRB Officer Prelims',
    suitableFor: ['MTS', 'Postman', 'Postal Assistant'],
    startTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
    endTime: new Date(Date.now() + 4 * 60 * 60 * 1000), // 4 hours from now
    durationMinutes: 60,
    totalQuestions: 80,
    isActive: true,
    isLive: false,
    status: 'upcoming',
    maxParticipants: 1000,
    currentParticipants: 0,
    instructorName: 'Dr. Rajesh Kumar',
    instructorImage: '',
    tags: ['banking', 'prelims', 'officer'],
    difficulty: 'medium',
    passingScore: 60,
    showResults: true,
    examId: '',
    createdBy: 'admin',
  },
  {
    title: 'SBI PO Mains Mock Test',
    description: 'High-quality mock test for SBI PO Mains examination with detailed solutions',
    examType: 'SBI PO Mains',
    suitableFor: ['Inspector', 'ASP', 'SP'],
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 3 * 60 * 60 * 1000), // Tomorrow + 3 hours
    durationMinutes: 180,
    totalQuestions: 155,
    isActive: true,
    isLive: false,
    status: 'upcoming',
    maxParticipants: 500,
    currentParticipants: 0,
    instructorName: 'Prof. Anita Sharma',
    instructorImage: '',
    tags: ['banking', 'mains', 'po'],
    difficulty: 'hard',
    passingScore: 65,
    showResults: true,
    examId: '',
    createdBy: 'admin',
  },
  {
    title: 'IBPS Clerk Prelims Speed Test',
    description: 'Fast-paced test to improve speed and accuracy for IBPS Clerk Prelims',
    examType: 'IBPS Clerk Prelims',
    suitableFor: ['Postman', 'Postal Assistant', 'Others'],
    startTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
    endTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000 + 90 * 60 * 1000), // 3 days + 1.5 hours
    durationMinutes: 60,
    totalQuestions: 100,
    isActive: true,
    isLive: false,
    status: 'upcoming',
    maxParticipants: 2000,
    currentParticipants: 0,
    instructorName: 'Mr. Vikash Singh',
    instructorImage: '',
    tags: ['banking', 'prelims', 'clerk'],
    difficulty: 'easy',
    passingScore: 55,
    showResults: true,
    examId: '',
    createdBy: 'admin',
  },
];

// Function to add sample banners to Firebase
export const addSampleBanners = async () => {
  try {
    console.log('Adding sample banners...');
    
    for (const banner of sampleBanners) {
      await addDoc(collection(db, 'banners'), {
        ...banner,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    }
    
    console.log('Sample banners added successfully!');
    return true;
  } catch (error) {
    console.error('Error adding sample banners:', error);
    return false;
  }
};

// Function to add sample live tests to Firebase
// Note: Live tests are now stored as exams with isLiveTest=true
// This function is deprecated and kept for backward compatibility
export const addSampleLiveTests = async () => {
  try {
    console.log('Note: Live tests are now stored in the exams collection with isLiveTest=true');
    console.log('Sample live tests can be created through the exam management interface');
    return true;
  } catch (error) {
    console.error('Error adding sample live tests:', error);
    return false;
  }
};

// Function to add all sample data
export const addAllSampleData = async () => {
  try {
    console.log('Adding all sample data...');
    
    const bannersResult = await addSampleBanners();
    const testsResult = await addSampleLiveTests();
    
    if (bannersResult && testsResult) {
      console.log('All sample data added successfully!');
      return true;
    } else {
      console.log('Some sample data failed to add');
      return false;
    }
  } catch (error) {
    console.error('Error adding sample data:', error);
    return false;
  }
};

// Function to clear all sample data (for testing)
export const clearSampleData = async () => {
  try {
    console.log('Note: Clear function not implemented for safety');
    console.log('Please manually delete test data from Firebase console if needed');
    return true;
  } catch (error) {
    console.error('Error clearing sample data:', error);
    return false;
  }
};
