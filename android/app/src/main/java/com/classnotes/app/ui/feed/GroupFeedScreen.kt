package com.classnotes.app.ui.feed

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.classnotes.app.model.*
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.PostService
import com.classnotes.app.service.RequestService
import com.classnotes.app.ui.theme.Teal
import com.classnotes.app.util.displayString
import com.classnotes.app.util.relativeString
import com.classnotes.app.util.shortDisplayString
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

enum class FeedTab(val title: String) {
    NOTES("Notes"),
    REQUESTS("Requests")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupFeedScreen(
    groupId: String,
    authService: AuthService,
    groupService: GroupService,
    postService: PostService,
    requestService: RequestService,
    onNavigateBack: () -> Unit,
    onPostClick: (Post) -> Unit,
    onPhotoClick: (Post, Int) -> Unit,
    onRequestClick: (NoteRequest) -> Unit,
    onCreatePost: () -> Unit,
    onCreateRequest: () -> Unit,
    onGroupInfo: () -> Unit
) {
    val groups by groupService.groups.collectAsState()
    val group = groups.find { it.id == groupId } ?: return
    val posts by postService.posts.collectAsState()
    val requests by requestService.requests.collectAsState()
    val currentUserId by authService.currentUserId.collectAsState()

    var selectedTab by remember { mutableStateOf(FeedTab.NOTES) }
    var selectedSubjectName by remember { mutableStateOf<String?>(null) }
    var isRefreshing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(groupId) {
        postService.loadPosts(groupId)
        requestService.loadRequests(groupId)
    }

    val filteredPosts = if (selectedSubjectName != null) {
        posts.filter { it.subjectName == selectedSubjectName }
    } else posts

    val activeRequests = requests.filter { it.status != RequestStatus.FULFILLED }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(group.name) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onGroupInfo) {
                        Icon(Icons.Filled.Info, contentDescription = "Group Info")
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { if (selectedTab == FeedTab.NOTES) onCreatePost() else onCreateRequest() },
                containerColor = Teal,
                contentColor = Color.White,
                shape = RoundedCornerShape(50)
            ) {
                Icon(
                    if (selectedTab == FeedTab.NOTES) Icons.Filled.CameraAlt else Icons.Filled.PanTool,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    if (selectedTab == FeedTab.NOTES) "Share Notes" else "Ask for Notes",
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Tab selector
            Row(
                modifier = Modifier
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(RoundedCornerShape(12.dp))
            ) {
                FeedTab.entries.forEach { tab ->
                    val isSelected = selectedTab == tab
                    val bgColor by animateColorAsState(
                        if (isSelected) Teal else MaterialTheme.colorScheme.surfaceVariant,
                        label = "tabBg"
                    )
                    val textColor by animateColorAsState(
                        if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
                        label = "tabText"
                    )
                    Surface(
                        modifier = Modifier.weight(1f),
                        color = bgColor,
                        onClick = { selectedTab = tab }
                    ) {
                        Text(
                            tab.title,
                            modifier = Modifier.padding(vertical = 14.dp),
                            textAlign = TextAlign.Center,
                            fontWeight = FontWeight.SemiBold,
                            color = textColor
                        )
                    }
                }
            }

            when (selectedTab) {
                FeedTab.NOTES -> {
                    // Subject filter
                    SubjectFilterRow(
                        allSubjects = group.allSubjects,
                        selectedSubjectName = selectedSubjectName,
                        onSelect = { selectedSubjectName = it }
                    )

                    PullToRefreshBox(
                        isRefreshing = isRefreshing,
                        onRefresh = {
                            scope.launch {
                                isRefreshing = true
                                postService.loadPosts(groupId)
                                delay(500)
                                isRefreshing = false
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    ) {
                        if (filteredPosts.isEmpty()) {
                            EmptyState(
                                icon = Icons.Filled.Description,
                                title = "No notes shared yet",
                                subtitle = "Be the first to share class notes!"
                            )
                        } else {
                            LazyColumn(
                                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                items(filteredPosts, key = { it.id }) { post ->
                                    PostCardView(
                                        post = post,
                                        group = group,
                                        onPhotoClick = { index -> onPhotoClick(post, index) },
                                        onDetailClick = { onPostClick(post) }
                                    )
                                }
                            }
                        }
                    }
                }

                FeedTab.REQUESTS -> {
                    PullToRefreshBox(
                        isRefreshing = isRefreshing,
                        onRefresh = {
                            scope.launch {
                                isRefreshing = true
                                requestService.loadRequests(groupId)
                                delay(500)
                                isRefreshing = false
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    ) {
                        if (activeRequests.isEmpty()) {
                            EmptyState(
                                icon = Icons.Filled.QuestionAnswer,
                                title = "No requests yet",
                                subtitle = "Need notes? Ask the group!"
                            )
                        } else {
                            LazyColumn(
                                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                items(activeRequests, key = { it.id }) { request ->
                                    RequestCardView(
                                        request = request,
                                        group = group,
                                        currentUserId = currentUserId,
                                        onClick = { onRequestClick(request) }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SubjectFilterRow(
    allSubjects: List<SubjectInfo>,
    selectedSubjectName: String?,
    onSelect: (String?) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            FilterChipItem(
                label = "All",
                color = Teal,
                isSelected = selectedSubjectName == null,
                onClick = { onSelect(null) }
            )
        }
        items(allSubjects) { subject ->
            FilterChipItem(
                label = subject.name,
                color = subject.color,
                isSelected = selectedSubjectName == subject.name,
                onClick = { onSelect(subject.name) }
            )
        }
    }
}

@Composable
fun FilterChipItem(label: String, color: Color, isSelected: Boolean, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(50),
        color = if (isSelected) color.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant,
        border = if (isSelected) ButtonDefaults.outlinedButtonBorder.copy(
            brush = androidx.compose.ui.graphics.SolidColor(color)
        ) else null
    ) {
        Text(
            label,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            color = if (isSelected) color else MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
fun PostCardView(
    post: Post,
    group: ClassGroup,
    onPhotoClick: (Int) -> Unit,
    onDetailClick: () -> Unit
) {
    val subjectInfo = post.subjectInfo(group)

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Subject badge + date + arrow to detail
            Row(verticalAlignment = Alignment.CenterVertically) {
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
                // Arrow to open thread detail
                IconButton(
                    onClick = onDetailClick,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        Icons.Filled.ChevronRight,
                        contentDescription = "View thread",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Photo thumbnails - tapping opens full screen viewer
            if (post.photoURLs.isNotEmpty()) {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(post.photoURLs.size) { index ->
                        AsyncImage(
                            model = post.photoURLs[index],
                            contentDescription = "Note photo",
                            modifier = Modifier
                                .width(120.dp)
                                .height(160.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .clickable { onPhotoClick(index) },
                            contentScale = ContentScale.Crop
                        )
                    }
                }
                Spacer(modifier = Modifier.height(10.dp))
            }

            // Description
            if (post.description.isNotEmpty()) {
                Text(
                    post.description,
                    style = MaterialTheme.typography.bodyMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Reactions summary
            if (post.reactions.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    post.reactions.forEach { reaction ->
                        Row {
                            Text(reaction.emoji, style = MaterialTheme.typography.labelSmall)
                            Text(
                                "${reaction.userIds.size}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Author + time + comment count
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.AccountCircle,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    "Shared by ${post.authorName}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.weight(1f))
                if (post.comments.isNotEmpty()) {
                    Icon(
                        Icons.Filled.ChatBubbleOutline,
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(
                        "${post.comments.size}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    post.createdAt.relativeString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun RequestCardView(
    request: NoteRequest,
    group: ClassGroup,
    currentUserId: String,
    onClick: () -> Unit
) {
    val subjectInfo = request.subjectInfo(group)
    val isForCurrentUser = request.targetUserId != null && request.targetUserId == currentUserId

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        onClick = onClick
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                // Subject badge + "For you" + date
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = subjectInfo.color.copy(alpha = 0.15f)
                    ) {
                        Text(
                            subjectInfo.name,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = subjectInfo.color
                        )
                    }
                    if (isForCurrentUser) {
                        Surface(
                            shape = RoundedCornerShape(50),
                            color = Color(0xFFFF9800).copy(alpha = 0.15f)
                        ) {
                            Text(
                                "For you",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = Color(0xFFFF9800)
                            )
                        }
                    }
                    Text(
                        request.date.shortDisplayString(),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Description
                Text(
                    text = request.description.ifEmpty {
                        "Need ${subjectInfo.name} notes from ${request.date.shortDisplayString()}"
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(6.dp))

                // Author + replies
                Row {
                    val askedText = if (request.targetUserName != null) {
                        "Asked by ${request.authorName} from ${request.targetUserName}"
                    } else {
                        "Asked by ${request.authorName}"
                    }
                    Text(
                        askedText,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        " \u00B7 ${request.responses.size} replies",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            if (request.status == RequestStatus.FULFILLED) {
                Icon(
                    Icons.Filled.CheckCircle,
                    contentDescription = "Fulfilled",
                    tint = Color(0xFF4CAF50),
                    modifier = Modifier.size(24.dp)
                )
            } else {
                Icon(
                    Icons.Filled.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

@Composable
fun EmptyState(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            icon,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            subtitle,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
        )
    }
}
