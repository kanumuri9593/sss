# Container Management System - Feature Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [Services](#services)
5. [User Interface](#user-interface)
6. [User Flows](#user-flows)
7. [Integration Points](#integration-points)
8. [Technical Implementation](#technical-implementation)
9. [Storage & Persistence](#storage--persistence)
10. [Image Recognition](#image-recognition)
11. [Deep Linking](#deep-linking)
12. [Future Enhancements](#future-enhancements)

---

## Overview

The Container Management System is a comprehensive solution for organizing physical items stored in boxes, bags, and drawers. It addresses the common problem of losing track of belongings by providing a digital inventory system with visual organization, smart tagging, and quick access through QR codes and NFC tags.

### Problem Statement
Users with multiple hobbies, seasonal items, and growing families struggle to locate items stored in various containers throughout their homes. The system provides:
- Visual organization with photos
- Smart search capabilities
- Quick access via QR/NFC scanning
- Nested container support for complex storage hierarchies

### Key Features
- ✅ Create containers (boxes, bags, drawers) with photos
- ✅ Add items to containers with tags and photos
- ✅ Search by text, tags, or image recognition
- ✅ Link containers to QR codes and NFC tags
- ✅ Nested containers (containers within containers)
- ✅ On-device storage (Phase 1)
- ✅ Image recognition for automatic tag suggestions

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      User Interface Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Screens    │  │   Widgets    │  │  Navigation  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Container   │  │    Item      │  │   Image      │     │
│  │   Service    │  │   Service    │  │ Recognition  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Storage    │  │     QR       │  │     NFC      │     │
│  │   Service    │  │   Service    │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Container   │  │    Item      │  │   Hive       │     │
│  │    Model     │  │    Model     │  │  Storage     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Component Relationships

```
ContainerService ──┐
                   ├──> StorageService ──> Hive (On-Device Storage)
ItemService ───────┘

ContainerService ──> QRService (for linking)
ContainerService ──> NFCService (for linking)

ItemCreateScreen ──> ImageRecognitionService ──> Google ML Kit
ContainerCreateScreen ──> ImagePicker ──> Camera/Gallery
```

---

## Data Models

### Container Model

**Location:** `lib/models/container.dart`

**Purpose:** Represents a physical container (box, bag, or drawer) that can hold items.

**Properties:**
```dart
class Container {
  final String id;                    // Unique identifier
  final String name;                  // Container name
  final ContainerType type;           // box, bag, or drawer
  final String? photoPath;            // Path to container photo
  final String createdAt;             // ISO 8601 timestamp
  final String updatedAt;             // ISO 8601 timestamp
  final String? qrCodeId;             // Linked QR code ID
  final String? nfcTagId;             // Linked NFC tag ID
  final String? parentContainerId;    // For nesting support
  final String? description;          // Optional description
  final List<String> tags;            // Searchable tags
}
```

**Container Types:**
- `ContainerType.box` - Storage boxes
- `ContainerType.bag` - Bags, backpacks, etc.
- `ContainerType.drawer` - Drawers, cabinets, etc.

**Key Methods:**
- `Container.create()` - Factory constructor with auto-generated ID
- `copyWith()` - Immutable update pattern
- `buildDeepLink()` - Generates `sss://container/<id>` deep link
- `isContainerDeepLink()` - Validates container deep links

### Item Model

**Location:** `lib/models/item.dart`

**Purpose:** Represents an item stored within a container.

**Properties:**
```dart
class Item {
  final String id;                    // Unique identifier
  final String name;                  // Item name
  final String? description;          // Optional description
  final String containerId;          // Parent container ID
  final List<String> tags;            // Categorization tags
  final String? photoPath;            // Optional item photo
  final String createdAt;             // ISO 8601 timestamp
  final String updatedAt;             // ISO 8601 timestamp
  final double? positionX;            // Future: 2D map position
  final double? positionY;            // Future: 2D map position
}
```

**Key Methods:**
- `Item.create()` - Factory constructor with auto-generated ID
- `copyWith()` - Immutable update pattern

### Hive Adapters

**Location:** `lib/models/container_adapter.dart`, `lib/models/item_adapter.dart`

**Purpose:** Enable Hive persistence for Container and Item models.

**Implementation:**
- Type adapters registered with Hive (typeId: 0 for Container, 1 for Item)
- Serialization/deserialization via JSON conversion

---

## Services

### StorageService

**Location:** `lib/services/storage_service.dart`

**Purpose:** Manages on-device persistence using Hive.

**Key Features:**
- Initializes Hive with Flutter bindings
- Registers type adapters for Container and Item
- Provides access to Hive boxes
- Handles storage lifecycle

**Usage:**
```dart
// Initialize in main.dart
await StorageService.initialize();

// Access containers box
final box = StorageService.containersBox;
final container = box.get(containerId);

// Access items box
final itemsBox = StorageService.itemsBox;
final item = itemsBox.get(itemId);
```

**Box Names:**
- `containers` - Stores all Container objects
- `items` - Stores all Item objects

### ContainerService

**Location:** `lib/services/container_service.dart`

**Purpose:** Business logic for container management.

**Key Methods:**

#### CRUD Operations
- `createContainer(Container)` - Create new container
- `getContainer(String id)` - Get container by ID
- `getAllContainers()` - Get all containers
- `updateContainer(Container)` - Update existing container
- `deleteContainer(String id)` - Delete container (cascades to items and nested containers)

#### Hierarchy Management
- `getRootContainers()` - Get containers without parents
- `getChildContainers(String parentId)` - Get nested containers
- `canNestContainer(String id, String parentId)` - Check for circular references
- `moveContainer(String id, String? newParentId)` - Move container in hierarchy

#### Search
- `searchContainers(String query)` - Text search across name, description, tags
- `searchContainersByTags(List<String> tags)` - Tag-based search

#### QR/NFC Integration
- `linkQRCode(String containerId, String qrCodeId)` - Link QR code
- `linkNFCTag(String containerId, String nfcTagId)` - Link NFC tag
- `unlinkQRCode(String containerId)` - Remove QR link
- `unlinkNFCTag(String containerId)` - Remove NFC link
- `getContainerByQRCode(String qrCodeId)` - Find container by QR
- `getContainerByNFCTag(String nfcTagId)` - Find container by NFC

#### Item Access
- `getItemsInContainer(String containerId)` - Get all items in container

### ItemService

**Location:** `lib/services/item_service.dart`

**Purpose:** Business logic for item management.

**Key Methods:**

#### CRUD Operations
- `createItem(Item)` - Create new item
- `getItem(String id)` - Get item by ID
- `getAllItems()` - Get all items
- `updateItem(Item)` - Update existing item
- `deleteItem(String id)` - Delete item

#### Container Operations
- `getItemsByContainer(String containerId)` - Get items in container
- `getItemsByContainers(List<String> containerIds)` - Get items from multiple containers
- `moveItem(String itemId, String newContainerId)` - Move item between containers
- `deleteItemsInContainer(String containerId)` - Bulk delete items

#### Search
- `searchItems(String query)` - Text search across name, description, tags
- `searchItemsByTags(List<String> tags)` - Tag-based search
- `searchItemsInContainer(String containerId, String query)` - Search within container

#### Bulk Operations
- `bulkUpdateItems(List<String> itemIds, Function)` - Apply updates to multiple items

### ImageRecognitionService

**Location:** `lib/services/image_recognition_service.dart`

**Purpose:** On-device image recognition using Google ML Kit.

**Key Features:**
- Uses Google ML Kit Image Labeling (on-device, no cloud)
- Low-cost processing (no API calls)
- Automatic tag suggestions from photos

**Key Methods:**
- `initialize()` - Initialize ML Kit labeler
- `processImage(String imagePath)` - Get tag suggestions from image
- `processImageDetailed(String imagePath)` - Get detailed labels with confidence scores
- `getTopTagSuggestions(String imagePath, int topN)` - Get top N tag suggestions

**Configuration:**
- Confidence threshold: 0.5 (50% minimum)
- Returns lowercase, formatted tags (spaces replaced with hyphens)

**Usage Flow:**
1. User takes/selects photo
2. Photo saved to app documents directory
3. ImageRecognitionService processes image
4. Returns list of suggested tags
5. User can accept/reject suggestions

---

## User Interface

### Screen Hierarchy

```
MainTabScreen
├── ContainerListScreen
│   └── ContainerDetailScreen
│       ├── ContainerCreateScreen (edit mode)
│       └── ItemCreateScreen
├── ContainerCreateScreen (create mode)
├── SearchScreen
├── QRPOCScreen
└── NFCPOCScreen
```

### ContainerListScreen

**Location:** `lib/screens/container_list_screen.dart`

**Purpose:** Main entry point for container management.

**Features:**
- Grid/List view toggle
- Search bar for filtering
- Pull-to-refresh
- Empty state with helpful message
- Floating action button to create container

**UI Components:**
- Search bar with clear button
- Grid view (2 columns) or List view
- Container cards showing photo, name, type, item count
- View toggle button in app bar

**User Actions:**
- Tap container card → Navigate to ContainerDetailScreen
- Tap search → Filter containers
- Tap + button → Open ContainerCreateScreen
- Pull down → Refresh container list

### ContainerDetailScreen

**Location:** `lib/screens/container_detail_screen.dart`

**Purpose:** Display container details and manage items.

**Features:**
- Large container photo header
- Container information (name, type, description, tags)
- Search bar for items within container
- Nested containers section (horizontal scroll)
- Items grid view
- Edit and delete actions

**UI Components:**
- Container photo (200px height)
- Container info section
- Search bar
- Nested containers horizontal list
- Items grid (2 columns)
- Floating action button to add item

**User Actions:**
- Tap edit icon → Open ContainerCreateScreen (edit mode)
- Tap delete icon → Confirm and delete container
- Tap nested container → Navigate to that container's detail
- Tap item card → Open ItemCreateScreen (edit mode)
- Tap + button → Open ItemCreateScreen (create mode)
- Search items → Filter items in container

### ContainerCreateScreen

**Location:** `lib/screens/container_create_screen.dart`

**Purpose:** Create or edit containers.

**Features:**
- Photo capture/selection (camera or gallery)
- Name input (required)
- Type selector (box/bag/drawer)
- Parent container selector (for nesting)
- Description input
- Tags input (comma-separated)
- QR/NFC linking (edit mode only)

**Form Fields:**
1. **Photo Section**
   - Tap to add/change photo
   - Shows placeholder if no photo
   - Displays current photo if editing

2. **Name** (required)
   - Text input with validation

3. **Type** (required)
   - Dropdown: Box, Bag, Drawer

4. **Parent Container** (optional)
   - Dropdown with "None" option
   - Lists available containers (excludes current and nested)

5. **Description** (optional)
   - Multi-line text input

6. **Tags** (optional)
   - Comma-separated input
   - Helper text with format instructions

7. **QR/NFC Linking** (edit mode only)
   - Two buttons: "Link QR" and "Link NFC"
   - Only available after container is saved

**User Flow:**
1. Fill form fields
2. Add photo (optional)
3. Save container
4. (Edit mode) Link QR/NFC if desired

### ItemCreateScreen

**Location:** `lib/screens/item_create_screen.dart`

**Purpose:** Create or edit items.

**Features:**
- Photo capture/selection with AI tag suggestions
- Name input (required)
- Description input
- Tags input with AI suggestions
- Container selector (if creating from search)

**Form Fields:**
1. **Photo Section**
   - Tap to add/change photo
   - Shows processing indicator during AI analysis
   - Displays AI suggestion badge if tags found
   - Auto-fills tags if none exist

2. **Name** (required)
   - Text input with validation

3. **Description** (optional)
   - Multi-line text input

4. **Tags** (optional)
   - Comma-separated input
   - AI suggestion chips appear below
   - Tap chips to add/remove tags
   - AI icon button to view all suggestions

**AI Tag Suggestions:**
- Triggered when photo is added
- Uses Google ML Kit for on-device processing
- Returns top 10 tag suggestions
- Formats tags (lowercase, hyphens for spaces)
- Shows suggestions as filter chips

**User Flow:**
1. Add photo (triggers AI analysis)
2. Review AI tag suggestions
3. Fill name and description
4. Add/edit tags
5. Save item

### SearchScreen

**Location:** `lib/screens/search_screen.dart`

**Purpose:** Unified search interface for items and containers.

**Features:**
- Text search
- Tag-based search
- Image-based search (AI recognition)
- Popular tags display
- Results grouped by type (containers vs items)

**Search Methods:**

1. **Text Search**
   - Searches name, description, and tags
   - Real-time filtering as user types
   - Searches both items and containers

2. **Tag Search**
   - Tap popular tags to search
   - Shows available tags when search is empty
   - Searches items and containers by tag intersection

3. **Image Search**
   - Camera button in search bar
   - Take photo or select from gallery
   - AI processes image and extracts tags
   - Searches using extracted tags
   - Updates search query with found tags

**Results Display:**
- Containers section (horizontal scroll)
- Items section (grid view)
- Shows container location for items
- Tap result → Navigate to ContainerDetailScreen

**User Flow:**
1. Enter search query OR tap camera icon
2. View results (containers and items)
3. Tap result to view details
4. Navigate to container to see item

---

## User Flows

### Flow 1: Create Container and Add Items

```
1. User opens app → ContainerListScreen
2. Taps + button → ContainerCreateScreen
3. Takes photo of container
4. Enters name: "Winter Clothes Box"
5. Selects type: Box
6. Adds tags: "winter, clothes, storage"
7. Saves container
8. Returns to ContainerListScreen
9. Taps container card → ContainerDetailScreen
10. Taps + button → ItemCreateScreen
11. Takes photo of item (e.g., jacket)
12. AI suggests tags: "clothing, jacket, winter"
13. Enters name: "Winter Jacket"
14. Saves item
15. Returns to ContainerDetailScreen
16. Item appears in grid
```

### Flow 2: Link Container to QR Code

```
1. User opens ContainerDetailScreen
2. Taps edit icon → ContainerCreateScreen (edit mode)
3. Taps "Link QR" button
4. QR code generated with deep link: sss://container/<id>
5. QR code ID linked to container
6. User can print/generate QR code from QR tab
7. When QR code is scanned → Opens ContainerDetailScreen
```

### Flow 3: Search for Item

```
1. User opens SearchScreen
2. Enters search query: "jacket"
3. Results show:
   - Items matching "jacket"
   - Containers matching "jacket"
4. User taps item result
5. Navigates to ContainerDetailScreen showing item's container
6. Item is highlighted/visible in container
```

### Flow 4: Image-Based Search

```
1. User opens SearchScreen
2. Taps camera icon
3. Takes photo of item they're looking for
4. AI processes image:
   - Extracts labels: "clothing", "jacket", "winter"
5. Search automatically runs with extracted tags
6. Results show items/containers matching tags
7. User taps result to view container
```

### Flow 5: Nested Containers

```
1. User creates "Garage Storage" container (root)
2. Creates "Winter Sports Box" container
3. Sets parent: "Garage Storage"
4. Creates "Ski Equipment Bag" container
5. Sets parent: "Winter Sports Box"
6. Hierarchy:
   - Garage Storage (root)
     └── Winter Sports Box
         └── Ski Equipment Bag
7. Viewing "Garage Storage" shows nested containers
8. Can navigate into nested containers
```

### Flow 6: Scan QR/NFC to Open Container

```
1. User scans QR code or NFC tag
2. Deep link handler processes: sss://container/<id>
3. OR processes: sss://qr/<id> and finds linked container
4. Opens ContainerDetailScreen
5. User can view items, add items, edit container
```

---

## Integration Points

### QR Code Integration

**Location:** `lib/services/qr_service.dart`, `lib/services/container_service.dart`

**How It Works:**
1. Container creates deep link: `sss://container/<containerId>`
2. QR code generated with this deep link
3. QR code ID stored in container's `qrCodeId` field
4. When QR code is scanned:
   - Deep link handler checks if QR ID links to container
   - If linked, opens ContainerDetailScreen
   - Otherwise, opens QRDetailScreen

**Code Flow:**
```dart
// Link QR to container
final deepLink = container.buildDeepLink(); // sss://container/<id>
final qrDeepLink = QRService.generateDeepLink(data: deepLink);
final qrId = QRData.extractIdFromDeepLink(qrDeepLink);
await ContainerService.linkQRCode(containerId, qrId);

// When scanned
final container = ContainerService.getContainerByQRCode(qrId);
if (container != null) {
  // Open container detail
}
```

### NFC Tag Integration

**Location:** `lib/services/nfc_service.dart`, `lib/services/container_service.dart`

**How It Works:**
1. Container creates deep link: `sss://container/<containerId>`
2. NFC tag written with this deep link
3. NFC tag ID stored in container's `nfcTagId` field
4. When NFC tag is scanned:
   - Deep link handler checks if NFC ID links to container
   - If linked, opens ContainerDetailScreen
   - Otherwise, opens NFCDetailScreen

**Code Flow:**
```dart
// Link NFC to container
final deepLink = container.buildDeepLink();
// Write to NFC tag (via NFCWriteScreen)
// Store NFC tag ID
await ContainerService.linkNFCTag(containerId, nfcTagId);

// When scanned
final container = ContainerService.getContainerByNFCTag(nfcTagId);
if (container != null) {
  // Open container detail
}
```

### Deep Link Handling

**Location:** `lib/main.dart`

**Supported Deep Links:**
- `sss://container/<containerId>` - Direct container link
- `sss://qr/<id>` - QR code link (may link to container)
- `sss://qr/<id>` - NFC tag link (may link to container)

**Processing Flow:**
```
Deep Link Received
    │
    ├─→ sss://container/<id>
    │   └─→ Open ContainerDetailScreen
    │
    └─→ sss://qr/<id>
        ├─→ Check if linked to container
        │   └─→ Open ContainerDetailScreen
        ├─→ Check if QR code
        │   └─→ Open QRDetailScreen
        └─→ Check if NFC tag
            └─→ Open NFCDetailScreen
```

---

## Technical Implementation

### Storage Architecture

**Technology:** Hive (NoSQL database for Flutter)

**Why Hive:**
- Fast on-device storage
- No SQL required
- Type-safe with adapters
- Lightweight (perfect for Phase 1)
- Easy migration path to cloud

**Storage Structure:**
```
App Documents Directory
├── photos/
│   ├── container_<timestamp>.jpg
│   └── item_<timestamp>.jpg
└── (Hive database files)
    ├── containers.hive
    └── items.hive
```

**Data Persistence:**
- Containers stored in `containers` Hive box
- Items stored in `items` Hive box
- Photos stored in `photos/` directory
- All data persisted immediately on save

### Photo Management

**Location:** `lib/utils/file_utils.dart`

**Photo Storage:**
- Photos saved to app documents directory
- Path format: `photos/container_<timestamp>.jpg` or `photos/item_<timestamp>.jpg`
- Photos referenced by path in Container/Item models
- Photos persist across app restarts

**Photo Operations:**
- `savePhoto(File source, String fileName)` - Copy photo to app directory
- `getPhotoFilePath(String fileName)` - Get full path for photo
- `getPhotosDirectory()` - Get photos directory

### Image Recognition Pipeline

**Technology:** Google ML Kit Image Labeling

**Processing Flow:**
```
User selects/takes photo
    │
    ├─→ Save photo to app directory
    │
    ├─→ ImageRecognitionService.processImage()
    │   ├─→ Load image file
    │   ├─→ Create InputImage from file path
    │   ├─→ Process with ML Kit labeler
    │   └─→ Extract labels (confidence > 0.5)
    │
    └─→ Format labels as tags
        ├─→ Convert to lowercase
        ├─→ Replace spaces with hyphens
        └─→ Return top N suggestions
```

**Performance:**
- On-device processing (no network calls)
- Typical processing time: 1-3 seconds
- Confidence threshold: 50%
- Returns top 10 suggestions by default

### Search Implementation

**Text Search:**
- Case-insensitive substring matching
- Searches: name, description, tags
- Real-time filtering as user types
- Searches both items and containers

**Tag Search:**
- Set intersection matching
- Item/container matches if any tag matches
- Supports multiple tag search
- Case-insensitive

**Image Search:**
- Uses ImageRecognitionService to extract tags
- Searches using extracted tags
- Updates search query with found tags
- Combines with text search results

### Nested Container Logic

**Circular Reference Prevention:**
```dart
bool canNestContainer(String containerId, String parentContainerId) {
  // Can't nest in itself
  if (containerId == parentContainerId) return false;
  
  // Check all ancestors of parent
  // If any ancestor is containerId, return false (circular)
  // Otherwise, return true
}
```

**Hierarchy Navigation:**
- Root containers have `parentContainerId == null`
- Child containers reference parent via `parentContainerId`
- Recursive deletion deletes all nested containers
- UI shows nested containers in horizontal scroll

---

## Storage & Persistence

### Hive Box Structure

**Containers Box:**
- Key: Container ID (String)
- Value: Container object
- Indexed by: ID (primary key)

**Items Box:**
- Key: Item ID (String)
- Value: Item object
- Indexed by: ID (primary key)

### Data Migration

**Current (Phase 1):**
- All data stored on-device
- No migration needed

**Future (Phase 2):**
- StorageService will handle migration
- Export/import functionality
- Cloud sync support

### Backup & Restore

**Current:**
- Data stored in app documents directory
- Can be backed up via device backup
- No explicit export/import (Phase 2 feature)

---

## Image Recognition

### Google ML Kit Integration

**Package:** `google_mlkit_image_labeling: ^0.11.0`

**Configuration:**
- Model: Default ML Kit image labeling model
- Confidence threshold: 0.5 (50%)
- Processing: On-device only

**Label Format:**
- Input: "Winter Jacket", "Clothing", "Outerwear"
- Output: "winter-jacket", "clothing", "outerwear"
- Format: lowercase, hyphens for spaces

**Performance:**
- Processing time: 1-3 seconds per image
- No network required
- No API costs
- Works offline

### Tag Suggestion Flow

```
1. User adds photo
2. Photo saved to app directory
3. ImageRecognitionService initialized (if not already)
4. Image processed with ML Kit
5. Labels extracted (confidence > 0.5)
6. Labels formatted as tags
7. Top N tags returned
8. UI displays suggestions
9. User accepts/rejects suggestions
```

---

## Deep Linking

### Deep Link Format

**Container Links:**
- Format: `sss://container/<containerId>`
- Example: `sss://container/container-1234567890-abc123`

**QR/NFC Links:**
- Format: `sss://qr/<id>`
- May link to container if `qrCodeId` or `nfcTagId` is set

### Deep Link Processing

**Location:** `lib/main.dart`

**Handler Flow:**
1. App receives deep link
2. Parse URI: `sss://container/<id>` or `sss://qr/<id>`
3. Check if container link → Open ContainerDetailScreen
4. Check if QR/NFC link:
   - Check if linked to container → Open ContainerDetailScreen
   - Check if QR code → Open QRDetailScreen
   - Check if NFC tag → Open NFCDetailScreen
5. Navigate to appropriate screen

### QR Code Deep Links

When QR code is generated for container:
1. Container builds deep link: `sss://container/<id>`
2. QR code encodes this deep link
3. QR code ID stored in container
4. When scanned, deep link opens container

### NFC Tag Deep Links

When NFC tag is written for container:
1. Container builds deep link: `sss://container/<id>`
2. NFC tag encodes this deep link
3. NFC tag ID stored in container
4. When scanned, deep link opens container

---

## Future Enhancements

### Phase 2 Features

**Cloud Sync:**
- Multi-device synchronization
- User accounts and authentication
- Cloud backup and restore
- Conflict resolution

**Multi-User Support:**
- Shared containers
- User permissions
- Activity logs
- Collaboration features

**Advanced Features:**
- Interactive 2D map positioning
- Item history and tracking
- Export/import functionality
- Barcode scanning for items
- Voice search
- Smart suggestions based on usage

**Performance:**
- Image compression
- Lazy loading for large collections
- Caching strategies
- Background sync

**Analytics:**
- Usage statistics
- Most searched items
- Container organization insights
- Storage optimization suggestions

---

## File Structure

```
lib/
├── models/
│   ├── container.dart              # Container model
│   ├── container_adapter.dart      # Hive adapter for Container
│   ├── item.dart                   # Item model
│   └── item_adapter.dart           # Hive adapter for Item
├── services/
│   ├── container_service.dart      # Container business logic
│   ├── item_service.dart           # Item business logic
│   ├── image_recognition_service.dart  # ML Kit integration
│   └── storage_service.dart        # Hive storage management
├── screens/
│   ├── container_list_screen.dart   # Main container list
│   ├── container_detail_screen.dart # Container details
│   ├── container_create_screen.dart # Create/edit container
│   ├── item_create_screen.dart     # Create/edit item
│   └── search_screen.dart          # Unified search
├── widgets/
│   ├── container_card.dart         # Container display widget
│   └── item_card.dart              # Item display widget
└── utils/
    └── file_utils.dart             # Photo file management
```

---

## Dependencies

### Core Dependencies
```yaml
# Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# Image Recognition
google_mlkit_image_labeling: ^0.11.0

# Image Picker
image_picker: ^1.0.7

# Path utilities
path: ^1.9.0
path_provider: ^2.1.1
```

### Integration Dependencies
```yaml
# QR Code (existing)
qr_flutter: ^4.1.0
mobile_scanner: ^5.2.3

# NFC (existing)
nfc_manager: ^4.1.1
ndef_record: ^1.3.3

# Deep Linking (existing)
uni_links: ^0.5.1
```

---

## Testing Considerations

### Unit Tests (Future)
- ContainerService CRUD operations
- ItemService CRUD operations
- Search functionality
- Nested container logic
- Circular reference prevention

### Integration Tests (Future)
- Container creation flow
- Item creation with AI tags
- QR/NFC linking
- Deep link handling
- Search flows

### UI Tests (Future)
- Screen navigation
- Form validation
- Photo capture/selection
- Search interactions

---

## Performance Considerations

### Current Optimizations
- On-device storage (fast access)
- Lazy loading in lists
- Image caching (Flutter handles)
- Efficient search algorithms

### Future Optimizations
- Image compression before storage
- Pagination for large lists
- Background image processing
- Search result caching

---

## Security & Privacy

### Current (Phase 1)
- All data stored on-device
- No network transmission
- No user accounts
- Photos stored in app directory

### Future (Phase 2)
- Encrypted cloud storage
- User authentication
- Privacy controls
- Data export options

---

## Conclusion

The Container Management System provides a comprehensive solution for organizing physical items with:
- Visual organization through photos
- Smart search capabilities
- Quick access via QR/NFC
- Flexible nesting support
- On-device processing for privacy

The system is designed for Phase 1 (on-device) with a clear path to Phase 2 (cloud sync, multi-user) enhancements.

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Author:** Container Management System Implementation
