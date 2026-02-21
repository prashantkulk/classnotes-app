package com.classnotes.app.ui.navigation

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.classnotes.app.AppMode
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.service.AuthService
import com.classnotes.app.service.GroupService
import com.classnotes.app.service.PostService
import com.classnotes.app.service.RequestService
import com.classnotes.app.service.demo.DemoAuthService
import com.classnotes.app.service.demo.DemoGroupService
import com.classnotes.app.service.demo.DemoPostService
import com.classnotes.app.service.demo.DemoRequestService
import com.classnotes.app.ui.auth.LoginScreen
import com.classnotes.app.ui.auth.OnboardingScreen
import com.classnotes.app.ui.feed.CreatePostScreen
import com.classnotes.app.ui.feed.GroupFeedScreen
import com.classnotes.app.ui.feed.PostDetailScreen
import com.classnotes.app.ui.groups.CreateGroupScreen
import com.classnotes.app.ui.groups.GroupsListScreen
import com.classnotes.app.ui.groups.JoinGroupScreen
import com.classnotes.app.ui.requests.CreateRequestScreen
import com.classnotes.app.ui.requests.RequestDetailScreen
import com.classnotes.app.ui.settings.SettingsScreen
import com.classnotes.app.ui.common.PhotoViewerScreen
import com.classnotes.app.ui.common.AddCustomSubjectScreen
import com.classnotes.app.ui.groups.GroupInfoScreen

sealed class Screen(val route: String) {
    data object Login : Screen("login")
    data object Onboarding : Screen("onboarding")
    data object GroupsList : Screen("groups_list")
    data object CreateGroup : Screen("create_group")
    data object JoinGroup : Screen("join_group")
    data object GroupFeed : Screen("group_feed/{groupId}") {
        fun createRoute(groupId: String) = "group_feed/$groupId"
    }
    data object PostDetail : Screen("post_detail/{postId}/{groupId}") {
        fun createRoute(postId: String, groupId: String) = "post_detail/$postId/$groupId"
    }
    data object CreatePost : Screen("create_post/{groupId}") {
        fun createRoute(groupId: String) = "create_post/$groupId"
    }
    data object RequestDetail : Screen("request_detail/{requestId}/{groupId}") {
        fun createRoute(requestId: String, groupId: String) = "request_detail/$requestId/$groupId"
    }
    data object CreateRequest : Screen("create_request/{groupId}") {
        fun createRoute(groupId: String) = "create_request/$groupId"
    }
    data object PhotoViewer : Screen("photo_viewer/{startIndex}") {
        fun createRoute(startIndex: Int) = "photo_viewer/$startIndex"
    }
    data object Settings : Screen("settings")
    data object GroupInfo : Screen("group_info/{groupId}") {
        fun createRoute(groupId: String) = "group_info/$groupId"
    }
    data object AddCustomSubject : Screen("add_custom_subject/{groupId}") {
        fun createRoute(groupId: String) = "add_custom_subject/$groupId"
    }
}

/**
 * Shared state for passing photo URLs to PhotoViewer
 * (URLs can be too long for navigation arguments)
 */
object PhotoViewerState {
    var photoURLs: List<String> = emptyList()
}

