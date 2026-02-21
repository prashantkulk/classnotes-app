# ClassNotes - Comprehensive Project Documentation

## Overview

ClassNotes is a cross-platform app (iOS + Android) for parents and teachers to share and request class notes within school groups. Both platforms share the same Firebase backend.

- **Bundle ID / Application ID**: `com.classnotes.app`
- **Team ID (iOS)**: `AU57XJFV4W`
- **Firebase Project**: `classnotes-afe61`
- **GitHub**: https://github.com/prashantkulk/classnotes-app
- **Min iOS**: 16.0
- **Min Android SDK**: 26 (Android 8.0), Target SDK: 35

## Important Links

| Resource | URL |
|----------|-----|
| Firebase Console | https://console.firebase.google.com/project/classnotes-afe61 |
| Firestore | https://console.firebase.google.com/project/classnotes-afe61/firestore |
| Firebase Storage | https://console.firebase.google.com/project/classnotes-afe61/storage |
| Firebase Auth | https://console.firebase.google.com/project/classnotes-afe61/authentication |
| Cloud Functions | https://console.firebase.google.com/project/classnotes-afe61/functions |
| FCM (Notifications) | https://console.firebase.google.com/project/classnotes-afe61/messaging |
| App Store Connect | https://appstoreconnect.apple.com |
| Google Cloud Console | https://console.cloud.google.com/functions/list?project=classnotes-afe61 |

---

## iOS App Architecture

### Pattern: MVVM with ObservableObject Services

```
ClassNotesApp.swift (Entry point)
  -> RootView (routing: Login -> Onboarding -> GroupsList)
     -> AuthService (EnvironmentObject, shared across all views)

Views observe service @Published properties via @ObservedObject/@StateObject.
Services talk to Firebase directly. No repository layer.
```

### iOS Project Structure

```
ios/
├── ClassNotes.xcodeproj/          # Xcode project file
├── ClassNotes/                    # Main app source
│   ├── ClassNotesApp.swift          # App entry, AppDelegate, RootView routing
│   ├── Info.plist                    # URL scheme for Firebase Phone Auth callback
│   ├── ClassNotes.entitlements       # Push notification entitlement (aps-environment)
│   ├── GoogleService-Info.plist      # Firebase config (DO NOT commit secrets)
│   ├── Models/
│   │   ├── User.swift                # AppUser (id, phone, name, groups, fcmToken)
│   │   ├── Group.swift               # ClassGroup (members, inviteCode, customSubjects)
│   │   ├── Post.swift                # Post (groupId, subjectName, photoURLs)
│   │   ├── Request.swift             # NoteRequest + RequestResponse + RequestStatus
│   │   ├── Subject.swift             # Subject enum (Math, Science, English, Hindi, Social Studies, Other)
│   │   └── SubjectInfo.swift         # Wrapper for built-in + custom subjects
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift       # Phone number + OTP entry with country code picker
│   │   │   └── OnboardingView.swift  # "What should we call you?" name entry
│   │   ├── Groups/
│   │   │   ├── GroupsListView.swift  # List of groups, create/join actions
│   │   │   ├── CreateGroupView.swift # Create group form
│   │   │   └── JoinGroupView.swift   # Join group by invite code
│   │   ├── Feed/
│   │   │   ├── GroupFeedView.swift   # Notes/Requests tabs, subject filter, GroupInfoView sheet
│   │   │   ├── PostCardView.swift    # Note card + CachedAsyncImage + ImageCache
│   │   │   └── CreatePostView.swift  # Multi-step: Photos -> Subject -> Date -> Review
│   │   ├── Requests/
│   │   │   ├── RequestsListView.swift # CreateRequestView (multi-step request wizard)
│   │   │   └── RequestDetailView.swift # Request detail + respond with photos
│   │   ├── Common/
│   │   │   ├── PhotoViewer.swift     # Full-screen zoomable photo viewer with save
│   │   │   ├── SubjectPicker.swift   # (Legacy, not actively used)
│   │   │   └── AddCustomSubjectView.swift # Add custom subject with color/icon picker
│   │   └── Settings/
│   │       └── SettingsView.swift    # Sign out, delete account, app version
│   ├── Services/
│   │   ├── AuthService.swift         # Firebase Phone Auth + user profile
│   │   ├── GroupService.swift        # CRUD groups, join/leave, custom subjects
│   │   ├── PostService.swift         # CRUD posts with real-time snapshot listener
│   │   ├── RequestService.swift      # CRUD requests, respond, mark fulfilled
│   │   ├── StorageService.swift      # Image upload to Firebase Storage (resize + compress)
│   │   ├── NotificationService.swift # FCM token management + member fetching
│   │   └── DemoServices.swift        # In-memory mock services for simulator demo mode
│   └── Utilities/
│       └── Extensions.swift          # Date formatting helpers
├── ClassNotesTests/
│   ├── Helpers/TestFixtures.swift    # Shared test data
│   ├── Models/                       # Unit tests for all model types
│   ├── Utilities/                    # Date extension tests
│   └── Services/
│       ├── Protocols/                # Service protocols for testability
│       ├── Mocks/                    # Mock implementations
│       └── Tests/                    # Service logic unit tests
└── ClassNotesUITests/
    └── ClassNotesUITests.swift       # Full demo flow E2E test

functions/                             # Cloud Functions (shared backend)
└── src/index.ts                       # v2: onPostCreated, onRequestCreated
```

