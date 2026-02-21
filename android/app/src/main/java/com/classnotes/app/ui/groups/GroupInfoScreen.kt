package com.classnotes.app.ui.groups

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.classnotes.app.AppMode
import com.classnotes.app.model.AppUser
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.NotificationService
import com.classnotes.app.service.demo.DemoData
import com.classnotes.app.ui.theme.Teal
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupInfoScreen(
    groupId: String,
    authService: AuthService,
    groupService: GroupService,
    onDismiss: () -> Unit,
    onGroupDeleted: () -> Unit,
    onGroupLeft: () -> Unit
) {
    val groups by groupService.groups.collectAsState()
    val group = groups.find { it.id == groupId } ?: return

    val currentUserId by authService.currentUserId.collectAsState()
    val isCreator = currentUserId == group.createdBy
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var members by remember { mutableStateOf<List<AppUser>>(emptyList()) }
    var isLoadingMembers by remember { mutableStateOf(true) }
    var isProcessing by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showLeaveDialog by remember { mutableStateOf(false) }

    LaunchedEffect(group.members) {
        if (AppMode.isDemo) {
            members = DemoData.users.filter { group.members.contains(it.id) }
        } else {
            members = NotificationService.fetchGroupMembers(group.members)
        }
        isLoadingMembers = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Group Info") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            Text(
                group.school,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                group.name,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Invite code section
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        "Invite Code",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        group.inviteCode,
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace,
                        color = Teal,
                        letterSpacing = 4.sp
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    TextButton(onClick = {
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("Invite Code", group.inviteCode))
                    }) {
                        Icon(Icons.Filled.ContentCopy, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Copy Code", color = Teal)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Members section
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Filled.People,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            "${group.members.size} Members",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))

                    if (isLoadingMembers) {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(modifier = Modifier.size(24.dp))
                        }
                    } else {
                        members.forEach { member ->
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Filled.AccountCircle,
                                    contentDescription = null,
                                    modifier = Modifier.size(32.dp),
                                    tint = if (member.id == group.createdBy) Teal else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = member.name.ifEmpty { "Parent" },
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = if (member.id == currentUserId) FontWeight.SemiBold else FontWeight.Normal
                                        )
                                        if (member.id == currentUserId) {
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Surface(
                                                shape = RoundedCornerShape(50),
                                                color = Teal.copy(alpha = 0.1f)
                                            ) {
                                                Text(
                                                    "You",
                                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                                    style = MaterialTheme.typography.labelSmall,
                                                    color = Teal
                                                )
                                            }
                                        }
                                    }
                                    if (member.id == group.createdBy) {
                                        Text(
                                            "Admin",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Teal
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Leave/Delete button
            if (isProcessing) {
                CircularProgressIndicator(modifier = Modifier.padding(bottom = 24.dp))
            } else if (isCreator) {
                Button(
                    onClick = { showDeleteDialog = true },
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Icon(Icons.Filled.Delete, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Delete Group", style = MaterialTheme.typography.titleMedium)
                }
            } else {
                Button(
                    onClick = { showLeaveDialog = true },
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Icon(Icons.Filled.ExitToApp, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Leave Group", style = MaterialTheme.typography.titleMedium)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Group") },
            text = { Text("This will permanently delete the group, all posts, and all requests. This cannot be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteDialog = false
                    isProcessing = true
                    scope.launch {
                        try {
                            groupService.deleteGroup(group)
                            onGroupDeleted()
                        } catch (e: Exception) {
                            isProcessing = false
                        }
                    }
                }) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showLeaveDialog) {
        AlertDialog(
            onDismissRequest = { showLeaveDialog = false },
            title = { Text("Leave Group") },
            text = { Text("Are you sure you want to leave this group? You can rejoin later with the invite code.") },
            confirmButton = {
                TextButton(onClick = {
                    showLeaveDialog = false
                    isProcessing = true
                    scope.launch {
                        try {
                            groupService.leaveGroup(group.id, currentUserId)
                            onGroupLeft()
                        } catch (e: Exception) {
                            isProcessing = false
                        }
                    }
                }) {
                    Text("Leave", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLeaveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
