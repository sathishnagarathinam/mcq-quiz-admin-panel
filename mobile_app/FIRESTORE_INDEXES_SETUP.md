# Firestore Indexes Setup for Exam Hub

The exam hub functionality requires composite indexes in Firestore to support queries with multiple conditions and ordering. Follow these steps to create the required indexes.

## Required Indexes

### 1. News Collection (`exam_hub_news`)
**Fields:**
- `isActive` (Ascending)
- `publishDate` (Descending)

**Index Creation URL:**
```
https://console.firebase.google.com/project/mcq-quiz-system/firestore/indexes?create_composite=CIVwAm9qZWNOcy9tY3EtcXVpeilzeXNOZWOVZGFOYWJhc2VzLyhkZWZhdWx0Ks9jb2xsZWNQaW9uR3JVdXBzL2V4YWfaHViX25|d3MvaW5kZXh|cy9fEAEaDAo|aXNBY3RpdmUQARoPCgtwdWJsaXNoRGFOZRACGgwKCF9fbmFtZV9fEAI
```

### 2. Tips Collection (`exam_hub_tips`)
**Fields:**
- `isActive` (Ascending)
- `createdAt` (Descending)

### 3. Papers Collection (`exam_hub_papers`)
**Fields:**
- `isActive` (Ascending)
- `examDate` (Descending)

### 4. Results Collection (`exam_hub_results`)
**Fields:**
- `isActive` (Ascending)
- `publishDate` (Descending)

## Manual Index Creation Steps

If the automatic URLs don't work, you can create indexes manually:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mcq-quiz-system`
3. Navigate to **Firestore Database** → **Indexes**
4. Click **Create Index**
5. For each collection, create a composite index with:
   - Collection ID: `exam_hub_news` (or respective collection)
   - Fields:
     - Field: `isActive`, Order: `Ascending`
     - Field: `publishDate` (or respective date field), Order: `Descending`
6. Click **Create**

## Index Status

After creating indexes, they may take a few minutes to build. You can check the status in the Firebase Console under Firestore → Indexes.

## Fallback Behavior

The mobile app has been updated with fallback behavior:
- If compound queries fail due to missing indexes, it will use simple queries
- Results will be sorted manually in the app
- This ensures the app works even without indexes (though with slightly reduced performance)

## Testing

Once indexes are created:
1. Test the exam hub screens in the mobile app
2. Verify that data loads correctly
3. Check that sorting works as expected

## Troubleshooting

If you encounter issues:
1. Check that all required indexes are created and built
2. Verify collection names match exactly
3. Ensure field names are correct (case-sensitive)
4. Check Firebase Console for any error messages

## Performance Notes

- With indexes: Queries are fast and efficient
- Without indexes: Queries work but may be slower for large datasets
- The app gracefully handles both scenarios
