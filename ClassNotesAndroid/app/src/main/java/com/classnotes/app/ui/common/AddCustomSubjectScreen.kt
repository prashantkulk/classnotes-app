package com.classnotes.app.ui.common

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.model.SubjectInfo
import com.classnotes.app.service.GroupService
import com.classnotes.app.ui.theme.Teal
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddCustomSubjectScreen(
    group: ClassGroup,
    groupService: GroupService,
    onCreated: (SubjectInfo) -> Unit,
    onDismiss: () -> Unit
) {
    var subjectName by remember { mutableStateOf("") }
    var selectedColorName by remember { mutableStateOf("teal") }
    var selectedIconName by remember { mutableStateOf("book") }
    var isLoading by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()
    val selectedColor = SubjectInfo.colorFromName(selectedColorName)
    val selectedIcon = SubjectInfo.iconFromName(selectedIconName)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Subject") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            val trimmedName = subjectName.trim()
                            if (trimmedName.isEmpty()) return@TextButton

                            // Check for duplicate
                            val existingNames = group.allSubjects.map { it.name.lowercase() }
                            if (existingNames.contains(trimmedName.lowercase())) {
                                errorMessage = "A subject named \"$trimmedName\" already exists."
                                return@TextButton
                            }

                            isLoading = true
                            val subject = SubjectInfo(
                                name = trimmedName,
                                colorName = selectedColorName,
                                iconName = selectedIconName
                            )
                            scope.launch {
                                try {
                                    groupService.addCustomSubject(group.id, subject)
                                    onCreated(subject)
                                    showSuccess = true
                                    delay(1200)
                                    onDismiss()
                                } catch (e: Exception) {
                                    errorMessage = e.message
                                }
                                isLoading = false
                            }
                        },
                        enabled = subjectName.trim().isNotEmpty() && !isLoading
                    ) {
                        Text("Add", fontWeight = FontWeight.SemiBold, color = Teal)
                    }
                }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp, vertical = 16.dp)
            ) {
                // Subject name
                Text(
                    "Subject Name",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(6.dp))
                OutlinedTextField(
                    value = subjectName,
                    onValueChange = { subjectName = it },
                    placeholder = { Text("e.g. Art, Music, PE") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        unfocusedBorderColor = Color.Transparent,
                        focusedBorderColor = Teal
                    )
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Color picker
                Text(
                    "Color",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(6.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    SubjectInfo.customColorOptions.forEach { (colorName, color) ->
                        val isSelected = selectedColorName == colorName
                        Surface(
                            modifier = Modifier.size(36.dp),
                            shape = CircleShape,
                            color = color,
                            onClick = { selectedColorName = colorName },
                            border = if (isSelected) ButtonDefaults.outlinedButtonBorder.copy(
                                width = 2.5.dp,
                                brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.onSurface)
                            ) else null
                        ) {
                            if (isSelected) {
                                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                                    Icon(
                                        Icons.Filled.Check,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp),
                                        tint = Color.White
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Icon picker
                Text(
                    "Icon",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(6.dp))
                LazyVerticalGrid(
                    columns = GridCells.Fixed(6),
                    modifier = Modifier.fillMaxWidth().heightIn(max = 200.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(SubjectInfo.customIconOptions) { (iconName, icon) ->
                        val isSelected = selectedIconName == iconName
                        Surface(
                            modifier = Modifier.size(48.dp),
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) selectedColor.copy(alpha = 0.15f)
                            else MaterialTheme.colorScheme.surfaceVariant,
                            onClick = { selectedIconName = iconName },
                            border = if (isSelected) ButtonDefaults.outlinedButtonBorder.copy(
                                brush = androidx.compose.ui.graphics.SolidColor(selectedColor)
                            ) else null
                        ) {
                            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                                Icon(
                                    icon,
                                    contentDescription = null,
                                    modifier = Modifier.size(24.dp),
                                    tint = if (isSelected) selectedColor else MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Preview
                if (subjectName.trim().isNotEmpty()) {
                    Text(
                        "Preview",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = selectedColor.copy(alpha = 0.1f),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                selectedIcon,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = selectedColor
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                subjectName.trim(),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            // Success overlay
            AnimatedVisibility(
                visible = showSuccess,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                ) {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Filled.CheckCircle,
                            contentDescription = null,
                            modifier = Modifier.size(56.dp),
                            tint = Color(0xFF4CAF50)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            "Subject Added!",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }
    }

    // Error dialog
    if (errorMessage != null) {
        AlertDialog(
            onDismissRequest = { errorMessage = null },
            title = { Text("Failed to Add Subject") },
            text = { Text(errorMessage ?: "Something went wrong. Please try again.") },
            confirmButton = {
                TextButton(onClick = { errorMessage = null }) {
                    Text("OK")
                }
            }
        )
    }
}
