package com.classnotes.app.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Abc
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Functions
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Translate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.classnotes.app.ui.theme.SubjectBlue
import com.classnotes.app.ui.theme.SubjectGray
import com.classnotes.app.ui.theme.SubjectGreen
import com.classnotes.app.ui.theme.SubjectHindiOrange
import com.classnotes.app.ui.theme.SubjectOrange
import com.classnotes.app.ui.theme.SubjectPurple

enum class Subject(
    val rawValue: String,
    val color: Color,
    val icon: ImageVector
) {
    MATH("Math", SubjectBlue, Icons.Filled.Functions),
    SCIENCE("Science", SubjectGreen, Icons.Filled.Science),
    ENGLISH("English", SubjectOrange, Icons.Filled.Abc),
    HINDI("Hindi", SubjectHindiOrange, Icons.Filled.Translate),
    SOCIAL_STUDIES("Social Studies", SubjectPurple, Icons.Filled.Public),
    OTHER("Other", SubjectGray, Icons.Filled.Description);

    companion object {
        fun fromRawValue(value: String): Subject? = entries.find { it.rawValue == value }
    }
}
