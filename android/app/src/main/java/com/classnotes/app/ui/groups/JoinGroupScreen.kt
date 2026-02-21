package com.classnotes.app.ui.groups

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
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.ui.theme.Teal
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JoinGroupScreen(
    authService: AuthService,
    groupService: GroupService,
    onDismiss: () -> Unit
) {
    var inviteCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var joinedGroup by remember { mutableStateOf<ClassGroup?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()
    val currentUserId by authService.currentUserId.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Join Group") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        if (joinedGroup != null) {
            // Success state
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 32.dp),
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
                    "Joined Successfully!",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "You've joined ${joinedGroup!!.name}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(32.dp))
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Teal)
                ) {
                    Text("Done", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // Form
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.weight(1f))

                Icon(
                    Icons.Filled.PersonAdd,
                    contentDescription = null,
                    modifier = Modifier.size(56.dp),
                    tint = Teal
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    "Enter Invite Code",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Ask the group admin for the invite code",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(40.dp))

                OutlinedTextField(
                    value = inviteCode,
                    onValueChange = { inviteCode = it.uppercase().take(6) },
                    placeholder = { Text("e.g. ABC123") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                        unfocusedBorderColor = Color.Transparent,
                        focusedBorderColor = Teal
                    )
                )

                Spacer(modifier = Modifier.height(16.dp))

                errorMessage?.let { msg ->
                    Text(
                        msg,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Button(
                    onClick = {
                        errorMessage = null
                        isLoading = true
                        scope.launch {
                            try {
                                val group = groupService.joinGroup(inviteCode.trim(), currentUserId)
                                joinedGroup = group
                            } catch (e: Exception) {
                                errorMessage = e.message
                            }
                            isLoading = false
                        }
                    },
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    enabled = inviteCode.trim().length >= 4 && !isLoading,
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Teal)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White, strokeWidth = 2.dp)
                    } else {
                        Text("Join Group", style = MaterialTheme.typography.titleMedium)
                    }
                }

                Spacer(modifier = Modifier.weight(2f))
            }
        }
    }
}
