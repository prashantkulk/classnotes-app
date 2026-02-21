package com.classnotes.app.ui.requests

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
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
import com.classnotes.app.AppMode
import com.classnotes.app.model.*
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.NotificationService
import com.classnotes.app.service.RequestService
import com.classnotes.app.service.demo.DemoData
import com.classnotes.app.ui.theme.Teal
import com.classnotes.app.util.displayString
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateRequestScreen(
    groupId: String,
    authService: AuthService,
    groupService: GroupService,
    requestService: RequestService,
    onDismiss: () -> Unit
) {
    val groups by groupService.groups.collectAsState()
    val group = groups.find { it.id == groupId } ?: return
    val currentUserId by authService.currentUserId.collectAsState()
    val currentUserName by authService.currentUserName.collectAsState()
    val scope = rememberCoroutineScope()

    var step by remember { mutableIntStateOf(0) }
    var selectedSubjectInfo by remember { mutableStateOf<SubjectInfo?>(null) }
    var selectedDate by remember { mutableStateOf(Date()) }
    var selectedTargetUser by remember { mutableStateOf<AppUser?>(null) }
    var message by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var groupMembers by remember { mutableStateOf<List<AppUser>>(emptyList()) }

    val stepTitle = when (step) {
        0 -> "Which Subject?"
        1 -> "Which Date?"
        2 -> "Ask Whom?"
        else -> "Add Details"
    }

    // Load members when reaching step 2
    LaunchedEffect(step) {
        if (step == 2 && groupMembers.isEmpty()) {
            if (AppMode.isDemo) {
                groupMembers = DemoData.users
            } else {
                groupMembers = NotificationService.fetchGroupMembers(group.members)
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stepTitle) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Progress dots
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                repeat(4) { i ->
                    Surface(
                        modifier = Modifier.size(10.dp),
                        shape = RoundedCornerShape(50),
                        color = if (i <= step) Teal else MaterialTheme.colorScheme.outlineVariant
                    ) {}
                    if (i < 3) Spacer(modifier = Modifier.width(8.dp))
                }
            }

            // Content
            Box(modifier = Modifier.weight(1f)) {
                when (step) {
                    0 -> SubjectSelectionStep(
                        allSubjects = group.allSubjects,
                        selectedSubjectInfo = selectedSubjectInfo,
                        onSelect = { selectedSubjectInfo = it }
                    )
                    1 -> DateSelectionStep(
                        selectedDate = selectedDate,
                        onDateSelected = { selectedDate = it }
                    )
                    2 -> MemberSelectionStep(
                        members = groupMembers,
                        currentUserId = currentUserId,
                        selectedTargetUser = selectedTargetUser,
                        onSelect = { selectedTargetUser = it },
                        onSelectEveryone = { selectedTargetUser = null }
                    )
                    3 -> MessageStep(
                        selectedSubjectInfo = selectedSubjectInfo,
                        selectedDate = selectedDate,
                        selectedTargetUser = selectedTargetUser,
                        message = message,
                        onMessageChange = { message = it }
                    )
                }
            }

            // Bottom buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (step > 0) {
                    OutlinedButton(
                        onClick = { step-- },
                        modifier = Modifier.weight(1f).height(56.dp),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Teal)
                    ) {
                        Icon(Icons.Filled.ChevronLeft, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Back", style = MaterialTheme.typography.titleMedium)
                    }
                }

                if (step == 3) {
                    Button(
                        onClick = {
                            isLoading = true
                            scope.launch {
                                try {
                                    requestService.createRequest(
                                        groupId = groupId,
                                        authorId = currentUserId,
                                        authorName = currentUserName,
                                        subjectName = selectedSubjectInfo?.name ?: "",
                                        date = selectedDate,
                                        description = message,
                                        targetUserId = selectedTargetUser?.id,
                                        targetUserName = selectedTargetUser?.name
                                    )
                                    onDismiss()
                                } catch (_: Exception) {}
                                isLoading = false
                            }
                        },
                        modifier = Modifier.weight(1f).height(56.dp),
                        enabled = !isLoading,
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Teal)
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White, strokeWidth = 2.dp)
                        } else {
                            Icon(Icons.Filled.PanTool, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Ask", style = MaterialTheme.typography.titleMedium)
                        }
                    }
                } else {
                    Button(
                        onClick = { step++ },
                        modifier = Modifier.weight(1f).height(56.dp),
                        enabled = step != 0 || selectedSubjectInfo != null,
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
    }
}

@Composable
private fun SubjectSelectionStep(
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
        // 2-column grid using Rows
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

@Composable
private fun DateSelectionStep(
    selectedDate: Date,
    onDateSelected: (Date) -> Unit
) {
    val today = remember { Date() }
    val yesterday = remember {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -1)
        cal.time
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            val isToday = isSameDay(selectedDate, today)
            val isYesterday = isSameDay(selectedDate, yesterday)

            Surface(
                modifier = Modifier.weight(1f),
                onClick = { onDateSelected(today) },
                shape = RoundedCornerShape(12.dp),
                color = if (isToday) Teal.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant
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
                onClick = { onDateSelected(yesterday) },
                shape = RoundedCornerShape(12.dp),
                color = if (isYesterday) Teal.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant
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
        Text(
            "Selected: ${selectedDate.displayString()}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun MemberSelectionStep(
    members: List<AppUser>,
    currentUserId: String,
    selectedTargetUser: AppUser?,
    onSelect: (AppUser) -> Unit,
    onSelectEveryone: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        // "Everyone" option
        val isEveryoneSelected = selectedTargetUser == null
        Surface(
            modifier = Modifier.fillMaxWidth(),
            onClick = onSelectEveryone,
            shape = RoundedCornerShape(12.dp),
            color = if (isEveryoneSelected) Teal.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant,
            border = if (isEveryoneSelected) ButtonDefaults.outlinedButtonBorder.copy(
                brush = androidx.compose.ui.graphics.SolidColor(Teal)
            ) else null
        ) {
            Row(
                modifier = Modifier.padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Filled.Groups,
                    contentDescription = null,
                    modifier = Modifier.size(28.dp),
                    tint = if (isEveryoneSelected) Teal else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    "Everyone in the group",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (isEveryoneSelected) FontWeight.SemiBold else FontWeight.Normal
                )
                Spacer(modifier = Modifier.weight(1f))
                if (isEveryoneSelected) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = Teal,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Individual members (exclude current user)
        members.filter { it.id != currentUserId }.forEach { member ->
            val isSelected = selectedTargetUser?.id == member.id
            Surface(
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                onClick = { onSelect(member) },
                shape = RoundedCornerShape(12.dp),
                color = if (isSelected) Teal.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant,
                border = if (isSelected) ButtonDefaults.outlinedButtonBorder.copy(
                    brush = androidx.compose.ui.graphics.SolidColor(Teal)
                ) else null
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.AccountCircle,
                        contentDescription = null,
                        modifier = Modifier.size(28.dp),
                        tint = if (isSelected) Teal else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        member.name.ifEmpty { "Parent" },
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    if (isSelected) {
                        Icon(
                            Icons.Filled.CheckCircle,
                            contentDescription = null,
                            tint = Teal,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MessageStep(
    selectedSubjectInfo: SubjectInfo?,
    selectedDate: Date,
    selectedTargetUser: AppUser?,
    message: String,
    onMessageChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center
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
                if (selectedTargetUser != null) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "\u2192 ${selectedTargetUser.name}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFFF9800)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            "Add a message (optional)",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(6.dp))
        OutlinedTextField(
            value = message,
            onValueChange = onMessageChange,
            placeholder = { Text("e.g. Need pages 45-50") },
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
