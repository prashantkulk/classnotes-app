import SwiftUI

struct PostCardView: View {
    let post: Post
    let group: ClassGroup
    @State private var selectedPhotoIndex: Int?

    private var subjectInfo: SubjectInfo { post.subjectInfo(for: group) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Subject badge + date
            HStack(spacing: 8) {
                Text(subjectInfo.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(subjectInfo.color.opacity(0.15))
                    .foregroundStyle(subjectInfo.color)
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
                            CachedAsyncImage(url: url)
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

            // Reactions summary
            if !post.reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(post.reactions, id: \.emoji) { reaction in
                        HStack(spacing: 2) {
                            Text(reaction.emoji)
                                .font(.caption)
                            Text("\(reaction.userIds.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Author + time + comment count
            HStack {
                Image(systemName: "person.circle")
                    .foregroundStyle(.secondary)
                Text("Shared by \(post.authorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !post.comments.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.right")
                            .font(.caption2)
                        Text("\(post.comments.count)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

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

// MARK: - Image Cache

/// In-memory + disk image cache using NSCache and URLCache
final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit

        // Configure URLSession with aggressive disk caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,  // 20MB memory
                                   diskCapacity: 200 * 1024 * 1024)    // 200MB disk
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func image(for urlString: String) -> UIImage? {
        memoryCache.object(forKey: urlString as NSString)
    }

    func setImage(_ image: UIImage, for urlString: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: urlString as NSString, cost: cost)
    }

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Check memory cache first
        if let cached = image(for: urlString) {
            completion(cached)
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // URLSession will check disk cache automatically via returnCacheDataElseLoad
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.setImage(image, for: urlString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage: View {
    let url: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasFailed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if hasFailed {
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            } else {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        // Check memory cache synchronously first
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            isLoading = false
            return
        }

        ImageCache.shared.loadImage(from: url) { loadedImage in
            if let loadedImage {
                image = loadedImage
            } else {
                hasFailed = true
            }
            isLoading = false
        }
    }
}

#Preview {
    PostCardView(post: Post(
        groupId: "1",
        authorId: "1",
        authorName: "Aditi's Mom",
        subject: .math,
        date: Date(),
        description: "Today's algebra notes",
        photoURLs: []
    ), group: ClassGroup(name: "Class 5B", school: "St. Mary's", createdBy: "1"))
    .padding()
}
