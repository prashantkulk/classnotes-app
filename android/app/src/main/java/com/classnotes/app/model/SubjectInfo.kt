package com.classnotes.app.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Architecture
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Laptop
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.classnotes.app.ui.theme.CustomBrown
import com.classnotes.app.ui.theme.CustomCyan
import com.classnotes.app.ui.theme.CustomIndigo
import com.classnotes.app.ui.theme.CustomMint
import com.classnotes.app.ui.theme.CustomPink
import com.classnotes.app.ui.theme.CustomRed
import com.classnotes.app.ui.theme.CustomTeal
import com.classnotes.app.ui.theme.CustomYellow
import com.classnotes.app.ui.theme.SubjectGray

data class SubjectInfo private constructor(
    val name: String,
    val color: Color,
    val icon: ImageVector,
    val isBuiltIn: Boolean,
    private val _colorName: String,
    private val _iconName: String
) {
    /** Create from a built-in [Subject] enum value. */
    constructor(from: Subject) : this(
        name = from.rawValue,
        color = from.color,
        icon = from.icon,
        isBuiltIn = true,
        _colorName = when (from) {
            Subject.MATH -> "blue"
            Subject.SCIENCE -> "green"
            Subject.ENGLISH -> "orange"
            Subject.HINDI -> "orange"
            Subject.SOCIAL_STUDIES -> "purple"
            Subject.OTHER -> "gray"
        },
        _iconName = when (from) {
            Subject.MATH -> "function"
            Subject.SCIENCE -> "science"
            Subject.ENGLISH -> "abc"
            Subject.HINDI -> "translate"
            Subject.SOCIAL_STUDIES -> "public"
            Subject.OTHER -> "description"
        }
    )

    /** Create from a custom subject stored in Firestore. */
    constructor(name: String, colorName: String, iconName: String) : this(
        name = name,
        color = colorFromName(colorName),
        icon = iconFromName(iconName),
        isBuiltIn = false,
        _colorName = colorName,
        _iconName = iconName
    )

    /** The color name string suitable for Firestore storage. */
    val colorNameString: String get() = _colorName

    /** The icon name string suitable for Firestore storage. */
    val iconNameString: String get() = _iconName

    /** Dictionary representation for writing to Firestore. */
    val firestoreDict: Map<String, String>
        get() = mapOf("name" to name, "color" to _colorName, "icon" to _iconName)

    // Equality based on name only (matching iOS behavior)
    override fun equals(other: Any?): Boolean = other is SubjectInfo && other.name == name
    override fun hashCode(): Int = name.hashCode()

    companion object {
        /** All built-in subjects as [SubjectInfo] instances. */
        val builtInSubjects: List<SubjectInfo> = Subject.entries.map { SubjectInfo(it) }

        /**
         * Find a [SubjectInfo] by name, checking built-in subjects first,
         * then falling back to the provided custom subjects list.
         */
        fun find(name: String, customSubjects: List<SubjectInfo>): SubjectInfo? {
            Subject.fromRawValue(name)?.let { return SubjectInfo(it) }
            return customSubjects.find { it.name == name }
        }

        /** Available color options for custom subjects. */
        val customColorOptions: List<Pair<String, Color>> = listOf(
            "red" to CustomRed,
            "pink" to CustomPink,
            "indigo" to CustomIndigo,
            "teal" to CustomTeal,
            "cyan" to CustomCyan,
            "mint" to CustomMint,
            "brown" to CustomBrown,
            "yellow" to CustomYellow
        )

        /** Available icon options for custom subjects. */
        val customIconOptions: List<Pair<String, ImageVector>> = listOf(
            "book" to Icons.Filled.Book,
            "architecture" to Icons.Filled.Architecture,
            "brush" to Icons.Filled.Brush,
            "music_note" to Icons.Filled.MusicNote,
            "sports_soccer" to Icons.Filled.SportsSoccer,
            "language" to Icons.Filled.Language,
            "laptop" to Icons.Filled.Laptop,
            "build" to Icons.Filled.Build,
            "eco" to Icons.Filled.Eco,
            "favorite" to Icons.Filled.Favorite,
            "star" to Icons.Filled.Star,
            "flag" to Icons.Filled.Flag
        )

        /** Resolve a color name string to a Compose [Color]. */
        fun colorFromName(name: String): Color =
            customColorOptions.find { it.first == name }?.second ?: SubjectGray

        /** Resolve an icon name string to a Material [ImageVector]. */
        fun iconFromName(name: String): ImageVector =
            customIconOptions.find { it.first == name }?.second ?: Icons.Filled.Description
    }
}
