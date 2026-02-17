import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  Timestamp,
  increment,
  DocumentSnapshot,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import {
  ExamHubNews,
  ExamHubTips,
  ExamHubPapers,
  ExamHubResults,
  NewsFormData,
  TipsFormData,
  PapersFormData,
  ResultsFormData,
  ExamHubSearchParams,
  FileAttachment,
} from '../types/examHub';
import { FileUploadService } from './fileUploadService';

// Collection names
const COLLECTIONS = {
  NEWS: 'exam_hub_news',
  TIPS: 'exam_hub_tips',
  PAPERS: 'exam_hub_papers',
  RESULTS: 'exam_hub_results',
} as const;

export class ExamHubService {
  // ==================== STANDALONE FILE OPERATIONS ====================

  /**
   * Save uploaded file as a standalone document (for immediate visibility)
   */
  static async saveUploadedFile(
    attachment: FileAttachment,
    category: 'news' | 'tips' | 'papers' | 'results',
    createdBy: string,
    metadata?: {
      title?: string;
      description?: string;
      examType?: string;
      examYear?: number;
    }
  ): Promise<string> {
    try {
      const collectionName = COLLECTIONS[category.toUpperCase() as keyof typeof COLLECTIONS];

      // Create a basic document structure based on category
      let documentData: any = {
        title: metadata?.title || attachment.originalName || attachment.name,
        description: metadata?.description || `Uploaded file: ${attachment.originalName || attachment.name}`,
        attachments: [attachment],
        isActive: true,
        priority: 0,
        createdBy,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        tags: [],
        viewCount: 0,
        downloadCount: 0,
      };

      // Add category-specific fields
      switch (category) {
        case 'news':
          documentData = {
            ...documentData,
            publishDate: Timestamp.now(),
            category: 'general',
            isUrgent: false,
            isPublic: true,
          };
          break;

        case 'tips':
          documentData = {
            ...documentData,
            category: 'study_tips',
            difficulty: 'beginner',
            estimatedReadTime: 5,
            relatedExamTypes: [],
            isVideoContent: false,
          };
          break;

        case 'papers':
          documentData = {
            ...documentData,
            examType: metadata?.examType || 'OTHER',
            examYear: metadata?.examYear || new Date().getFullYear(),
            examDate: Timestamp.now(),
            paperType: 'question_paper',
            duration: 120,
            totalMarks: 100,
            totalQuestions: 100,
            language: ['English'],
            isOfficial: false,
          };
          break;

        case 'results':
          documentData = {
            ...documentData,
            examType: metadata?.examType || 'OTHER',
            examYear: metadata?.examYear || new Date().getFullYear(),
            resultType: 'final_result',
            publishDate: Timestamp.now(),
            examDate: Timestamp.now(),
            isOfficial: false,
          };
          break;
      }

      const docRef = await addDoc(collection(db, collectionName), documentData);
      console.log(`Saved uploaded file as ${category} document:`, docRef.id);
      return docRef.id;
    } catch (error) {
      console.error(`Error saving uploaded file as ${category}:`, error);
      throw new Error(`Failed to save uploaded file as ${category}`);
    }
  }

  // ==================== NEWS OPERATIONS ====================

