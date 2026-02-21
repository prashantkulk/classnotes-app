package com.classnotes.app.ui.groups

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.ui.theme.Teal

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupsListScreen(
    authService: AuthService,
    groupService: GroupService,
    onGroupClick: (ClassGroup) -> Unit,
    onCreateGroup: () -> Unit,
    onJoinGroup: () -> Unit,
    onSettings: () -> Unit
) {
    val groups by groupService.groups.collectAsState()
    val currentUserId by authService.currentUserId.collectAsState()
    var showMenu by remember { mutableStateOf(false) }

    LaunchedEffect(currentUserId) {
        if (currentUserId.isNotEmpty()) {
            groupService.loadGroups(currentUserId)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Your Groups", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = "Settings")
                    }
                },
                actions = {
                    Box {
                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Filled.Add, contentDescription = "Add Group")
                        }
                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Create Group") },
                                onClick = {
                                    showMenu = false
                                    onCreateGroup()
                                },
                                leadingIcon = { Icon(Icons.Filled.AddCircle, contentDescription = null) }
                            )
                            DropdownMenuItem(
                                text = { Text("Join Group") },
                                onClick = {
                                    showMenu = false
                                    onJoinGroup()
                                },
                                leadingIcon = { Icon(Icons.Filled.PersonAdd, contentDescription = null) }
                            )
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (groups.isEmpty()) {
            // Empty state
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    Icons.Filled.People,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = Teal.copy(alpha = 0.6f)
                )
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    "No groups yet",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Create or join your first class group\nto start sharing notes",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                    onClick = onCreateGroup,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Teal)
                ) {
                    Icon(Icons.Filled.AddCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Create a Group", style = MaterialTheme.typography.titleMedium)
                }
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedButton(
                    onClick = onJoinGroup,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Teal)
                ) {
                    Icon(Icons.Filled.PersonAdd, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Join with Code", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(groups) { group ->
                    GroupCardView(group = group, onClick = { onGroupClick(group) })
                }
            }
        }
    }
}

@Composable
fun GroupCardView(group: ClassGroup, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text(
                text = group.school.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                letterSpacing = 0.5.sp
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = group.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.People,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    "${group.members.size}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
