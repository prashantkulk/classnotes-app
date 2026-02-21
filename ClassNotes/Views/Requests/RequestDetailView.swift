import SwiftUI
import PhotosUI

struct RequestDetailView: View {
    let request: NoteRequest
    @ObservedObject var requestService: RequestService
    @ObservedObject var postService: PostService
    let group: ClassGroup
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var selectedPhotoIndex: Int?
    @State private var selectedResponsePhotos: [String] = []
    @State private var showDeleteConfirmation = false

    private var subjectInfo: SubjectInfo { request.subjectInfo(for: group) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Request header
                requestHeader

                Divider()

                // Responses
                if request.responses.isEmpty {
                    emptyResponsesView
                } else {
                    responsesView
                }
            }
            .padding()
        }
        .navigationTitle("Request")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            responseButton
        }
        .fullScreenCover(item: $selectedPhotoIndex) { index in
            PhotoViewer(photoURLs: selectedResponsePhotos, initialIndex: index)
        }
        .toolbar {
            if request.authorId == authService.currentUserId {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .confirmationDialog("Delete Request", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                requestService.deleteRequest(request) { _ in
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this request? This cannot be undone.")
        }
    }

    // MARK: - Request Header

    private var requestHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(subjectInfo.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(subjectInfo.color.opacity(0.15))
                    .foregroundStyle(subjectInfo.color)
                    .clipShape(Capsule())

                Text(request.date.displayString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if request.status == .fulfilled {
                    Label("Fulfilled", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            if !request.description.isEmpty {
                Text(request.description)
                    .font(.body)
            }

            if let targetName = request.targetUserName {
                HStack(spacing: 6) {
                    Image(systemName: "at")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Requested from \(targetName)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Image(systemName: "person.circle")
                    .foregroundStyle(.secondary)
                Text("Asked by \(request.authorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(request.createdAt.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Responses

    private var emptyResponsesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No responses yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Be the first to help!")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var responsesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(request.responses.count) Response\(request.responses.count == 1 ? "" : "s")")
                .font(.headline)

            ForEach(request.responses) { response in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.teal)
                        Text(response.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(response.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(response.photoURLs.enumerated()), id: \.offset) { index, url in
                                Button {
                                    selectedResponsePhotos = response.photoURLs
                                    selectedPhotoIndex = index
                                } label: {
                                    CachedAsyncImage(url: url)
                                        .frame(width: 120, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Response Button

    private var responseButton: some View {
        VStack(spacing: 0) {
            Divider()

            PhotosPicker(selection: $selectedPhotos,
                         maxSelectionCount: 10,
                         matching: .images) {
                if isUploading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Label("Respond with Photos", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isUploading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onChange(of: selectedPhotos) { items in
                uploadResponse(items: items)
            }
        }
        .background(.bar)
    }

    // MARK: - Actions

    private func uploadResponse(items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isUploading = true

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
            // Also create a post so the notes appear in the Notes tab
            postService.createPost(
                groupId: request.groupId,
                authorId: authService.currentUserId,
                authorName: authService.currentUserName,
                subjectName: request.subjectName,
                date: request.date,
                description: request.description.isEmpty
                    ? "\(request.subjectName) notes (from request)"
                    : request.description,
                images: images
            ) { _ in
                // Post created (or failed silently) — now update the request
                requestService.respondToRequest(
                    requestId: request.id,
                    authorId: authService.currentUserId,
                    authorName: authService.currentUserName,
                    images: images
                ) { _ in
                    isUploading = false
                    selectedPhotos = []
                }
            }
        }
    }
}
