#!/usr/bin/env python3
"""
SHA-1 Fingerprint Converter for Firebase
Converts UPPERCASE SHA-1 fingerprints to lowercase format required by Firebase
"""

def convert_sha_fingerprint(sha_fingerprint):
    """Convert SHA fingerprint to lowercase format"""
    return sha_fingerprint.lower()

def main():
    print("🔧 SHA-1 Fingerprint Converter for Firebase")
    print("=" * 50)
    
    # Your current SHA-1 from the project
    current_sha1 = "08:C3:DE:0D:17:61:6F:3A:B8:DD:E2:45:12:B1:C1:44:3D:F1:FA:F5"
    
    print(f"📱 Current SHA-1 (UPPERCASE):")
    print(f"   {current_sha1}")
    print()
    
    # Convert to lowercase
    firebase_sha1 = convert_sha_fingerprint(current_sha1)
    
    print(f"🔥 Firebase SHA-1 (lowercase):")
    print(f"   {firebase_sha1}")
    print()
    
    print("📋 Copy the lowercase version above and:")
    print("1. Go to Firebase Console")
    print("2. Project Settings → Your apps → Android")
    print("3. Add the lowercase SHA-1 fingerprint")
    print("4. Download new google-services.json")
    print("5. Replace the file in mobile_app/android/app/")
    print("6. Rebuild your app")
    print()
    
    # Allow custom input
    print("🔧 Or enter your own SHA-1 fingerprint:")
    custom_sha = input("Enter SHA-1 (or press Enter to skip): ").strip()
    
    if custom_sha:
        converted = convert_sha_fingerprint(custom_sha)
        print(f"\n📱 Your SHA-1: {custom_sha}")
        print(f"🔥 For Firebase: {converted}")
    
    print("\n✅ Done! Use the lowercase version in Firebase Console.")

if __name__ == "__main__":
    main()
