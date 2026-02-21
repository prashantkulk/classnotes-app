package com.classnotes.app.ui.feed

import android.net.Uri
import android.os.Environment
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.classnotes.app.model.*
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.PostService
import com.classnotes.app.ui.theme.Teal
import com.classnotes.app.util.displayString
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File
import java.util.Calendar
import java.util.Date

enum class CreatePostStep(val title: String) {
    PHOTOS("Select Photos"),
    SUBJECT("Which Subject?"),
    DATE("Which Date?"),
    REVIEW("Review & Share")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatePostScreen(
    groupId: String,
    authService: AuthService,
    groupService: GroupService,
    postService: PostService,
    onDismiss: () -> Unit
) {
    val groups by groupService.groups.collectAsState()
    val group = groups.find { it.id == groupId } ?: return
    val currentUserId by authService.currentUserId.collectAsState()
    val currentUserName by authService.currentUserName.collectAsState()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var currentStep by remember { mutableStateOf(CreatePostStep.PHOTOS) }
    var selectedPhotoUris by remember { mutableStateOf<List<Uri>>(emptyList()) }
    var selectedSubjectInfo by remember { mutableStateOf<SubjectInfo?>(null) }
    var selectedDate by remember { mutableStateOf(Date()) }
    var description by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Gallery picker
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickMultipleVisualMedia(10)
    ) { uris: List<Uri> ->
        if (uris.isNotEmpty()) {
            selectedPhotoUris = selectedPhotoUris + uris
        }
    }