---

## iOS Demo Mode

On simulator (`#if targetEnvironment(simulator)`), `AppMode.isDemo` is set to `true`. This:
- Uses `DemoAuthService`, `DemoGroupService`, `DemoPostService`, `DemoRequestService` (in-memory, no Firebase calls)
- Pre-populates data from `DemoData` enum (7 users, 2 groups, 6 posts, 4 requests)
- Skips `FirebaseApp.configure()` in AppDelegate
- Phone number: `9876543210`, OTP: `123456` (any 6 digits), Name: `Aditi's Mom`

---

## Firebase Backend Architecture

### Firestore Collections

**`users/{userId}`**
```
{
  phone: "+919876543210",
  name: "Aditi's Mom",
  groups: ["groupId1", "groupId2"],
  fcmToken: "firebase-cloud-messaging-token",
  createdAt: Timestamp
}
```

**`groups/{groupId}`**
```
{
  name: "Class 5A",
  school: "Delhi Public School",
  inviteCode: "ABC123",
  members: ["userId1", "userId2"],
  createdBy: "userId1",
  createdAt: Timestamp,
  customSubjects: [{"name": "Computer", "color": "cyan", "icon": "laptopcomputer"}]
}
```

**`posts/{postId}`**
```
{
  groupId: "groupId1",
  authorId: "userId1",
  authorName: "Aditi's Mom",
  subject: "Math",                    // stored as string, field name is "subject"
  date: Timestamp,
  description: "Chapter 7 - Fractions",
  photoURLs: ["https://firebasestorage.googleapis.com/..."],
  createdAt: Timestamp
}
```

**`requests/{requestId}`**
```
{
  groupId: "groupId1",
  authorId: "userId1",
  authorName: "You",
  subject: "Science",                 // stored as string, field name is "subject"
  date: Timestamp,
  description: "Need Science notes",
  status: "open" | "fulfilled",
  targetUserId: "userId2" | null,     // null = ask everyone
  targetUserName: "Aditi's Mom" | null,
  responses: [{
    id: "respId",
    authorId: "userId2",
    authorName: "Aditi's Mom",
    photoURLs: ["https://..."],
    createdAt: Timestamp
  }],
  createdAt: Timestamp
}
```

### Firestore Composite Indexes (CRITICAL)

Defined in `firestore.indexes.json`. Without these, queries with `whereField` + `order(by:)` on different fields **fail silently** (snapshot listeners return nil).

| Collection | Fields | Purpose |
|-----------|--------|---------|
| `posts` | groupId ASC + createdAt DESC | `PostService.loadPosts()` |
| `requests` | groupId ASC + createdAt DESC | `RequestService.loadRequests()` |
| `requests` | groupId ASC + subject ASC + status ASC | Cloud Function: find matching open requests |
| `groups` | members CONTAINS + createdAt DESC | `GroupService.loadGroups()` |

Deploy with: `firebase deploy --only firestore:indexes`

### Firebase Storage Structure

```
posts/{postId}/{uuid}.jpg          # Note photos (resized to max 1600px, JPEG 0.6 quality)
requests/{requestId}/responses/{uuid}.jpg  # Response photos
```

### Cloud Functions (v2)

Located in `functions/src/index.ts`. Uses `firebase-functions/v2/firestore` API.

**`onPostCreated`**: Triggered when a new post is created.
- Finds open requests for the same subject in the same group
- If matching requests exist: notifies the request authors ("X shared Math notes you requested!")
- If no matching requests: notifies all group members except the author ("X shared Math notes")

**`onRequestCreated`**: Triggered when a new request is created.
- If targeted at a specific user: notifies that user ("X has requested Math notes from you")
- If broadcast to group: notifies all group members except the author ("X is looking for Math notes")

Both functions:
- Clean up invalid FCM tokens automatically
- Batch Firestore queries in groups of 30 (Firestore `in` query limit)

---

## iOS Data Flow Deep Dive

### Authentication Flow
```
LoginView -> AuthService.sendOTP(fullNumber)
  -> PhoneAuthProvider.verifyPhoneNumber() -> verificationId stored
LoginView -> AuthService.verifyOTP(code)
  -> PhoneAuthProvider.credential() -> Auth.signIn()
  -> Auth state listener fires -> fetchUserProfile()
  -> If no name: needsOnboarding = true -> OnboardingView
  -> completeOnboarding(name) -> writes to Firestore users/{uid}
```

### Real-time Data Loading
```
GroupsListView.onAppear -> GroupService.loadGroups(userId)
  -> Firestore snapshot listener on groups WHERE members CONTAINS userId
  -> @Published groups updated -> UI re-renders

GroupFeedView.onAppear -> PostService.loadPosts(groupId)
  -> Firestore snapshot listener on posts WHERE groupId == X ORDER BY createdAt DESC
  -> @Published posts updated -> UI re-renders

GroupFeedView.onAppear -> RequestService.loadRequests(groupId)
  -> Firestore snapshot listener on requests WHERE groupId == X ORDER BY createdAt DESC
  -> @Published requests updated -> UI re-renders
```

