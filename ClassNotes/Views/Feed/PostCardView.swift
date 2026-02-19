import SwiftUI

struct PostCardView: View {
    let post: Post
    @State private var selectedPhotoIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Subject badge + date
            HStack(spacing: 8) {
                Text(post.subject.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(post.subject.color.opacity(0.15))
                    .foregroundStyle(post.subject.color)
                    .clipShape(Capsule())

                Text(post.date.displayString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Photo thumbnails (horizontal scroll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(post.photoURLs.enumerated()), id: \.offset) { index, url in
                        Button {
                            selectedPhotoIndex = index
                        } label: {
                            AsyncImageView(url: url)
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

            // Description (if any)
            if !post.description.isEmpty {
                Text(post.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            // Author + time
            HStack {
                Image(systemName: "person.circle")
                    .foregroundStyle(.secondary)
                Text("Shared by \(post.authorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(post.createdAt.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .fullScreenCover(item: $selectedPhotoIndex) { index in
            PhotoViewer(photoURLs: post.photoURLs, initialIndex: index)
        }
    }
}

// Make Int conform to Identifiable for fullScreenCover
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Async Image View

struct AsyncImageView: View {
    let url: String

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            case .empty:
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            @unknown default:
                Color(.systemGray5)
            }
        }
    }
}

#Preview {
    PostCardView(post: Post(
        groupId: "1",
        authorId: "1",
        authorName: "Priya's Mom",
        subject: .math,
        date: Date(),
        description: "Today's algebra notes",
        photoURLs: []
    ))
    .padding()
}
