package com.classnotes.app.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.classnotes.app.service.AuthService
import com.classnotes.app.ui.theme.Teal
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    authService: AuthService,
    onDismiss: () -> Unit,
    onSignedOut: () -> Unit
) {
    val currentUserName by authService.currentUserName.collectAsState()
    val scope = rememberCoroutineScope()

    var showSignOutDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showFinalDeleteDialog by remember { mutableStateOf(false) }
    var showEditNameDialog by remember { mutableStateOf(false) }
    var editedName by remember { mutableStateOf("") }
    var isDeletingAccount by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            // Account section
            Text(
                "Account",
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 12.dp),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                onClick = {
                    editedName = currentUserName
                    showEditNameDialog = true
                }
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Name", style = MaterialTheme.typography.bodyMedium)
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        currentUserName,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Icon(
                        Icons.Filled.ChevronRight,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Sign out
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                onClick = { showSignOutDialog = true }
            ) {
                Text(
                    "Sign Out",
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Delete account
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                onClick = { showDeleteDialog = true },
                enabled = !isDeletingAccount
            ) {
                Text(
                    "Delete Account",
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error
                )
            }
            Text(
                "Permanently deletes your account and profile data. Your shared notes will remain visible to group members.",
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.weight(1f))

            // Credits
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 24.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Designed by Ritu, Rashmi and Aditi with ",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                )
                Icon(
                    Icons.Filled.Favorite,
                    contentDescription = null,
                    modifier = Modifier.size(12.dp),
                    tint = Color.Red
                )
            }
        }
    }

    // Sign out dialog
    if (showSignOutDialog) {
        AlertDialog(
            onDismissRequest = { showSignOutDialog = false },
            title = { Text("Sign Out") },
            text = { Text("Are you sure you want to sign out?") },
            confirmButton = {
                TextButton(onClick = {
                    showSignOutDialog = false
                    authService.signOut()
                    onSignedOut()
                }) {
                    Text("Sign Out", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showSignOutDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Delete account dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Account?") },
            text = { Text("This will permanently delete your account. This action cannot be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteDialog = false
                    showFinalDeleteDialog = true
                }) {
                    Text("Delete My Account", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Final delete confirmation
    if (showFinalDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showFinalDeleteDialog = false },
            title = { Text("Are you absolutely sure?") },
            text = { Text("Your account and profile will be permanently deleted. You will need to create a new account to use ClassNotes again.") },
            confirmButton = {
                TextButton(onClick = {
                    showFinalDeleteDialog = false
                    isDeletingAccount = true
                    scope.launch {
                        try {
                            authService.deleteAccount()
                            onSignedOut()
                        } catch (_: Exception) {
                            isDeletingAccount = false
                        }
                    }
                }) {
                    Text("Yes, Delete Everything", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showFinalDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Edit name dialog
    if (showEditNameDialog) {
        AlertDialog(
            onDismissRequest = { showEditNameDialog = false },
            title = { Text("Edit Name") },
            text = {
                Column {
                    Text("What should we call you?")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = editedName,
                        onValueChange = { editedName = it },
                        placeholder = { Text("Your name") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    val trimmed = editedName.trim()
                    if (trimmed.isNotEmpty() && trimmed != currentUserName) {
                        scope.launch {
                            try {
                                authService.updateName(trimmed)
                            } catch (_: Exception) {}
                        }
                    }
                    showEditNameDialog = false
                }) {
                    Text("Save", color = Teal)
                }
            },
            dismissButton = {
                TextButton(onClick = { showEditNameDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Deleting overlay
    if (isDeletingAccount) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.Black.copy(alpha = 0.3f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    tonalElevation = 8.dp
                ) {
                    Column(
                        modifier = Modifier.padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Deleting account...", style = MaterialTheme.typography.titleMedium)
                    }
                }
            }
        }
    }
}