  /**
   * Create a new news item
   */
  static async createNews(
    formData: NewsFormData,
    attachments: FileAttachment[],
    createdBy: string
  ): Promise<string> {
    try {
      const newsData: Omit<ExamHubNews, 'id'> = {
        ...formData,
        publishDate: Timestamp.fromDate(formData.publishDate),
        expiryDate: formData.expiryDate ? Timestamp.fromDate(formData.expiryDate) : undefined,
        attachments,
        viewCount: 0,
        downloadCount: 0,
        createdBy,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      const docRef = await addDoc(collection(db, COLLECTIONS.NEWS), newsData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating news:', error);
      throw new Error('Failed to create news item');
    }
  }

  /**
   * Update news item
   */
  static async updateNews(
    id: string,
    formData: NewsFormData,
    attachments: FileAttachment[]
  ): Promise<void> {
    try {
      const updateData = {
        ...formData,
        publishDate: Timestamp.fromDate(formData.publishDate),
        expiryDate: formData.expiryDate ? Timestamp.fromDate(formData.expiryDate) : undefined,
        attachments,
        updatedAt: Timestamp.now(),
      };

      await updateDoc(doc(db, COLLECTIONS.NEWS, id), updateData);
    } catch (error) {
      console.error('Error updating news:', error);
      throw new Error('Failed to update news item');
    }
  }

  /**
   * Delete news item
   */
  static async deleteNews(id: string): Promise<void> {
    try {
      // Get the news item to delete its attachments
      const newsDoc = await getDoc(doc(db, COLLECTIONS.NEWS, id));
      if (newsDoc.exists()) {
        const newsData = newsDoc.data() as ExamHubNews;
        if (newsData.attachments?.length > 0) {
          await FileUploadService.deleteMultipleFiles(newsData.attachments);
        }
      }

      await deleteDoc(doc(db, COLLECTIONS.NEWS, id));
    } catch (error) {
      console.error('Error deleting news:', error);
      throw new Error('Failed to delete news item');
    }
  }

  /**
   * Get all news items
   */
  static async getAllNews(searchParams?: ExamHubSearchParams): Promise<ExamHubNews[]> {
    try {
      let q = query(collection(db, COLLECTIONS.NEWS));

      // Apply filters
      if (searchParams?.filters) {
        const { filters } = searchParams;
        if (filters.category) {
          q = query(q, where('category', '==', filters.category));
        }
        if (filters.isActive !== undefined) {
          q = query(q, where('isActive', '==', filters.isActive));
        }
      }

      // Apply sorting
      const sortBy = searchParams?.sortBy || 'createdAt';
      const sortOrder = searchParams?.sortOrder || 'desc';
      q = query(q, orderBy(sortBy, sortOrder));

      // Apply limit
      if (searchParams?.limit) {
        q = query(q, limit(searchParams.limit));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as ExamHubNews[];
    } catch (error) {
      console.error('Error getting news:', error);
      throw new Error('Failed to fetch news items');
    }
  }

  /**
   * Get news item by ID
   */
  static async getNewsById(id: string): Promise<ExamHubNews | null> {
    try {
      const docSnap = await getDoc(doc(db, COLLECTIONS.NEWS, id));
      if (docSnap.exists()) {
        return {
          id: docSnap.id,
          ...docSnap.data(),
        } as ExamHubNews;
      }
      return null;
    } catch (error) {
      console.error('Error getting news by ID:', error);
      throw new Error('Failed to fetch news item');
    }
  }

  // ==================== TIPS OPERATIONS ====================

  /**
   * Create a new tips item
   */
  static async createTips(
    formData: TipsFormData,
    attachments: FileAttachment[],
    createdBy: string
  ): Promise<string> {
    try {
      const tipsData: Omit<ExamHubTips, 'id'> = {
        ...formData,
        attachments,
        viewCount: 0,
        downloadCount: 0,
        createdBy,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      const docRef = await addDoc(collection(db, COLLECTIONS.TIPS), tipsData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating tips:', error);
      throw new Error('Failed to create tips item');
    }
  }

  /**
   * Update tips item
   */
  static async updateTips(
    id: string,
    formData: TipsFormData,
    attachments: FileAttachment[]
  ): Promise<void> {
    try {
      const updateData = {
        ...formData,
        attachments,
        updatedAt: Timestamp.now(),
      };

      await updateDoc(doc(db, COLLECTIONS.TIPS, id), updateData);
    } catch (error) {
      console.error('Error updating tips:', error);
      throw new Error('Failed to update tips item');
    }
  }

  /**
   * Delete tips item
   */
  static async deleteTips(id: string): Promise<void> {
    try {
      const tipsDoc = await getDoc(doc(db, COLLECTIONS.TIPS, id));
      if (tipsDoc.exists()) {
        const tipsData = tipsDoc.data() as ExamHubTips;
        if (tipsData.attachments?.length > 0) {
          await FileUploadService.deleteMultipleFiles(tipsData.attachments);
        }
      }

      await deleteDoc(doc(db, COLLECTIONS.TIPS, id));
    } catch (error) {
      console.error('Error deleting tips:', error);
      throw new Error('Failed to delete tips item');
    }
  }

  /**
   * Get all tips items
   */
  static async getAllTips(searchParams?: ExamHubSearchParams): Promise<ExamHubTips[]> {
    try {
      let q = query(collection(db, COLLECTIONS.TIPS));

      if (searchParams?.filters) {
        const { filters } = searchParams;
        if (filters.category) {
          q = query(q, where('category', '==', filters.category));
        }
        if (filters.isActive !== undefined) {
          q = query(q, where('isActive', '==', filters.isActive));
        }
      }

      const sortBy = searchParams?.sortBy || 'createdAt';
      const sortOrder = searchParams?.sortOrder || 'desc';
      q = query(q, orderBy(sortBy, sortOrder));

      if (searchParams?.limit) {
        q = query(q, limit(searchParams.limit));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as ExamHubTips[];
    } catch (error) {
      console.error('Error getting tips:', error);
      throw new Error('Failed to fetch tips items');
    }
  }

  // ==================== PAPERS OPERATIONS ====================

  /**
   * Create a new papers item
   */
  static async createPapers(
    formData: PapersFormData,
    attachments: FileAttachment[],
    createdBy: string
  ): Promise<string> {
    try {
      const papersData: Omit<ExamHubPapers, 'id'> = {
        ...formData,
        examDate: Timestamp.fromDate(formData.examDate),
        attachments,
        viewCount: 0,
        downloadCount: 0,
        createdBy,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      const docRef = await addDoc(collection(db, COLLECTIONS.PAPERS), papersData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating papers:', error);
      throw new Error('Failed to create papers item');
    }
  }

  /**
   * Update papers item
   */
  static async updatePapers(
    id: string,
    formData: PapersFormData,
    attachments: FileAttachment[]
  ): Promise<void> {
    try {
      const updateData = {
        ...formData,
        examDate: Timestamp.fromDate(formData.examDate),
        attachments,
        updatedAt: Timestamp.now(),
      };

      await updateDoc(doc(db, COLLECTIONS.PAPERS, id), updateData);
    } catch (error) {
      console.error('Error updating papers:', error);
      throw new Error('Failed to update papers item');
    }
  }

  /**
   * Delete papers item
   */
  static async deletePapers(id: string): Promise<void> {
    try {
      const papersDoc = await getDoc(doc(db, COLLECTIONS.PAPERS, id));
      if (papersDoc.exists()) {
        const papersData = papersDoc.data() as ExamHubPapers;
        if (papersData.attachments?.length > 0) {
          await FileUploadService.deleteMultipleFiles(papersData.attachments);
        }
      }

      await deleteDoc(doc(db, COLLECTIONS.PAPERS, id));
    } catch (error) {
      console.error('Error deleting papers:', error);
      throw new Error('Failed to delete papers item');
    }
  }

  /**
   * Get all papers items
   */
  static async getAllPapers(searchParams?: ExamHubSearchParams): Promise<ExamHubPapers[]> {
    try {
      let q = query(collection(db, COLLECTIONS.PAPERS));

      if (searchParams?.filters) {
        const { filters } = searchParams;
        if (filters.examType) {
          q = query(q, where('examType', '==', filters.examType));
        }
        if (filters.year) {
          q = query(q, where('examYear', '==', filters.year));
        }
        if (filters.isActive !== undefined) {
          q = query(q, where('isActive', '==', filters.isActive));
        }
      }

      const sortBy = searchParams?.sortBy || 'examDate';
      const sortOrder = searchParams?.sortOrder || 'desc';
      q = query(q, orderBy(sortBy, sortOrder));

      if (searchParams?.limit) {
        q = query(q, limit(searchParams.limit));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as ExamHubPapers[];
    } catch (error) {
      console.error('Error getting papers:', error);
      throw new Error('Failed to fetch papers items');
    }
  }

  // ==================== RESULTS OPERATIONS ====================

  /**
   * Create a new results item
   */
  static async createResults(
    formData: ResultsFormData,
    attachments: FileAttachment[],
    createdBy: string
  ): Promise<string> {
    try {
      const resultsData: Omit<ExamHubResults, 'id'> = {
        ...formData,
        publishDate: Timestamp.fromDate(formData.publishDate),
        examDate: Timestamp.fromDate(formData.examDate),
        attachments,
        viewCount: 0,
        downloadCount: 0,
        createdBy,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };

      const docRef = await addDoc(collection(db, COLLECTIONS.RESULTS), resultsData);
      return docRef.id;
    } catch (error) {
      console.error('Error creating results:', error);
      throw new Error('Failed to create results item');
    }
  }

  /**
   * Update results item
   */
  static async updateResults(
    id: string,
    formData: ResultsFormData,
    attachments: FileAttachment[]
  ): Promise<void> {
    try {
      const updateData = {
        ...formData,
        publishDate: Timestamp.fromDate(formData.publishDate),
        examDate: Timestamp.fromDate(formData.examDate),
        attachments,
        updatedAt: Timestamp.now(),
      };

      await updateDoc(doc(db, COLLECTIONS.RESULTS, id), updateData);
    } catch (error) {
      console.error('Error updating results:', error);
      throw new Error('Failed to update results item');
    }
  }

  /**
   * Delete results item
   */
  static async deleteResults(id: string): Promise<void> {
    try {
      const resultsDoc = await getDoc(doc(db, COLLECTIONS.RESULTS, id));
      if (resultsDoc.exists()) {
        const resultsData = resultsDoc.data() as ExamHubResults;
        if (resultsData.attachments?.length > 0) {
          await FileUploadService.deleteMultipleFiles(resultsData.attachments);
        }
      }

      await deleteDoc(doc(db, COLLECTIONS.RESULTS, id));
    } catch (error) {
      console.error('Error deleting results:', error);
      throw new Error('Failed to delete results item');
    }
  }

  /**
   * Get all results items
   */
  static async getAllResults(searchParams?: ExamHubSearchParams): Promise<ExamHubResults[]> {
    try {
      let q = query(collection(db, COLLECTIONS.RESULTS));

      if (searchParams?.filters) {
        const { filters } = searchParams;
        if (filters.examType) {
          q = query(q, where('examType', '==', filters.examType));
        }
        if (filters.year) {
          q = query(q, where('examYear', '==', filters.year));
        }
        if (filters.isActive !== undefined) {
          q = query(q, where('isActive', '==', filters.isActive));
        }
      }

      const sortBy = searchParams?.sortBy || 'publishDate';
      const sortOrder = searchParams?.sortOrder || 'desc';
      q = query(q, orderBy(sortBy, sortOrder));

      if (searchParams?.limit) {
        q = query(q, limit(searchParams.limit));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as ExamHubResults[];
    } catch (error) {
      console.error('Error getting results:', error);
      throw new Error('Failed to fetch results items');
    }
  }

  // ==================== COMMON OPERATIONS ====================

  /**
   * Increment view count for any item
   */
  static async incrementViewCount(collection: string, id: string): Promise<void> {
    try {
      await updateDoc(doc(db, collection, id), {
        viewCount: increment(1),
      });
    } catch (error) {
      console.error('Error incrementing view count:', error);
    }
  }

  /**
   * Increment download count for any item
   */
  static async incrementDownloadCount(collection: string, id: string): Promise<void> {
    try {
      await updateDoc(doc(db, collection, id), {
        downloadCount: increment(1),
      });
    } catch (error) {
      console.error('Error incrementing download count:', error);
    }
  }
}

export default ExamHubService;
