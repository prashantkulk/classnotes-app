import SwiftUI

enum FeedTab: String, CaseIterable {
    case notes = "Notes"
    case requests = "Requests"
}

struct GroupFeedView: View {
    let group: ClassGroup
    @ObservedObject var groupService: GroupService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismissFeed
    @StateObject private var postService: PostService = AppMode.isDemo ? DemoPostService() : PostService()
    @StateObject private var requestService: RequestService = AppMode.isDemo ? DemoRequestService() : RequestService()
    @State private var selectedTab: FeedTab = .notes
    @State private var selectedSubjectName: String?
    @State private var showCreatePost = false
    @State private var showCreateRequest = false
    @State private var showGroupInfo = false
    @State private var requestToDelete: NoteRequest?
    @State private var showDeleteRequestConfirmation = false
    @State private var postToDelete: Post?
    @State private var showDeletePostConfirmation = false

    // Use the latest group from groupService (real-time) for accurate data
    private var liveGroup: ClassGroup {
        groupService.groups.first { $0.id == group.id } ?? group
    }

    private var activeRequests: [NoteRequest] {
        requestService.requests.filter { $0.status != .fulfilled }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector

            // Content
            switch selectedTab {
            case .notes:
                notesContent
            case .requests:
                requestsContent
            }
        }
        .navigationTitle(liveGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showGroupInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(group: liveGroup, postService: postService, groupService: groupService)
        }
        .sheet(isPresented: $showCreateRequest) {
            CreateRequestView(group: liveGroup, requestService: requestService, groupService: groupService)
        }
        .sheet(isPresented: $showGroupInfo) {
            GroupInfoView(group: liveGroup, groupService: groupService, onGroupDeleted: {
                dismissFeed()
            }, onGroupLeft: {
                dismissFeed()
            })
        }
        .confirmationDialog(
            "Delete Request",
            isPresented: $showDeleteRequestConfirmation,
            presenting: requestToDelete
        ) { request in
            Button("Delete", role: .destructive) {
                requestService.deleteRequest(request) { _ in }
            }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            Text("Are you sure you want to delete this request? This cannot be undone.")
        }
        .confirmationDialog(
            "Delete Notes",
            isPresented: $showDeletePostConfirmation,
            presenting: postToDelete
        ) { post in
            Button("Delete", role: .destructive) {
                postService.deletePost(post) { _ in }
            }
            Button("Cancel", role: .cancel) {}
        } message: { post in
            Text("Are you sure you want to delete these notes? This cannot be undone.")
        }
        .onAppear {
            postService.loadPosts(for: group.id)
            requestService.loadRequests(for: group.id)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedTab == tab ? Color.teal : Color(.systemGray6))
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Notes Content

    private var notesContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Subject filter
                subjectFilter

                if filteredPosts.isEmpty {
                    emptyNotesState
                } else {
                    List {
                        ForEach(filteredPosts) { post in
                            NavigationLink(destination: PostDetailView(post: post, group: liveGroup, postService: postService)) {
                                PostCardView(post: post, group: liveGroup)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if post.authorId == authService.currentUserId {
                                    Button(role: .destructive) {
                                        postToDelete = post
                                        showDeletePostConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        postService.loadPosts(for: group.id)
                    }
                }
            }

            // Floating action button
            Button {
                showCreatePost = true
            } label: {
                Label("Share Notes", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.teal)
                    .clipShape(Capsule())
                    .shadow(color: .teal.opacity(0.3), radius: 8, y: 4)
            }
            .padding(20)
        }
    }

    // MARK: - Subject Filter

    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "All", isSelected: selectedSubjectName == nil) {
                    selectedSubjectName = nil
                }

                ForEach(liveGroup.allSubjects) { subjectInfo in
                    filterPill(
                        label: subjectInfo.name,
                        color: subjectInfo.color,
                        isSelected: selectedSubjectName == subjectInfo.name
                    ) {
                        selectedSubjectName = subjectInfo.name
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func filterPill(label: String, color: Color = .teal, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(isSelected ? color : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
        }
    }

    private var filteredPosts: [Post] {
        if let name = selectedSubjectName {
            return postService.posts.filter { $0.subjectName == name }
        }
        return postService.posts
    }

    // MARK: - Requests Content

    private var requestsContent: some View {
        ZStack(alignment: .bottomTrailing) {
            if activeRequests.isEmpty {
                emptyRequestsState
            } else {
                List {
                    ForEach(activeRequests) { request in
                        NavigationLink(destination: RequestDetailView(request: request, requestService: requestService, postService: postService, group: liveGroup)) {
                            RequestCardView(request: request, group: liveGroup)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if request.authorId == authService.currentUserId {
                                Button(role: .destructive) {
                                    requestToDelete = request
                                    showDeleteRequestConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    requestService.loadRequests(for: group.id)
                }
            }

            // Floating action button
            Button {
                showCreateRequest = true
            } label: {
                Label("Ask for Notes", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.teal)
                    .clipShape(Capsule())
                    .shadow(color: .teal.opacity(0.3), radius: 8, y: 4)
            }
            .padding(20)
        }
    }

    // MARK: - Empty States

    private var emptyNotesState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No notes shared yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Be the first to share class notes!")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
            Spacer()
        }
    }

    private var emptyRequestsState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "questionmark.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No requests yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Need notes? Ask the group!")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
            Spacer()
        }
    }
}

// MARK: - Group Info Sheet

struct GroupInfoView: View {
    let group: ClassGroup
    @ObservedObject var groupService: GroupService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    var onGroupDeleted: (() -> Void)? = nil
    var onGroupLeft: (() -> Void)? = nil

    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @State private var isProcessing = false
    @State private var members: [AppUser] = []
    @State private var isLoadingMembers = true
    @State private var memberToRemove: AppUser?
    @State private var showRemoveMemberConfirmation = false