@Composable
fun ClassNotesNavHost(
    navController: NavHostController = rememberNavController()
) {
    val context = LocalContext.current
    val activity = context as? Activity

    val authService = remember {
        if (AppMode.isDemo) DemoAuthService() else AuthService().also {
            it.activity = activity
        }
    }
    val groupService = remember {
        if (AppMode.isDemo) DemoGroupService() else GroupService()
    }
    val postService = remember {
        if (AppMode.isDemo) DemoPostService() else PostService().also {
            it.appContext = context.applicationContext
        }
    }
    val requestService = remember {
        if (AppMode.isDemo) DemoRequestService() else RequestService().also {
            it.appContext = context.applicationContext
        }
    }

    val isAuthenticated by authService.isAuthenticated.collectAsState()

    NavHost(
        navController = navController,
        startDestination = Screen.Login.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                authService = authService,
                onLoginSuccess = { needsOnboarding ->
                    if (needsOnboarding) {
                        navController.navigate(Screen.Onboarding.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.GroupsList.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    }
                }
            )
        }

        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                authService = authService,
                onOnboardingComplete = {
                    navController.navigate(Screen.GroupsList.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.GroupsList.route) {
            GroupsListScreen(
                authService = authService,
                groupService = groupService,
                onGroupClick = { group ->
                    navController.navigate(Screen.GroupFeed.createRoute(group.id))
                },
                onCreateGroup = {
                    navController.navigate(Screen.CreateGroup.route)
                },
                onJoinGroup = {
                    navController.navigate(Screen.JoinGroup.route)
                },
                onSettings = {
                    navController.navigate(Screen.Settings.route)
                }
            )
        }

        composable(Screen.CreateGroup.route) {
            CreateGroupScreen(
                authService = authService,
                groupService = groupService,
                onDismiss = { navController.popBackStack() }
            )
        }

        composable(Screen.JoinGroup.route) {
            JoinGroupScreen(
                authService = authService,
                groupService = groupService,
                onDismiss = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.GroupFeed.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) { backStackEntry ->
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            GroupFeedScreen(
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                postService = postService,
                requestService = requestService,
                onNavigateBack = { navController.popBackStack() },
                onPostClick = { post ->
                    navController.navigate(Screen.PostDetail.createRoute(post.id, groupId))
                },
                onPhotoClick = { post, index ->
                    PhotoViewerState.photoURLs = post.photoURLs
                    navController.navigate(Screen.PhotoViewer.createRoute(index))
                },
                onRequestClick = { request ->
                    navController.navigate(Screen.RequestDetail.createRoute(request.id, groupId))
                },
                onCreatePost = {
                    navController.navigate(Screen.CreatePost.createRoute(groupId))
                },
                onCreateRequest = {
                    navController.navigate(Screen.CreateRequest.createRoute(groupId))
                },
                onGroupInfo = {
                    navController.navigate(Screen.GroupInfo.createRoute(groupId))
                }
            )
        }

        composable(
            route = Screen.PostDetail.route,
            arguments = listOf(
                navArgument("postId") { type = NavType.StringType },
                navArgument("groupId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val postId = backStackEntry.arguments?.getString("postId") ?: return@composable
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            PostDetailScreen(
                postId = postId,
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                postService = postService,
                onNavigateBack = { navController.popBackStack() },
                onPhotoClick = { photoURLs, index ->
                    PhotoViewerState.photoURLs = photoURLs
                    navController.navigate(Screen.PhotoViewer.createRoute(index))
                }
            )
        }

        composable(
            route = Screen.CreatePost.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) { backStackEntry ->
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            CreatePostScreen(
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                postService = postService,
                onDismiss = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.RequestDetail.route,
            arguments = listOf(
                navArgument("requestId") { type = NavType.StringType },
                navArgument("groupId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val requestId = backStackEntry.arguments?.getString("requestId") ?: return@composable
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            RequestDetailScreen(
                requestId = requestId,
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                requestService = requestService,
                postService = postService,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.CreateRequest.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) { backStackEntry ->
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            CreateRequestScreen(
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                requestService = requestService,
                onDismiss = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.PhotoViewer.route,
            arguments = listOf(navArgument("startIndex") { type = NavType.IntType })
        ) { backStackEntry ->
            val startIndex = backStackEntry.arguments?.getInt("startIndex") ?: 0
            PhotoViewerScreen(
                photoURLs = PhotoViewerState.photoURLs,
                initialIndex = startIndex,
                onDismiss = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                authService = authService,
                onDismiss = { navController.popBackStack() },
                onSignedOut = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        composable(
            route = Screen.GroupInfo.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) { backStackEntry ->
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            GroupInfoScreen(
                groupId = groupId,
                authService = authService,
                groupService = groupService,
                onDismiss = { navController.popBackStack() },
                onGroupDeleted = {
                    // Pop back to groups list
                    navController.popBackStack(Screen.GroupsList.route, false)
                },
                onGroupLeft = {
                    navController.popBackStack(Screen.GroupsList.route, false)
                }
            )
        }

        composable(
            route = Screen.AddCustomSubject.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) { backStackEntry ->
            val groupId = backStackEntry.arguments?.getString("groupId") ?: return@composable
            val groups by groupService.groups.collectAsState()
            val group = groups.find { it.id == groupId } ?: return@composable
            AddCustomSubjectScreen(
                group = group,
                groupService = groupService,
                onCreated = { /* Subject added, will appear in group's allSubjects */ },
                onDismiss = { navController.popBackStack() }
            )
        }
    }
}
