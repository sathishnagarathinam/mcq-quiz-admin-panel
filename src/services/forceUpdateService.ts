import {
  doc,
  getDoc,
  setDoc,
  onSnapshot,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Force Update Configuration Interface
export interface ForceUpdateConfig {
  minRequiredVersion: string;
  isForceUpdateEnabled: boolean;
  updateMessage: string;
  playStoreUrl: string;
  lastUpdatedAt: Date | null;
  updatedBy: string | null;
}

// Firestore document structure
interface ForceUpdateConfigDoc {
  minRequiredVersion: string;
  isForceUpdateEnabled: boolean;
  updateMessage: string;
  playStoreUrl: string;
  lastUpdatedAt: Timestamp | null;
  updatedBy: string | null;
}

export class ForceUpdateService {
  private static readonly CONFIG_COLLECTION = 'app_config';
  private static readonly FORCE_UPDATE_DOC = 'force_update';

  // Default configuration
  static getDefaultConfig(): ForceUpdateConfig {
    return {
      minRequiredVersion: '1.0.0',
      isForceUpdateEnabled: false,
      updateMessage: 'A new version of the app is available. Please update to continue using the app.',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.mcqquiz1.app',
      lastUpdatedAt: null,
      updatedBy: null,
    };
  }

  // Get force update configuration
  static async getConfig(): Promise<ForceUpdateConfig> {
    try {
      const docRef = doc(db, this.CONFIG_COLLECTION, this.FORCE_UPDATE_DOC);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data() as ForceUpdateConfigDoc;
        return {
          minRequiredVersion: data.minRequiredVersion || '1.0.0',
          isForceUpdateEnabled: data.isForceUpdateEnabled ?? false,
          updateMessage: data.updateMessage || 'A new version of the app is available. Please update to continue using the app.',
          playStoreUrl: data.playStoreUrl || 'https://play.google.com/store/apps/details?id=com.mcqquiz1.app',
          lastUpdatedAt: data.lastUpdatedAt?.toDate() || null,
          updatedBy: data.updatedBy || null,
        };
      }

      // Return default config if document doesn't exist
      return this.getDefaultConfig();
    } catch (error) {
      console.error('Error fetching force update config:', error);
      throw error;
    }
  }

  // Save force update configuration
  static async saveConfig(
    config: Partial<ForceUpdateConfig>,
    updatedBy: string
  ): Promise<void> {
    try {
      const docRef = doc(db, this.CONFIG_COLLECTION, this.FORCE_UPDATE_DOC);
      
      const updateData: Partial<ForceUpdateConfigDoc> = {
        lastUpdatedAt: Timestamp.now(),
        updatedBy,
      };

      if (config.minRequiredVersion !== undefined) {
        updateData.minRequiredVersion = config.minRequiredVersion;
      }
      if (config.isForceUpdateEnabled !== undefined) {
        updateData.isForceUpdateEnabled = config.isForceUpdateEnabled;
      }
      if (config.updateMessage !== undefined) {
        updateData.updateMessage = config.updateMessage;
      }
      if (config.playStoreUrl !== undefined) {
        updateData.playStoreUrl = config.playStoreUrl;
      }

      await setDoc(docRef, updateData, { merge: true });
      console.log('Force update config saved successfully');
    } catch (error) {
      console.error('Error saving force update config:', error);
      throw error;
    }
  }

  // Subscribe to real-time updates
  static subscribeToConfig(
    callback: (config: ForceUpdateConfig) => void,
    onError?: (error: Error) => void
  ): () => void {
    const docRef = doc(db, this.CONFIG_COLLECTION, this.FORCE_UPDATE_DOC);

    return onSnapshot(
      docRef,
      (docSnap) => {
        if (docSnap.exists()) {
          const data = docSnap.data() as ForceUpdateConfigDoc;
          callback({
            minRequiredVersion: data.minRequiredVersion || '1.0.0',
            isForceUpdateEnabled: data.isForceUpdateEnabled ?? false,
            updateMessage: data.updateMessage || 'A new version of the app is available.',
            playStoreUrl: data.playStoreUrl || '',
            lastUpdatedAt: data.lastUpdatedAt?.toDate() || null,
            updatedBy: data.updatedBy || null,
          });
        } else {
          callback(this.getDefaultConfig());
        }
      },
      (error) => {
        console.error('Error subscribing to force update config:', error);
        onError?.(error);
      }
    );
  }

  // Validate version format (semantic versioning)
  static isValidVersion(version: string): boolean {
    const semverRegex = /^\d+\.\d+\.\d+$/;
    return semverRegex.test(version);
  }

  // Compare versions (returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2)
  static compareVersions(v1: string, v2: string): number {
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);

    for (let i = 0; i < 3; i++) {
      const p1 = parts1[i] || 0;
      const p2 = parts2[i] || 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }
}