    // Use the latest group from groupService (real-time) to get accurate member count
    private var liveGroup: ClassGroup {
        groupService.groups.first { $0.id == group.id } ?? group
    }

    private var isCreator: Bool {
        authService.currentUserId == liveGroup.createdBy
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(liveGroup.school)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(liveGroup.name)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("Invite Code")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(liveGroup.inviteCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(.teal)

                        Button {
                            UIPasteboard.general.string = liveGroup.inviteCode
                        } label: {
                            Label("Copy Code", systemImage: "doc.on.doc")
                                .font(.subheadline)
                        }
                        .tint(.teal)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - Members List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundStyle(.secondary)
                            Text("\(liveGroup.members.count) Members")
                                .font(.headline)
                            Spacer()
                        }

                        if isLoadingMembers {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(members) { member in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(member.id == liveGroup.createdBy ? .teal : .secondary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(member.name.isEmpty ? "Parent" : member.name)
                                                .font(.body)
                                                .fontWeight(member.id == authService.currentUserId ? .semibold : .regular)

                                            if member.id == authService.currentUserId {
                                                Text("You")
                                                    .font(.caption)
                                                    .foregroundStyle(.teal)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.teal.opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        if member.id == liveGroup.createdBy {
                                            Text("Admin")
                                                .font(.caption)
                                                .foregroundStyle(.teal)
                                        }
                                    }

                                    Spacer()

                                    // Admin can remove non-admin members
                                    if isCreator && member.id != authService.currentUserId {
                                        Button {
                                            memberToRemove = member
                                            showRemoveMemberConfirmation = true
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.body)
                                                .foregroundStyle(.secondary.opacity(0.5))
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Leave or Delete group
                    if isProcessing {
                        ProgressView()
                            .padding(.bottom, 24)
                    } else if isCreator {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Group", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.bottom, 24)
                    } else {
                        Button(role: .destructive) {
                            showLeaveConfirmation = true
                        } label: {
                            Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadMembers() }
            .onChange(of: liveGroup.members) { _ in
                loadMembers()
            }
            .confirmationDialog("Delete Group", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    isProcessing = true
                    groupService.deleteGroup(liveGroup) { result in
                        isProcessing = false
                        if case .success = result {
                            dismiss()
                            onGroupDeleted?()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete the group, all posts, and all requests. This cannot be undone.")
            }
            .confirmationDialog("Leave Group", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
                Button("Leave", role: .destructive) {
                    isProcessing = true
                    groupService.leaveGroup(groupId: liveGroup.id, userId: authService.currentUserId) { result in
                        isProcessing = false
                        if case .success = result {
                            dismiss()
                            onGroupLeft?()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to leave this group? You can rejoin later with the invite code.")
            }
            .confirmationDialog("Remove Member", isPresented: $showRemoveMemberConfirmation, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        groupService.leaveGroup(groupId: liveGroup.id, userId: member.id) { result in
                            if case .success = result {
                                members.removeAll { $0.id == member.id }
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Remove \(memberToRemove?.name ?? "this member") from the group?")
            }
        }
    }

    private func loadMembers() {
        if AppMode.isDemo {
            members = DemoData.users.filter { liveGroup.members.contains($0.id) }
            isLoadingMembers = false
        } else {
            NotificationService.shared.fetchGroupMembers(memberIds: liveGroup.members) { users in
                DispatchQueue.main.async {
                    self.members = users
                    self.isLoadingMembers = false
                }
            }
        }
    }
}

// MARK: - Request Card

struct RequestCardView: View {
    let request: NoteRequest
    let group: ClassGroup
    @EnvironmentObject var authService: AuthService

    private var subjectInfo: SubjectInfo {
        request.subjectInfo(for: group)
    }

    private var isForCurrentUser: Bool {
        request.targetUserId != nil && request.targetUserId == authService.currentUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(subjectInfo.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(subjectInfo.color.opacity(0.15))
                        .foregroundStyle(subjectInfo.color)
                        .clipShape(Capsule())

                    if isForCurrentUser {
                        Text("For you")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    Text(request.date.shortDisplayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(request.description.isEmpty
                     ? "Need \(subjectInfo.name) notes from \(request.date.shortDisplayString)"
                     : request.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if let targetName = request.targetUserName {
                        Text("Asked by \(request.authorName) from \(targetName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Asked by \(request.authorName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\u{00B7} \(request.responses.count) replies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if request.status == .fulfilled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
