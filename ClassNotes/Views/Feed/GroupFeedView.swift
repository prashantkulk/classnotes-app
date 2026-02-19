import SwiftUI

enum FeedTab: String, CaseIterable {
    case notes = "Notes"
    case requests = "Requests"
}

struct GroupFeedView: View {
    let group: ClassGroup
    @StateObject private var postService: PostService = AppMode.isDemo ? DemoPostService() : PostService()
    @StateObject private var requestService: RequestService = AppMode.isDemo ? DemoRequestService() : RequestService()
    @State private var selectedTab: FeedTab = .notes
    @State private var selectedSubject: Subject?
    @State private var showCreatePost = false
    @State private var showCreateRequest = false
    @State private var showGroupInfo = false

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
        .navigationTitle(group.name)
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
            CreatePostView(group: group, postService: postService)
        }
        .sheet(isPresented: $showCreateRequest) {
            CreateRequestView(group: group, requestService: requestService)
        }
        .sheet(isPresented: $showGroupInfo) {
            GroupInfoView(group: group)
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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPosts) { post in
                                PostCardView(post: post)
                            }
                        }
                        .padding()
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
                filterPill(label: "All", isSelected: selectedSubject == nil) {
                    selectedSubject = nil
                }

                ForEach(Subject.allCases) { subject in
                    filterPill(
                        label: subject.rawValue,
                        color: subject.color,
                        isSelected: selectedSubject == subject
                    ) {
                        selectedSubject = subject
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
        if let subject = selectedSubject {
            return postService.posts.filter { $0.subject == subject }
        }
        return postService.posts
    }

    // MARK: - Requests Content

    private var requestsContent: some View {
        ZStack(alignment: .bottomTrailing) {
            if requestService.requests.isEmpty {
                emptyRequestsState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(requestService.requests) { request in
                            NavigationLink(destination: RequestDetailView(request: request, requestService: requestService)) {
                                RequestCardView(request: request)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(group.school)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(group.name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("Invite Code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(group.inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.teal)

                    Button {
                        UIPasteboard.general.string = group.inviteCode
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

                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(.secondary)
                    Text("\(group.members.count) members")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Request Card

struct RequestCardView: View {
    let request: NoteRequest
    @EnvironmentObject var authService: AuthService

    private var isForCurrentUser: Bool {
        request.targetUserId != nil && request.targetUserId == authService.currentUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(request.subject.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(request.subject.color.opacity(0.15))
                        .foregroundStyle(request.subject.color)
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
                     ? "Need \(request.subject.rawValue) notes from \(request.date.shortDisplayString)"
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
                    Text("· \(request.responses.count) replies")
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