### Photo Upload Flow
```
CreatePostView: user selects photos from gallery or camera
  -> loadImages() converts PhotosPickerItem -> UIImage
  -> shareNotes() calls PostService.createPost(images)
    -> StorageService.uploadImages(images, basePath: "posts/{postId}")
      -> For each image:
        -> resizeImage() to max 1600px dimension
        -> jpegData(compressionQuality: 0.6)
        -> Storage.putData() with completion handler
        -> fetchDownloadURL() with retry (up to 3 attempts, 1s/2s/3s delays)
      -> Returns array of download URLs
    -> PostService writes to Firestore posts collection
    -> Cloud Function `onPostCreated` triggers -> sends push notifications
```

### Join Group Flow
```
JoinGroupView -> GroupService.joinGroup(code, userId)
  -> Firestore query: groups WHERE inviteCode == code
  -> Check if already a member (409 error)
  -> Firestore batch write:
    - groups/{groupId}.members: arrayUnion(userId)
    - users/{userId}.groups: arrayUnion(groupId)
  -> Wait for batch.commit() completion
  -> Return group with updated members array (includes joining user)
  -> JoinGroupView calls groupService.loadGroups() to refresh
```

### GroupFeedView Live Data Pattern
```
GroupFeedView receives `group: ClassGroup` (initial value, may become stale)
  -> Defines computed `liveGroup`:
     groupService.groups.first { $0.id == group.id } ?? group
  -> All UI reads from `liveGroup` (real-time from snapshot listener)
  -> GroupInfoView uses same pattern + .onChange(of: liveGroup.members) to re-fetch member details
```

---

## iOS Image Caching System

`PostCardView.swift` contains:
- **`ImageCache`**: Singleton with NSCache (50MB memory, 100 items) + URLSession with URLCache (20MB memory, 200MB disk)
- **`CachedAsyncImage`**: SwiftUI view that checks memory cache synchronously, then falls back to URLSession (which checks disk cache automatically via `returnCacheDataElseLoad`)
- Used in: PostCardView, RequestDetailView, PhotoViewer

---

## iOS Key Implementation Details

### Firebase Phone Auth URL Scheme
`Info.plist` must contain `CFBundleURLTypes` with scheme `app-1-577096727828-ios-c6e54a3334cc4cda98d601` (derived from `GoogleService-Info.plist` GOOGLE_APP_ID). Without this, Firebase Phone Auth crashes on real devices with `fatalError`.

### Custom Subjects
Groups can have custom subjects beyond the 6 built-in ones. Stored as `[[String: String]]` in the group document's `customSubjects` field. Each entry has `name`, `color`, `icon` keys. `SubjectInfo.swift` wraps both built-in and custom subjects with a unified interface.

### Subject Field Name
In Firestore, the subject field is stored as `"subject"` (not `"subjectName"`). In Swift models, it's `subjectName: String`. The `Post` and `NoteRequest` models have a convenience `subject: Subject?` computed property for backward compatibility with the enum.

### Snapshot Listener Error Handling
All three snapshot listeners (groups, posts, requests) log errors to console with `[ServiceName]` prefix. If a query requires a composite index that doesn't exist, the snapshot listener returns an error (not nil documents), which is now logged.

---

## iOS Build, Test, and Upload

### Prerequisites
- Xcode (latest, with iOS 26.2 SDK for iPhone 17 Pro simulator)
- Node.js: `/Users/prashant/local/node-v20.11.1-darwin-arm64/bin/`
- Firebase CLI: available at same path as `firebase`
- Signing identity: `Apple Development: prashantkulkarni.nm@gmail.com (QHYZ38AQ8B)`
- Distribution cert: Cloud-managed (Apple re-signs during export with `-allowProvisioningUpdates`)

### Node.js PATH Setup
```bash
export PATH="/Users/prashant/local/node-v20.11.1-darwin-arm64/bin:$PATH"
```

### Quick Build & Test
```bash
# Build for simulator
xcodebuild -project ios/ClassNotes.xcodeproj -scheme ClassNotes -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests (unit + UI)
xcodebuild -project ios/ClassNotes.xcodeproj -scheme ClassNotes -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

### Full Upload Pipeline

1. **Bump version** in `project.pbxproj`: Change all `CURRENT_PROJECT_VERSION = N` to `N+1` (6 occurrences). Must increment for each App Store Connect upload.

2. **Archive without signing**:
```bash
xcodebuild -project ios/ClassNotes.xcodeproj -scheme ClassNotes -sdk iphoneos -configuration Release \
  -archivePath /tmp/ClassNotes.xcarchive archive \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

3. **Sign all frameworks + main app**:
```bash
# Sign embedded frameworks first
for fw in /tmp/ClassNotes.xcarchive/Products/Applications/ClassNotes.app/Frameworks/*.framework; do
    codesign --force --sign "Apple Development: prashantkulkarni.nm@gmail.com (QHYZ38AQ8B)" "$fw"
done

# Sign the main app
codesign --force --sign "Apple Development: prashantkulkarni.nm@gmail.com (QHYZ38AQ8B)" \
  --entitlements ios/ClassNotes/ClassNotes.entitlements \
  /tmp/ClassNotes.xcarchive/Products/Applications/ClassNotes.app
```

