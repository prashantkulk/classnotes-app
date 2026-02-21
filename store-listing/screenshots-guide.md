# Screenshots Guide

## Available Screenshots

All screenshots are in `/screenshots/` directory, captured from iPhone 17 Pro simulator (1206x2622 px).

| File | Screen | Recommended Caption |
|------|--------|-------------------|
| `01_Login_Screen.png` | Login | Sign in with your phone number |
| `02_Groups_List.png` | Groups List | Join your child's class group |
| `03_Group_Feed.png` | Notes Feed | Browse shared notes by subject |
| `04_Note_Detail.png` | Note Detail | View notes with comments & reactions |
| `05_Requests_Tab.png` | Requests | Request notes when your child is absent |
| `06_Request_Detail.png` | Request Detail | Respond to requests with photos |
| `07_Group_Info.png` | Group Info | Manage members and invite parents |
| `08_Settings.png` | Settings | Your account settings |

## Recommended Order for Store Listings

### App Store (upload 5-8 screenshots):
1. `03_Group_Feed.png` - **Lead with the main experience**
2. `05_Requests_Tab.png` - Show the request feature
3. `04_Note_Detail.png` - Show detail view
4. `07_Group_Info.png` - Show group management
5. `02_Groups_List.png` - Show multi-group support
6. `01_Login_Screen.png` - Show simple sign-in (optional)

### Google Play (upload 4-8 screenshots):
Same order as above. Google Play accepts phone screenshots directly.

## Screenshot Sizes

- **iOS App Store:** 1206x2622 px (iPhone 6.7" display) - our screenshots match
- **Google Play:** Min 320px, max 3840px on any side. 16:9 or 9:16 aspect ratio preferred. Our iOS screenshots work but you may want to capture Android-specific ones from the emulator.

## App Icon

- **iOS:** `ClassNotes/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024x1024)
- **Android:** Auto-generated adaptive icon from `res/mipmap-*` directories
- **Google Play Store icon:** Must be 512x512 PNG. You can resize the iOS AppIcon.png.

### To create a 512x512 icon for Google Play:
```bash
sips -z 512 512 ClassNotes/Assets.xcassets/AppIcon.appiconset/AppIcon.png --out store-listing/play-store-icon-512.png
```
