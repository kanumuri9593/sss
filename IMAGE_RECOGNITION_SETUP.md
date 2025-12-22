# Image Recognition Feature - Setup and Testing Guide

## Overview

The image recognition feature has been successfully enabled in the app. It uses Google ML Kit for on-device image labeling to automatically suggest tags when users add photos to items.

## Status: ✅ ENABLED

The previously disabled `google_mlkit_image_labeling` package has been re-enabled and fully integrated.

## What Changed

### 1. Dependencies Updated
- **File:** `pubspec.yaml`
- **Change:** Enabled `google_mlkit_image_labeling: ^0.14.1`
- **Compatibility:** Works with `mobile_scanner: ^5.2.3` (no conflicts)

### 2. Service Implementation Restored
- **File:** `lib/services/image_recognition_service.dart`
- **Status:** Fully functional with all methods uncommented
- **Features:**
  - On-device image processing
  - Tag suggestions with 50% confidence threshold
  - Automatic tag formatting (lowercase, hyphens for spaces)
  - Top N suggestions with confidence sorting

### 3. Integration Points
- **Initialization:** `lib/main.dart` - Service initialized on app startup
- **Usage:** `lib/screens/item_create_screen.dart` - Auto-tagging when photos are added
- **Search:** `lib/screens/search_screen.dart` - Image-based search functionality

## How It Works

### Tag Suggestion Flow

```
User adds photo to item
    ↓
Photo saved to app directory
    ↓
ImageRecognitionService.getTopTagSuggestions(path, 10)
    ↓
ML Kit processes image (1-3 seconds)
    ↓
Returns labels with confidence > 50%
    ↓
Labels formatted as tags (e.g., "Winter Jacket" → "winter-jacket")
    ↓
Top 10 suggestions displayed to user
    ↓
User can accept/reject suggestions
```

### Key Methods

**`ImageRecognitionService.initialize()`**
- Initializes the ML Kit image labeler
- Called automatically in main.dart on app startup
- Sets confidence threshold to 0.5 (50%)

**`ImageRecognitionService.processImage(imagePath)`**
- Processes an image and returns tag suggestions
- Returns: `List<String>` of formatted tags

**`ImageRecognitionService.getTopTagSuggestions(imagePath, topN)`**
- Gets the top N most confident tag suggestions
- Sorted by confidence score (highest first)
- Used by ItemCreateScreen (topN = 10)

**`ImageRecognitionService.processImageDetailed(imagePath)`**
- Returns detailed labels with confidence scores
- Returns: `List<ImageLabel>` with label text and confidence

## Testing the Feature

### Prerequisites
1. Run `flutter pub get` to install dependencies
2. For iOS: Run `cd ios && pod install` to install native dependencies
3. Build and run the app on a physical device (camera access required)

### Test Steps

#### Test 1: Manual Tag Suggestions
1. Open the app
2. Navigate to a container
3. Tap "+" to create a new item
4. Tap "Add Photo" and take a picture of an object (e.g., jacket, book, toy)
5. Wait 1-3 seconds for processing
6. **Expected:** Tag suggestions appear below the tags field
7. **Expected:** If tags field is empty, top 5 suggestions auto-fill
8. Tap on suggestion chips to add/remove tags
9. Save the item

#### Test 2: Tag Suggestion Dialog
1. Create an item with existing tags (e.g., "winter")
2. Add a photo
3. **Expected:** Dialog appears with suggested tags
4. **Expected:** Existing tags are marked as selected
5. Tap suggestions to toggle them on/off
6. Verify tags are updated in the tags field

#### Test 3: Image-Based Search
1. Go to Search tab
2. Tap the camera icon in the search bar
3. Take a photo of an item
4. **Expected:** Tags extracted from image appear in search field
5. **Expected:** Search results show items/containers matching those tags

#### Test 4: Multiple Images
1. Create an item and add first photo
2. Note the suggested tags
3. Add a second photo of a different object
4. **Expected:** New suggestions appear for the second image
5. **Expected:** Can add tags from both sets of suggestions

### Expected Behavior

