package com.classnotes.app.ui.feed

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.classnotes.app.model.*
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.PostService
import com.classnotes.app.ui.theme.Teal
import com.classnotes.app.util.displayString
import com.classnotes.app.util.relativeString
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PostDetailScreen(
    postId: String,
    groupId: String,
    authService: AuthService,
    groupService: GroupService,
    postService: PostService,
    onNavigateBack: () -> Unit,
    onPhotoClick: (List<String>, Int) -> Unit = { _, _ -> }
) {
    val groups by groupService.groups.collectAsState()
    val group = groups.find { it.id == groupId } ?: return
    val posts by postService.posts.collectAsState()
    val post = posts.find { it.id == postId } ?: return

    val currentUserId by authService.currentUserId.collectAsState()
    val currentUserName by authService.currentUserName.collectAsState()
    val scope = rememberCoroutineScope()

    val subjectInfo = post.subjectInfo(group)
    val isOwner = post.authorId == currentUserId
    val availableReactions = listOf("\uD83D\uDC4D", "\uD83D\uDE4F", "\u2764\uFE0F", "\uD83D\uDCDD")

    var commentText by remember { mutableStateOf("") }
    var isAddingComment by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notes") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (isOwner) {
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            )
        },
        bottomBar = {
            // Comment input bar
            Surface(tonalElevation = 3.dp) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .navigationBarsPadding(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = commentText,
                        onValueChange = { commentText = it },
                        placeholder = { Text("Add a comment...") },
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        shape = RoundedCornerShape(20.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            unfocusedBorderColor = Color.Transparent,
                            focusedBorderColor = Teal
                        )
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(
                        onClick = {
                            val text = commentText.trim()
                            if (text.isNotEmpty() && !isAddingComment) {
                                isAddingComment = true
                                commentText = ""
                                scope.launch {
                                    try {
                                        postService.addComment(post.id, currentUserId, currentUserName, text)
                                    } catch (_: Exception) {}
                                    isAddingComment = false
                                }
                            }
                        },
                        enabled = commentText.trim().isNotEmpty() && !isAddingComment
                    ) {
                        Icon(
                            Icons.Filled.Send,
                            contentDescription = "Send",
                            tint = if (commentText.trim().isNotEmpty()) Teal else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(50),
                    color = subjectInfo.color.copy(alpha = 0.15f)
                ) {
                    Text(
                        subjectInfo.name,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = subjectInfo.color
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    post.date.displayString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.weight(1f))
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        post.authorName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        post.createdAt.relativeString(),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                    )
                }
            }

            // Photos - tapping opens full screen viewer
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(post.photoURLs.size) { index ->
                    AsyncImage(
                        model = post.photoURLs[index],
                        contentDescription = "Note photo",
                        modifier = Modifier
                            .width(200.dp)
                            .height(260.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .clickable { onPhotoClick(post.photoURLs, index) },
                        contentScale = ContentScale.Crop
                    )
                }
            }

            // Description
            if (post.description.isNotEmpty()) {
                Text(
                    post.description,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            // Reactions
            Spacer(modifier = Modifier.height(8.dp))

            // Existing reactions
            if (post.reactions.isNotEmpty()) {
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(post.reactions, key = { it.emoji }) { reaction ->
                        val isActive = reaction.userIds.contains(currentUserId)
                        Surface(
                            onClick = {
                                scope.launch {
                                    try {
                                        postService.toggleReaction(post.id, reaction.emoji, currentUserId, post.reactions)
                                    } catch (_: Exception) {}
                                }
                            },
                            shape = RoundedCornerShape(50),
                            color = if (isActive) Teal.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
                            border = if (isActive) ButtonDefaults.outlinedButtonBorder.copy(
                                brush = androidx.compose.ui.graphics.SolidColor(Teal)
                            ) else null
                        ) {
                            Row(modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)) {
                                Text(reaction.emoji, style = MaterialTheme.typography.labelSmall)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    "${reaction.userIds.size}",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }
            }

            // Add reaction buttons
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                availableReactions.forEach { emoji ->
                    val existing = post.reactions.find { it.emoji == emoji }
                    if (existing == null) {
                        Surface(
                            onClick = {
                                scope.launch {
                                    try {
                                        postService.toggleReaction(post.id, emoji, currentUserId, post.reactions)
                                    } catch (_: Exception) {}
                                }
                            },
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Text(
                                emoji,
                                modifier = Modifier.padding(8.dp),
                                style = MaterialTheme.typography.titleMedium
                            )
                        }
                    }
                }
            }

            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))

            // Comments
            Text(
                "${post.comments.size} Comments",
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            if (post.comments.isEmpty()) {
                Text(
                    "No comments yet. Be the first to comment!",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            } else {
                post.comments.forEach { comment ->
                    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                        Row {
                            Text(
                                comment.authorName,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                comment.createdAt.relativeString(),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                            )
                        }
                        Text(
                            comment.text,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Notes") },
            text = { Text("Are you sure you want to delete these notes? This cannot be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteDialog = false
                    scope.launch {
                        try {
                            postService.deletePost(post)
                            onNavigateBack()
                        } catch (_: Exception) {}
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
}
