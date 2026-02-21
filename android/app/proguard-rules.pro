# ClassNotes ProGuard Rules
-keepattributes Signature
-keepattributes *Annotation*

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep data classes for Firestore serialization
-keep class com.classnotes.app.model.** { *; }
