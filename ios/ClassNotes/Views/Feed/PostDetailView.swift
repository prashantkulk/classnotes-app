import SwiftUI
import PhotosUI

struct PostDetailView: View {
    let post: Post
    let group: ClassGroup
    @ObservedObject var postService: PostService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var commentText: String = ""
    @State private var isAddingComment = false
    @State private var selectedPhotoIndex: Int?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showAddPhotos = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploadingPhotos = false

    // Live post from the snapshot listener
    private var livePost: Post {
        postService.posts.first { $0.id == post.id } ?? post
    }

    private var subjectInfo: SubjectInfo { livePost.subjectInfo(for: group) }
    private var isOwner: Bool { livePost.authorId == authService.currentUserId }

    private let availableReactions = ["👍", "🙏", "❤️", "📝"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    headerSection

                    // Photos
                    photosSection

                    // Description
                    if !livePost.description.isEmpty {
                        Text(livePost.description)
                            .font(.body)
                            .padding(.horizontal, 16)
                    }

                    // Reactions
                    reactionsSection

                    Divider()
                        .padding(.horizontal, 16)

                    // Comments
                    commentsSection
                }
                .padding(.bottom, 16)
            }

            // Comment input bar
            commentInputBar
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if isOwner {
                        Button {
                            showAddPhotos = true
                        } label: {
                            Label("Add More Photos", systemImage: "photo.on.rectangle.angled")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Notes", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(!isOwner)
                .opacity(isOwner ? 1 : 0)
            }
        }
        .confirmationDialog("Delete Notes", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                isDeleting = true
                postService.deletePost(livePost) { result in
                    isDeleting = false
                    if case .success = result {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete these notes? This cannot be undone.")
        }
        .photosPicker(isPresented: $showAddPhotos, selection: $selectedItems, maxSelectionCount: 10, matching: .images)
        .onChange(of: selectedItems) { items in
            guard !items.isEmpty else { return }
            uploadAdditionalPhotos(items: items)
        }
        .fullScreenCover(item: $selectedPhotoIndex) { index in
            PhotoViewer(photoURLs: livePost.photoURLs, initialIndex: index)
        }
        .overlay {
            if isDeleting || isUploadingPhotos {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(isDeleting ? "Deleting..." : "Uploading photos...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Text(subjectInfo.name)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(subjectInfo.color.opacity(0.15))
                .foregroundStyle(subjectInfo.color)
                .clipShape(Capsule())

            Text(livePost.date.displayString)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(livePost.authorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(livePost.createdAt.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Photos

    private var photosSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(livePost.photoURLs.enumerated()), id: \.offset) { index, url in
                    Button {
                        selectedPhotoIndex = index
                    } label: {
                        CachedAsyncImage(url: url)
                            .frame(width: 200, height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reactions

    private var reactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing reactions
            if !livePost.reactions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(livePost.reactions, id: \.emoji) { reaction in
                            let isActive = reaction.userIds.contains(authService.currentUserId)
                            Button {
                                postService.toggleReaction(postId: livePost.id, emoji: reaction.emoji, userId: authService.currentUserId, currentReactions: livePost.reactions) { _ in }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(reaction.emoji)
                                    Text("\(reaction.userIds.count)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isActive ? Color.teal.opacity(0.15) : Color(.systemGray6))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isActive ? Color.teal : Color.clear, lineWidth: 1.5)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Add reaction buttons
            HStack(spacing: 8) {
                ForEach(availableReactions, id: \.self) { emoji in
                    let existing = livePost.reactions.first { $0.emoji == emoji }
                    let isActive = existing?.userIds.contains(authService.currentUserId) ?? false
                    if existing == nil {
                        Button {
                            postService.toggleReaction(postId: livePost.id, emoji: emoji, userId: authService.currentUserId, currentReactions: livePost.reactions) { _ in }
                        } label: {
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(livePost.comments.count) Comments")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            if livePost.comments.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
            } else {
                ForEach(livePost.comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(comment.createdAt.timeAgo)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(comment.text)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        HStack(spacing: 8) {
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                sendComment()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.teal)
            }
            .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isAddingComment)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Actions

    private func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        isAddingComment = true
        commentText = ""

        postService.addComment(to: livePost.id, authorId: authService.currentUserId, authorName: authService.currentUserName, text: text) { _ in
            isAddingComment = false
        }
    }

    private func uploadAdditionalPhotos(items: [PhotosPickerItem]) {
        isUploadingPhotos = true
        var images: [UIImage] = []
        let group = DispatchGroup()

        for item in items {
            group.enter()
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        images.append(image)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            selectedItems = []
            guard !images.isEmpty else {
                isUploadingPhotos = false
                return
            }
            postService.addPhotos(to: livePost.id, images: images) { _ in
                isUploadingPhotos = false
            }
        }
    }
}