    // Camera capture
    var cameraUri by remember { mutableStateOf<Uri?>(null) }
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success && cameraUri != null) {
            selectedPhotoUris = selectedPhotoUris + cameraUri!!
        }
    }

    val canProceed = when (currentStep) {
        CreatePostStep.PHOTOS -> selectedPhotoUris.isNotEmpty()
        CreatePostStep.SUBJECT -> selectedSubjectInfo != null
        CreatePostStep.DATE -> true
        CreatePostStep.REVIEW -> true
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(currentStep.title) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Progress dots
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
                    horizontalArrangement = Arrangement.Center
                ) {
                    CreatePostStep.entries.forEachIndexed { index, step ->
                        Surface(
                            modifier = Modifier.size(10.dp),
                            shape = RoundedCornerShape(50),
                            color = if (step.ordinal <= currentStep.ordinal) Teal else MaterialTheme.colorScheme.outlineVariant
                        ) {}
                        if (index < CreatePostStep.entries.size - 1) Spacer(modifier = Modifier.width(8.dp))
                    }
                }

                // Step content
                Box(modifier = Modifier.weight(1f)) {
                    when (currentStep) {
                        CreatePostStep.PHOTOS -> PhotosStep(
                            selectedUris = selectedPhotoUris,
                            onRemove = { uri -> selectedPhotoUris = selectedPhotoUris.filter { it != uri } },
                            onPickPhotos = {
                                photoPickerLauncher.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                )
                            },
                            onTakePhoto = {
                                val photoFile = File(
                                    context.getExternalFilesDir(Environment.DIRECTORY_PICTURES),
                                    "classnotes_${System.currentTimeMillis()}.jpg"
                                )
                                val uri = androidx.core.content.FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.fileprovider",
                                    photoFile
                                )
                                cameraUri = uri
                                cameraLauncher.launch(uri)
                            }
                        )
                        CreatePostStep.SUBJECT -> SubjectStep(
                            allSubjects = group.allSubjects,
                            selectedSubjectInfo = selectedSubjectInfo,
                            onSelect = { selectedSubjectInfo = it }
                        )
                        CreatePostStep.DATE -> DateStep(
                            selectedDate = selectedDate,
                            onDateSelected = { selectedDate = it }
                        )
                        CreatePostStep.REVIEW -> ReviewStep(
                            selectedSubjectInfo = selectedSubjectInfo,
                            selectedDate = selectedDate,
                            photoCount = selectedPhotoUris.size,
                            photoUris = selectedPhotoUris,
                            description = description,
                            onDescriptionChange = { description = it }
                        )
                    }
                }

                // Bottom buttons
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 24.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (currentStep != CreatePostStep.PHOTOS) {
                        OutlinedButton(
                            onClick = {
                                val prev = CreatePostStep.entries.getOrNull(currentStep.ordinal - 1)
                                if (prev != null) currentStep = prev
                            },
                            modifier = Modifier.weight(1f).height(56.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Teal)
                        ) {
                            Icon(Icons.Filled.ChevronLeft, contentDescription = null)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Back", style = MaterialTheme.typography.titleMedium)
                        }
                    }

                    if (currentStep == CreatePostStep.REVIEW) {
                        Button(
                            onClick = {
                                isLoading = true
                                scope.launch {
                                    try {
                                        postService.createPost(
                                            groupId = groupId,
                                            authorId = currentUserId,
                                            authorName = currentUserName,
                                            subjectName = selectedSubjectInfo?.name ?: "",
                                            date = selectedDate,
                                            description = description,
                                            imageUris = selectedPhotoUris
                                        )
                                        showSuccess = true
                                        delay(1500)
                                        onDismiss()
                                    } catch (e: Exception) {
                                        errorMessage = e.message
                                    }
                                    isLoading = false
                                }
                            },
                            modifier = Modifier.weight(1f).height(56.dp),
                            enabled = !isLoading,
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                        ) {
                            if (isLoading) {
                                CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White, strokeWidth = 2.dp)
                            } else {
                                Icon(Icons.Filled.Send, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Share", style = MaterialTheme.typography.titleMedium)
                            }
                        }
                    } else {
                        Button(
                            onClick = {
                                val next = CreatePostStep.entries.getOrNull(currentStep.ordinal + 1)
                                if (next != null) currentStep = next
                            },
                            modifier = Modifier.weight(1f).height(56.dp),
                            enabled = canProceed,
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Teal)
                        ) {
                            Text("Next", style = MaterialTheme.typography.titleMedium)
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(Icons.Filled.ChevronRight, contentDescription = null)
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
                            modifier = Modifier.size(64.dp),
                            tint = Color(0xFF4CAF50)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "Notes Shared!",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "Your notes have been uploaded successfully.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
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
            title = { Text("Upload Failed") },
            text = { Text(errorMessage ?: "Something went wrong. Please try again.") },
            confirmButton = {
                TextButton(onClick = { errorMessage = null }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
private fun PhotosStep(
    selectedUris: List<Uri>,
    onRemove: (Uri) -> Unit,
    onPickPhotos: () -> Unit,
    onTakePhoto: () -> Unit
) {
    if (selectedUris.isEmpty()) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                Icons.Filled.PhotoLibrary,
                contentDescription = null,
                modifier = Modifier.size(56.dp),
                tint = Teal.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                "Add photos of class notes",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Take Photo button
            Button(
                onClick = onTakePhoto,
                modifier = Modifier.fillMaxWidth(0.7f).height(56.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Teal)
            ) {
                Icon(Icons.Filled.CameraAlt, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Take Photo", style = MaterialTheme.typography.titleMedium)
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Choose from Gallery button
            OutlinedButton(
                onClick = onPickPhotos,
                modifier = Modifier.fillMaxWidth(0.7f).height(56.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Teal)
            ) {
                Icon(Icons.Filled.PhotoLibrary, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Choose from Gallery", style = MaterialTheme.typography.titleMedium)
            }
        }
    } else {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
        ) {
            // Photo grid
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier.fillMaxWidth().heightIn(max = 400.dp).padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(selectedUris) { uri ->
                    Box {
                        AsyncImage(
                            model = uri,
                            contentDescription = "Selected photo",
                            modifier = Modifier
                                .aspectRatio(0.75f)
                                .clip(RoundedCornerShape(10.dp)),
                            contentScale = ContentScale.Crop
                        )
                        IconButton(
                            onClick = { onRemove(uri) },
                            modifier = Modifier.align(Alignment.TopEnd).size(32.dp)
                        ) {
                            Icon(
                                Icons.Filled.Cancel,
                                contentDescription = "Remove",
                                tint = Color.White,
                                modifier = Modifier.size(24.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Add more buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                TextButton(onClick = onTakePhoto) {
                    Icon(Icons.Filled.CameraAlt, contentDescription = null, tint = Teal)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Take Photo", color = Teal)
                }
                Spacer(modifier = Modifier.width(12.dp))
                TextButton(onClick = onPickPhotos) {
                    Icon(Icons.Filled.Add, contentDescription = null, tint = Teal)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Add More Photos", color = Teal)
                }
            }
        }
    }
}

@Composable
private fun SubjectStep(
    allSubjects: List<SubjectInfo>,
    selectedSubjectInfo: SubjectInfo?,
    onSelect: (SubjectInfo) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center
    ) {
        allSubjects.chunked(2).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                row.forEach { subject ->
                    val isSelected = selectedSubjectInfo == subject
                    Surface(
                        modifier = Modifier.weight(1f),
                        onClick = { onSelect(subject) },
                        shape = RoundedCornerShape(16.dp),
                        color = if (isSelected) subject.color.copy(alpha = 0.15f)
                        else MaterialTheme.colorScheme.surfaceVariant,
                        border = if (isSelected) ButtonDefaults.outlinedButtonBorder.copy(
                            brush = androidx.compose.ui.graphics.SolidColor(subject.color)
                        ) else null
                    ) {
                        Column(
                            modifier = Modifier.padding(vertical = 24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                subject.icon,
                                contentDescription = null,
                                modifier = Modifier.size(28.dp),
                                tint = if (isSelected) subject.color else MaterialTheme.colorScheme.onSurface
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                subject.name,
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = if (isSelected) subject.color else MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
                if (row.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DateStep(
    selectedDate: Date,
    onDateSelected: (Date) -> Unit
) {
    val today = remember { Date() }
    val yesterday = remember {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -1)
        cal.time
    }

    // Convert selectedDate to millis for DatePicker
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = selectedDate.time
    )

    // Sync DatePicker selection back to parent state
    LaunchedEffect(datePickerState.selectedDateMillis) {
        datePickerState.selectedDateMillis?.let { millis ->
            onDateSelected(Date(millis))
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp)
    ) {
        Spacer(modifier = Modifier.height(16.dp))

        // Quick select buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            val isToday = isSameDay(selectedDate, today)
            val isYesterday = isSameDay(selectedDate, yesterday)

            Surface(
                modifier = Modifier.weight(1f),
                onClick = {
                    onDateSelected(today)
                },
                shape = RoundedCornerShape(12.dp),
                color = if (isToday) Teal.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
                border = if (isToday) androidx.compose.foundation.BorderStroke(1.5.dp, Teal) else null
            ) {
                Text(
                    "Today",
                    modifier = Modifier.padding(vertical = 14.dp),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isToday) Teal else MaterialTheme.colorScheme.onSurface
                )
            }
            Surface(
                modifier = Modifier.weight(1f),
                onClick = {
                    onDateSelected(yesterday)
                },
                shape = RoundedCornerShape(12.dp),
                color = if (isYesterday) Teal.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
                border = if (isYesterday) androidx.compose.foundation.BorderStroke(1.5.dp, Teal) else null
            ) {
                Text(
                    "Yesterday",
                    modifier = Modifier.padding(vertical = 14.dp),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isYesterday) Teal else MaterialTheme.colorScheme.onSurface
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Calendar date picker (graphical like iOS)
        DatePicker(
            state = datePickerState,
            modifier = Modifier.fillMaxWidth(),
            title = null,
            headline = null,
            showModeToggle = false,
            colors = DatePickerDefaults.colors(
                selectedDayContainerColor = Teal,
                todayContentColor = Teal,
                todayDateBorderColor = Teal
            )
        )
    }
}

@Composable
private fun ReviewStep(
    selectedSubjectInfo: SubjectInfo?,
    selectedDate: Date,
    photoCount: Int,
    photoUris: List<Uri>,
    description: String,
    onDescriptionChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp)
    ) {
        // Summary
        if (selectedSubjectInfo != null) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    shape = RoundedCornerShape(50),
                    color = selectedSubjectInfo.color.copy(alpha = 0.15f)
                ) {
                    Text(
                        selectedSubjectInfo.name,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold,
                        color = selectedSubjectInfo.color
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    selectedDate.displayString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Photo preview
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(photoUris) { uri ->
                AsyncImage(
                    model = uri,
                    contentDescription = "Photo",
                    modifier = Modifier
                        .width(100.dp)
                        .height(130.dp)
                        .clip(RoundedCornerShape(10.dp)),
                    contentScale = ContentScale.Crop
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "$photoCount photo${if (photoCount == 1) "" else "s"}",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            "Add a note (optional)",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(6.dp))
        OutlinedTextField(
            value = description,
            onValueChange = onDescriptionChange,
            placeholder = { Text("e.g. Chapters 5 & 6") },
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
    }
}

private fun isSameDay(d1: Date, d2: Date): Boolean {
    val c1 = Calendar.getInstance().apply { time = d1 }
    val c2 = Calendar.getInstance().apply { time = d2 }
    return c1.get(Calendar.YEAR) == c2.get(Calendar.YEAR) &&
            c1.get(Calendar.DAY_OF_YEAR) == c2.get(Calendar.DAY_OF_YEAR)
}
