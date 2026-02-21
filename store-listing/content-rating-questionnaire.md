# Content Rating Questionnaire Answers

## For Apple App Store (Age Rating)

When submitting in App Store Connect, answer these questions:

| Question | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

**Expected Rating: 4+ (Everyone)**

---

## For Google Play Store (IARC Rating)

Go to: Play Console > Content Rating > Start Questionnaire

### Category Selection
- **Primary category:** Education
- **App type:** Utility / Productivity / Education

### Questionnaire Answers

| Question | Answer |
|----------|--------|
| Does the app contain violence? | No |
| Does the app contain sexual content? | No |
| Does the app contain profanity or crude humor? | No |
| Does the app contain drug references? | No |
| Does the app contain gambling? | No |
| Does the app allow users to interact or exchange content? | **Yes** (users can share photos and text within groups) |
| Does the app share the user's current location? | No |
| Does the app allow purchases? | No |
| Does the app contain ads? | No |

**Expected Rating: PEGI 3 / Everyone / IARC 3+**

> Note: Because users can share photos and text with each other, the store may add a "User Interaction" content descriptor. This is normal for any app with user-generated content.

---

## Target Audience and Content Declarations

### For Google Play Store

**Target Age Group:**
- Select: **Adults only (18+)** for target audience
- This is because the app is designed for parents and teachers, NOT for children
- Even though the content is about school, the *users* are adults

**Appeals to Children Declaration:**
- Does the app appeal to children? **No**
- The app requires a phone number for sign-in (adults only)
- No child-attractive game mechanics, characters, or animations
- App is a utility for parents to coordinate

**Data Safety Section (Google Play):**

| Question | Answer |
|----------|--------|
| Does your app collect or share any user data? | Yes |
| **Data collected:** | |
| - Phone number | Yes - for authentication |
| - Name | Yes - user-provided display name |
| - Photos | Yes - user-uploaded class note photos |
| Is data encrypted in transit? | Yes (HTTPS/TLS) |
| Can users request data deletion? | Yes (Delete Account in Settings) |
| **Data shared with third parties?** | No |
| **Data used for advertising?** | No |
| **Data used for analytics?** | No |

### For Apple App Store

**App Privacy (Nutrition Labels):**

| Data Type | Collected? | Linked to Identity? | Used for Tracking? |
|-----------|-----------|---------------------|-------------------|
| Phone Number | Yes | Yes | No |
| Name | Yes | Yes | No |
| Photos | Yes | Yes | No |
| Device ID (FCM Token) | Yes | No | No |

**Purpose for all data:** App Functionality

---

## Additional Store Requirements

### Apple - App Review Notes
```
ClassNotes is an app for parents and teachers to share class notes
within school groups.

For testing, the app runs in Demo Mode on the simulator with
pre-populated sample data:
- Phone: 9876543210
- OTP: 123456 (any 6 digits)
- Name: Aditi's Mom

The app uses Firebase Phone Auth for sign-in. On real devices,
a real phone number is needed to receive an SMS verification code.
```

### Google Play - App Access Instructions
```
The app requires phone number verification to sign in. For testing,
you can use Firebase Auth test phone numbers configured in the
Firebase Console, or a real phone number.

Contact prashantkulkarni.nm@gmail.com for a test account if needed.
```