**Processing Indicators:**
- "Processing image..." text appears while ML Kit analyzes
- Circular progress indicator shows during processing
- UI remains responsive (processing is async)

**Tag Quality:**
- Common objects: High accuracy (e.g., "clothing", "book", "toy")
- Specific items: Generic tags (e.g., "winter-jacket" might return "clothing", "outerwear")
- Minimum 50% confidence threshold filters out low-quality suggestions

**Auto-Fill Logic:**
- If tags field is **empty**: Top 5 suggestions auto-fill
- If tags field has **existing tags**: Dialog shows suggestions for manual selection
- Prevents overwriting user's manual tags

## Troubleshooting

### Issue: "Image recognition disabled" in logs
**Solution:** Run `flutter pub get` to install the dependency

### Issue: No tags suggested
**Possible causes:**
1. Image doesn't contain recognizable objects
2. Objects have confidence < 50%
3. Image file not found or corrupted

**Debug:** Check logs for `[ImageRecognition]` messages

### Issue: iOS build fails
**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Issue: Android build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter build apk
```

## Performance Notes

- **Processing Time:** 1-3 seconds per image on modern devices
- **Network:** No network required (on-device processing)
- **Cost:** Free (no API calls)
- **Privacy:** Images never leave the device
- **Battery:** Minimal impact (efficient on-device processing)

## API Reference

### ImageRecognitionService

```dart
class ImageRecognitionService {
  // Initialize the service
  static Future<void> initialize() async

  // Check if initialized
  static bool get isInitialized

  // Get tag suggestions
  static Future<List<String>> processImage(String imagePath) async

  // Get detailed labels with confidence scores
  static Future<List<ImageLabel>> processImageDetailed(String imagePath) async

  // Get top N suggestions
  static Future<List<String>> getTopTagSuggestions(String imagePath, int topN) async

  // Clean up resources
  static Future<void> close() async
}
```

### Example Usage

```dart
// In ItemCreateScreen
final suggestions = await ImageRecognitionService.getTopTagSuggestions(
  savedImagePath,
  10, // Get top 10 suggestions
);

// Auto-fill tags if empty
if (_tagsController.text.isEmpty && suggestions.isNotEmpty) {
  _tagsController.text = suggestions.take(5).join(', ');
}

// Or show dialog for manual selection
else if (_tagsController.text.isNotEmpty && suggestions.isNotEmpty) {
  _showTagSuggestions(suggestions);
}
```

## Future Enhancements

### Potential Improvements
1. **Custom Models:** Train custom models for specific item categories
2. **Confidence Display:** Show confidence scores in UI
3. **Tag Learning:** Learn from user corrections to improve suggestions
4. **Batch Processing:** Process multiple images simultaneously
5. **Background Processing:** Process images in background for faster UX
6. **Tag Translation:** Translate tags to user's language
7. **Smart Filtering:** Filter out generic tags, keep specific ones

### Phase 2 Features
- Cloud-based image recognition for higher accuracy
- Image similarity search (find items with similar images)
- OCR for text extraction from images
- Barcode/QR code detection in item photos

## Documentation

For more details, see:
- [Container Management Feature Documentation](CONTAINER_MANAGEMENT_FEATURE_DOCUMENTATION.md)
- [Google ML Kit Documentation](https://developers.google.com/ml-kit/vision/image-labeling)
- [Package Documentation](https://pub.dev/packages/google_mlkit_image_labeling)

## Support

If you encounter issues:
1. Check the logs for `[ImageRecognition]` debug messages
2. Verify the dependency is installed: `flutter pub get`
3. Ensure camera permissions are granted
4. Try rebuilding the app: `flutter clean && flutter run`

## Version Information

- **Package:** google_mlkit_image_labeling ^0.14.1
- **ML Kit Version:** Latest (bundled with package)
- **Confidence Threshold:** 0.5 (50%)
- **Platform Support:** iOS, Android (64-bit only)
- **Minimum SDK:**
  - Android: API 21+
  - iOS: iOS 12.0+

---

**Status:** ✅ Ready for testing
**Last Updated:** December 21, 2025
**Feature:** Image Recognition & Auto-Tagging