4. **Create export options plist** (`/tmp/ExportOptions.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>AU57XJFV4W</string>
</dict>
</plist>
```

5. **Export and upload**:
```bash
xcodebuild -exportArchive -archivePath /tmp/ClassNotes.xcarchive \
  -exportPath /tmp/ClassNotesExport \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -allowProvisioningUpdates
```

The `-allowProvisioningUpdates` flag causes Xcode to re-sign with the cloud-managed distribution certificate automatically.

### Firebase Deployment

```bash
export PATH="/Users/prashant/local/node-v20.11.1-darwin-arm64/bin:$PATH"

# Deploy everything
firebase deploy

# Deploy specific components
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
firebase deploy --only functions

# Build functions manually
npm --prefix functions run build

# Delete functions (if upgrading v1 -> v2)
firebase functions:delete functionName --force

# List deployed functions
firebase functions:list
```

**IMPORTANT**: When upgrading Cloud Functions from v1 to v2, you MUST delete the v1 function first, then deploy the v2 version. In-place upgrades are not supported.

---

## iOS End-to-End Testing on Simulator

### Automated UI Test
The `ClassNotesUITests.testFullDemoFlow()` test covers:
1. Login screen verification
2. Phone number entry (9876543210) + Send OTP
3. OTP entry (123456) + auto-verify
4. Onboarding name entry ("Aditi's Mom") + Continue
5. Groups list - verify "Class 5A" appears
6. Navigate into group feed
7. Switch to Requests tab
8. Navigate back
9. Open Settings

Screenshots are saved to `/Users/prashant/Projects/ClassNotes/screenshots/`.

Run: `xcodebuild -project ios/ClassNotes.xcodeproj -scheme ClassNotes -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`

### Manual Testing Flows

**Flow 1: Share Notes**
1. Open app in simulator -> auto-enters demo mode
2. Enter phone 9876543210 -> Send OTP -> Enter 123456
3. Enter name "Test Parent" -> Continue
4. Tap "Class 5A"
5. Tap "Share Notes" floating button
6. Select photos -> Next -> Select subject -> Next -> Pick date -> Next
7. Review -> Tap "Share"
8. Verify "Notes Shared!" overlay appears
9. Verify new post appears in Notes tab

**Flow 2: Request Notes**
1. From group feed, switch to "Requests" tab
2. Tap "Ask for Notes" floating button
3. Select subject -> Next -> Pick date -> Next -> Choose "Everyone" or specific member -> Next
4. Add optional message -> Tap "Ask"
5. Verify request appears in Requests tab

**Flow 3: Custom Subjects**
1. From "Share Notes" or "Ask for Notes", on the subject step
2. Tap "+ Add Subject" dashed button
3. Enter name, pick color, pick icon
4. Verify "Subject Added!" confirmation
5. New subject should appear in the subject grid

**Flow 4: Group Management**
1. From groups list, tap "+" menu -> "Create Group"
2. Enter class name + school name -> Create
3. Verify invite code shown + can copy
4. From groups list, tap "+" -> "Join Group"
5. Enter invite code -> Join -> Verify success
6. Open group -> Tap info (i) button
7. Verify member count is correct
8. Test "Leave Group" (non-creator) or "Delete Group" (creator)

**Flow 5: Photo Visibility (requires real Firebase)**
1. User A uploads notes with photos
2. User B opens the same group
3. User B should see User A's photos in the Notes tab
4. If photos don't appear: check Firestore composite indexes are built (Firebase Console -> Firestore -> Indexes)

---

## iOS Troubleshooting

### Photos not visible to other users
**Root Cause**: Missing Firestore composite indexes. Queries with `whereField("groupId") + order(by: "createdAt")` require a composite index. Without it, snapshot listeners fail silently.
**Fix**: `firebase deploy --only firestore:indexes` and wait for indexes to build (check status in Firebase Console -> Firestore -> Indexes).

### Member count wrong after joining
**Root Cause**: `joinGroup()` was returning pre-join group data without waiting for Firestore writes. Fixed to use batch.commit() with completion handler and return updated members array.

### "Object does not exist" on photo upload
**Root Cause**: Firebase Storage was never enabled for the project. Must be enabled manually in Firebase Console -> Storage.

### Cloud Functions deployment fails (v1 -> v2 upgrade)
**Root Cause**: Cannot upgrade v1 functions to v2 in-place. Must delete v1 functions first:
```bash
firebase functions:delete onRequestCreated onPostCreated --force
firebase deploy --only functions
```
First-time v2 deployment may fail with "Eventarc Service Agent" permission error. Wait 2-3 minutes and retry.

### "No Accounts with App Store Connect Access" during export
**Root Cause**: Transient Xcode session issue. Retry the export command.

### xcodebuild can't find simulator
Available simulators change with Xcode/SDK updates. Check available destinations with:
```bash
xcodebuild -project ios/ClassNotes.xcodeproj -scheme ClassNotes -showdestinations
```
Current simulator: `iPhone 17 Pro` (iOS 26.2).

### Firebase Phone Auth crashes on device
`Info.plist` must have the URL scheme `app-1-577096727828-ios-c6e54a3334cc4cda98d601` in `CFBundleURLTypes`. This is derived from `GoogleService-Info.plist` GOOGLE_APP_ID with colons replaced by dashes.

---

## iOS Version History

| Build | Changes |
|-------|---------|
| 1-4 | Initial app, features, bug fixes |
| 5 | Leave group, delete group, delete request, custom subjects |
| 6 | Fixed test failures for custom subjects |
| 7 | Fixed Firebase Storage (was not enabled), rewrote StorageService |
| 8 | Image resizing, CachedAsyncImage, Firestore rules |
| 9 | Upload success feedback, Cloud Functions for notifications, demo data cleanup |
| 10 | Fixed photo visibility (composite indexes), fixed member count (joinGroup batch), snapshot listener error logging, Cloud Functions v2 deployed |

---
---

# Android App

## Android Architecture

### Pattern: MVVM with StateFlow Services + Jetpack Compose Navigation

```
ClassNotesApp (Application) -> AppMode.initialize() + FirebaseApp.initializeApp()
  -> MainActivity -> ClassNotesTheme -> ClassNotesNavHost
     -> Services created via remember {} (demo or real based on AppMode.isDemo)
     -> NavHost routes to composable screens

Services expose MutableStateFlow properties.
Screens collect via .collectAsState() for reactive UI updates.
Services talk to Firebase directly. No repository layer (mirrors iOS architecture).
```

### iOS-to-Android Architecture Mapping

| iOS Concept | Android Equivalent |
|---|---|
| SwiftUI | Jetpack Compose |
| `@Published` / `ObservableObject` | `MutableStateFlow` / `StateFlow` |
| `@EnvironmentObject` | Services passed as parameters via `remember {}` in NavGraph |
| `NavigationStack` | `NavHost` + `NavController` (Compose Navigation) |
| `PhotosPicker` | `ActivityResultContracts.PickMultipleVisualMedia` |
| `UIImage` + `jpegData()` | `Bitmap` + `compress(JPEG, quality)` |
| NSCache + URLCache | Coil (automatic memory + disk caching) |
| `#if targetEnvironment(simulator)` | File-based: `/sdcard/classnotes_demo_mode` |

---

## Android Project Structure

```
android/
├── app/
│   ├── build.gradle.kts              # App build config, dependencies
│   ├── google-services.json          # Firebase config (DO NOT commit)
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml    # Permissions: INTERNET, CAMERA, READ_EXTERNAL_STORAGE
│       │   ├── java/com/classnotes/app/
│       │   │   ├── ClassNotesApp.kt   # Application class: AppMode.initialize() + Firebase init
│       │   │   ├── MainActivity.kt    # Single activity: enableEdgeToEdge() + ClassNotesNavHost
│       │   │   ├── AppMode.kt         # Demo mode toggle via /sdcard/classnotes_demo_mode file
│       │   │   ├── model/
│       │   │   │   ├── AppUser.kt     # data class (id, phone, name, groups, fcmToken)
│       │   │   │   ├── ClassGroup.kt  # data class (members, inviteCode, customSubjects, allSubjects)
│       │   │   │   ├── Post.kt        # data class + PostComment + PostReaction, subjectInfo(group)
│       │   │   │   ├── NoteRequest.kt # data class + RequestResponse + RequestStatus enum
│       │   │   │   ├── Subject.kt     # enum class (rawValue, color, icon) - 6 built-in subjects
│       │   │   │   └── SubjectInfo.kt # Unified wrapper: builtInSubjects + custom, find(), colorFromName(), iconFromName()
│       │   │   ├── service/
│       │   │   │   ├── AuthService.kt          # Firebase Phone Auth + user profile (open class for demo override)
│       │   │   │   ├── GroupService.kt          # CRUD groups, join/leave, custom subjects
│       │   │   │   ├── PostService.kt           # CRUD posts, snapshot listener, comments, reactions
│       │   │   │   ├── RequestService.kt        # CRUD requests, respond, mark fulfilled
│       │   │   │   ├── StorageService.kt        # Image upload: resize (max 1600px) + JPEG 60% + retry
│       │   │   │   ├── NotificationService.kt   # FCM token management
│       │   │   │   └── demo/
│       │   │   │       ├── DemoData.kt           # 7 users, 2 groups, 6 posts, 4 requests (picsum.photos)
│       │   │   │       ├── DemoAuthService.kt    # In-memory auth (extends AuthService)
│       │   │   │       ├── DemoGroupService.kt   # In-memory groups (extends GroupService)
│       │   │   │       ├── DemoPostService.kt    # In-memory posts with comments/reactions (extends PostService)
│       │   │   │       └── DemoRequestService.kt # In-memory requests (extends RequestService)
│       │   │   ├── ui/
│       │   │   │   ├── auth/
│       │   │   │   │   ├── LoginScreen.kt        # Phone number + OTP with country code picker
│       │   │   │   │   └── OnboardingScreen.kt   # Name entry
│       │   │   │   ├── groups/
│       │   │   │   │   ├── GroupsListScreen.kt   # Groups list with create/join/settings
│       │   │   │   │   ├── CreateGroupScreen.kt  # Create group form
│       │   │   │   │   ├── JoinGroupScreen.kt    # Join by invite code
│       │   │   │   │   └── GroupInfoScreen.kt    # Members, invite code, leave/delete group
│       │   │   │   ├── feed/
│       │   │   │   │   ├── GroupFeedScreen.kt    # Notes/Requests tabs, subject filter chips, pull-to-refresh
│       │   │   │   │   ├── PostDetailScreen.kt   # Full post view with comments, reactions, all photos
│       │   │   │   │   └── CreatePostScreen.kt   # Multi-step wizard: Photos -> Subject -> Date -> Review
│       │   │   │   ├── requests/
│       │   │   │   │   ├── CreateRequestScreen.kt # Multi-step: Subject -> Date -> Target -> Message
│       │   │   │   │   └── RequestDetailScreen.kt # Detail + respond with photos
│       │   │   │   ├── common/
│       │   │   │   │   ├── PhotoViewerScreen.kt  # HorizontalPager with pinch-to-zoom + pan
│       │   │   │   │   └── AddCustomSubjectScreen.kt # Custom subject creation
│       │   │   │   ├── settings/
│       │   │   │   │   └── SettingsScreen.kt     # Sign out, delete account, version info
│       │   │   │   ├── navigation/
│       │   │   │   │   └── NavGraph.kt           # All routes, Screen sealed class, PhotoViewerState
│       │   │   │   └── theme/
│       │   │   │       ├── Color.kt              # Subject colors + app palette
│       │   │   │       ├── Theme.kt              # Material3 dynamic color theme
│       │   │   │       └── Type.kt               # Typography definitions
│       │   │   └── util/
│       │   │       └── DateExtensions.kt         # displayString(), shortDisplayString(), relativeString(), daysAgo()
│       │   └── res/
│       │       ├── drawable/classnotes_logo.xml   # App logo (vector drawable)
│       │       └── values/                        # strings, themes, colors
│       ├── test/                                  # Unit tests (Robolectric)
│       │   ├── java/com/classnotes/app/
│       │   │   ├── model/
│       │   │   │   ├── AppUserTest.kt            # 6 tests
│       │   │   │   ├── ClassGroupTest.kt         # 9 tests
│       │   │   │   ├── PostTest.kt               # 11 tests
│       │   │   │   ├── NoteRequestTest.kt        # 12 tests
│       │   │   │   ├── SubjectTest.kt            # 7 tests
│       │   │   │   └── SubjectInfoTest.kt        # 21 tests
│       │   │   ├── service/demo/
│       │   │   │   ├── DemoDataTest.kt           # 25 tests (data integrity, referential integrity)
│       │   │   │   ├── DemoAuthServiceTest.kt    # 14 tests (full auth flow)
│       │   │   │   ├── DemoGroupServiceTest.kt   # 10 tests
│       │   │   │   ├── DemoPostServiceTest.kt    # 13 tests (comments, reactions)
│       │   │   │   └── DemoRequestServiceTest.kt # 9 tests
│       │   │   └── util/
│       │   │       └── DateExtensionsTest.kt     # 15 tests
│       │   └── resources/
│       │       └── robolectric.properties        # sdk=34
│       └── androidTest/                          # Instrumented UI tests
│           └── java/com/classnotes/app/
│               └── ClassNotesE2ETest.kt          # 7 E2E test methods (full demo flow)
├── gradle/
│   └── libs.versions.toml                        # Version catalog
├── build.gradle.kts                              # Root build config
├── settings.gradle.kts                           # Project settings
└── gradlew / gradlew.bat                         # Gradle wrapper
```

---

## Android Demo Mode

Controlled by file presence: `/sdcard/classnotes_demo_mode`

```bash
# Enable demo mode
adb shell "touch /sdcard/classnotes_demo_mode"

# Disable demo mode
adb shell "rm /sdcard/classnotes_demo_mode"
```

When `AppMode.isDemo == true`:
- `ClassNotesNavHost` creates `DemoAuthService`, `DemoGroupService`, `DemoPostService`, `DemoRequestService` instead of real Firebase services
- `DemoData` object provides same sample data as iOS: 7 users, 2 groups, 6 posts, 4 requests
- Demo photos use `picsum.photos` placeholder URLs
- Phone: `9876543210`, OTP: `123456` (any 6 digits), Name: `Aditi's Mom`
- Firebase is still initialized (so switching modes doesn't require reinstall)

---

## Android Navigation

All navigation is defined in `NavGraph.kt` via a `Screen` sealed class:

| Route | Screen | Parameters |
|-------|--------|------------|
| `login` | LoginScreen | - |
| `onboarding` | OnboardingScreen | - |
| `groups_list` | GroupsListScreen | - |
| `create_group` | CreateGroupScreen | - |
| `join_group` | JoinGroupScreen | - |
| `group_feed/{groupId}` | GroupFeedScreen | groupId: String |
| `post_detail/{postId}/{groupId}` | PostDetailScreen | postId, groupId |
| `create_post/{groupId}` | CreatePostScreen | groupId |
| `request_detail/{requestId}/{groupId}` | RequestDetailScreen | requestId, groupId |
| `create_request/{groupId}` | CreateRequestScreen | groupId |
| `photo_viewer/{startIndex}` | PhotoViewerScreen | startIndex: Int |
| `settings` | SettingsScreen | - |
| `group_info/{groupId}` | GroupInfoScreen | groupId |
| `add_custom_subject/{groupId}` | AddCustomSubjectScreen | groupId |

**PhotoViewerState**: Photo URLs are too long for nav arguments, so `PhotoViewerState.photoURLs` (a singleton `List<String>`) is set before navigation and read by `PhotoViewerScreen`.

---

## Android Service Layer

All services use `open class` so demo services can extend and override them.

### State Management Pattern
```kotlin
// Base service exposes StateFlow
open class PostService {
    protected val _posts = MutableStateFlow<List<Post>>(emptyList())
    val posts: StateFlow<List<Post>> = _posts
    // ...
}

// Demo service overrides methods with in-memory logic
class DemoPostService : PostService() {
    override suspend fun loadPosts(groupId: String) {
        _posts.value = DemoData.posts.filter { it.groupId == groupId }
    }
}

// Screen collects state
@Composable fun GroupFeedScreen(postService: PostService) {
    val posts by postService.posts.collectAsState()
    // UI renders from posts
}
```

### AuthService
- Firebase Phone Auth with `PhoneAuthProvider`
- `activity` reference needed for reCAPTCHA verification
- Auth state listener auto-updates `isAuthenticated`, `currentUserId`, `currentUserName`
- `init` block guarded by `if (!AppMode.isDemo)` to avoid Firebase calls in demo mode
- Lazy `auth`/`db` properties return null in demo mode

### StorageService
- Singleton `object` (not a class)
- `uploadImages()`: parallel upload via `coroutineScope { async {} }.awaitAll()`
- Resize to max 1600px, JPEG quality 60%
- Download URL retry: up to 3 attempts with 1s/2s/3s delays
- `deleteImages()`: fire-and-forget cleanup

---

## Android Key Implementation Details

### PhotoViewer Gesture Handling (CRITICAL)

The `PhotoViewerScreen` uses `HorizontalPager` with per-page pinch-to-zoom. The gesture system uses low-level `awaitEachGesture` instead of `detectTransformGestures` because the latter consumes ALL touch events, blocking the pager from handling single-finger swipes.

**Key logic:**
- 2+ fingers: pinch-to-zoom + pan, events consumed (prevents pager scroll during pinch)
- 1 finger + zoomed (scale > 1f): pan around image, events consumed
- 1 finger + not zoomed (scale == 1f): events NOT consumed, pager handles swipe
- Double-tap: toggle between 1x and 3x zoom
- Scale resets when swiping to a different page via `LaunchedEffect(pagerState.currentPage)`

**Why `detectTransformGestures` doesn't work:** It's a high-level API that calls `consume()` on all pointer events internally, even when the handler takes no action. This prevents the pager from ever receiving single-finger swipe events.

### Image Loading
- Uses Coil (`AsyncImage`) for all image loading with automatic caching
- No custom cache layer needed (unlike iOS NSCache approach)
- Coil handles memory cache + disk cache automatically

### Subject Colors and Icons
- `Subject` enum uses Compose `Color` and `ImageVector` directly
- This means **all unit tests that reference Subject/SubjectInfo require Robolectric** (Compose types need Android framework)
- `SubjectInfo.colorFromName()` and `SubjectInfo.iconFromName()` map string names to Compose values

### Post Model - Dual Constructors
`Post` has two constructors:
- Primary: takes `subjectName: String` (matches Firestore field)
- Convenience: takes `subject: Subject` enum, internally converts via `subject.rawValue`
- `subjectInfo(group)` resolves to full `SubjectInfo` using group's custom subjects

### Pull-to-Refresh
`GroupFeedScreen` uses `PullToRefreshBox` (Material3) wrapping the content. Refresh reloads both posts and requests for the current group.

---

## Android Build Environment

### Prerequisites
```bash
export JAVA_HOME="/Users/prashant/local/jdk-17.0.2.jdk/Contents/Home"
export ANDROID_HOME="/Users/prashant/local/android-sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

- **JDK**: 17.0.2 (required for AGP 8.7.3)
- **Android SDK**: API 35 (compile + target)
- **Kotlin**: 2.0.21 with Compose compiler plugin
- **Gradle**: wrapper-managed (no global install needed)
- **Compose BOM**: 2024.12.01

### Key Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| Compose BOM | 2024.12.01 | Material3, UI, Navigation |
| Firebase BOM | 33.7.0 | Auth, Firestore, Storage, Messaging |
| Coil | 2.7.0 | Image loading + caching |
| Accompanist Permissions | 0.36.0 | Runtime permission handling |
| Navigation Compose | 2.8.5 | Declarative navigation |
| Robolectric | 4.14.1 | Unit test Android framework mocking |
| Coroutines Test | 1.9.0 | `runTest` for suspend function tests |

### Build Commands

```bash
cd /Users/prashant/Projects/ClassNotes/android

# Build debug APK
./gradlew assembleDebug

# Run unit tests (152 tests)
./gradlew testDebugUnitTest

# Run instrumented UI tests (requires running emulator)
./gradlew connectedAndroidTest

# Clean build
./gradlew clean assembleDebug
```

### Emulator Setup

```bash
# Create AVD (already created: ClassNotes_Pixel7)
avdmanager create avd -n ClassNotes_Pixel7 -k "system-images;android-35;google_apis;arm64-v8a" -d pixel_7

# Fix keyboard input
# Edit ~/.android/avd/ClassNotes_Pixel7.avd/config.ini:
# hw.keyboard = yes

# Start emulator
emulator -avd ClassNotes_Pixel7

# Install APK
adb install app/build/outputs/apk/debug/app-debug.apk

# Enable demo mode + restart app
adb shell "touch /sdcard/classnotes_demo_mode"
adb shell am force-stop com.classnotes.app
adb shell am start -n com.classnotes.app/.MainActivity
```

---

## Android Testing

### Unit Tests (152 tests, Robolectric)

All unit tests use `@RunWith(RobolectricTestRunner::class)` because `Subject` and `SubjectInfo` reference Compose types (`ImageVector`, `Color`). Configuration: `src/test/resources/robolectric.properties` with `sdk=34`.

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `AppUserTest` | 6 | Creation, defaults, equality, copy |
| `ClassGroupTest` | 9 | Invite code generation/validation, customSubjectInfos, allSubjects |
| `PostTest` | 11 | Enum/string constructors, subjectInfo resolution, comments, reactions |
| `NoteRequestTest` | 12 | Creation, targeting, RequestStatus, responses, subjectInfo |
| `SubjectTest` | 7 | rawValues, fromRawValue, uniqueness, colors, icons |
| `SubjectInfoTest` | 21 | builtInSubjects, custom creation, firestoreDict, find() priority, equality |
| `DateExtensionsTest` | 15 | displayString, shortDisplayString, relativeString, daysAgo |
| `DemoDataTest` | 25 | Data integrity, referential integrity, custom subjects, mixed statuses |
| `DemoAuthServiceTest` | 14 | Full auth flow, OTP, onboarding, signOut, deleteAccount |
| `DemoGroupServiceTest` | 10 | loadGroups, createGroup, joinGroup, leaveGroup, deleteGroup |
| `DemoPostServiceTest` | 13 | loadPosts, createPost, deletePost, comments, reactions |
| `DemoRequestServiceTest` | 9 | loadRequests, createRequest, respondToRequest, deleteRequest |

Run: `./gradlew testDebugUnitTest`
Results: `app/build/test-results/testDebugUnitTest/`

### Instrumented UI Tests (7 tests)

`ClassNotesE2ETest.kt` uses `createAndroidComposeRule<MainActivity>()`:

1. **testLoginScreenElements** - Verifies login screen UI elements
2. **testFullDemoFlow** - Login -> OTP -> Onboarding -> Groups -> Feed -> Filters -> Requests -> Back
3. **testSettingsFlow** - Navigate to Settings, verify elements
4. **testGroupInfoFlow** - Navigate to Group Info, verify members
5. **testPostDetailFlow** - Navigate to Post Detail, verify content
6. **testPullToRefreshOnNotes** - Pull-to-refresh on Notes tab
7. **testPullToRefreshOnRequests** - Pull-to-refresh on Requests tab

Requires: running emulator with demo mode enabled.
Run: `./gradlew connectedAndroidTest`

---

## Android Troubleshooting

### Unit tests fail with "Method myPid in android.os.Process not mocked"
**Root Cause**: Test class references Android/Compose types without Robolectric.
**Fix**: Add `@RunWith(RobolectricTestRunner::class)` to the test class. Ensure `robolectric.properties` exists in `src/test/resources/` with `sdk=34`.

### PhotoViewer swipe between photos not working
**Root Cause**: `detectTransformGestures` consumes all pointer events, blocking `HorizontalPager` from handling swipe gestures.
**Fix**: Replace with `awaitEachGesture` + `awaitPointerEvent` for manual event handling. Only consume events when zoomed or pinching.

### Emulator keyboard doesn't work
**Fix**: Edit `~/.android/avd/<avd-name>.avd/config.ini` and set `hw.keyboard = yes`. Restart emulator.

### App crashes on startup (Firebase)
**Root Cause**: Missing `google-services.json` in `app/` directory.
**Fix**: Download from Firebase Console -> Project Settings -> Android app -> Download `google-services.json`.

### Demo mode not activating
**Fix**: Ensure the demo mode file exists and app is restarted:
```bash
adb shell "touch /sdcard/classnotes_demo_mode"
adb shell am force-stop com.classnotes.app
adb shell am start -n com.classnotes.app/.MainActivity
```

### Gradle build fails with JDK error
**Fix**: Ensure `JAVA_HOME` points to JDK 17:
```bash
export JAVA_HOME="/Users/prashant/local/jdk-17.0.2.jdk/Contents/Home"
```
