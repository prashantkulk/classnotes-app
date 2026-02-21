import Foundation
import UIKit
import FirebaseStorage

class StorageService {
    static let shared = StorageService()

    private lazy var storage = Storage.storage()

    /// Maximum dimension (width or height) for uploaded images.
    /// 1600px is plenty for reading notes on a phone screen while keeping file size small.
    private let maxImageDimension: CGFloat = 1600

    // MARK: - Upload Image

    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Resize image before compressing to dramatically reduce upload size
        let resized = resizeImage(image, maxDimension: maxImageDimension)
        guard let data = resized.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }

        let sizeMB = Double(data.count) / (1024.0 * 1024.0)
        print("[StorageService] Uploading \(path) — \(String(format: "%.1f", sizeMB))MB (\(Int(resized.size.width))x\(Int(resized.size.height)))")

        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(data, metadata: metadata) { [weak self] uploadedMetadata, error in
            if let error {
                print("[StorageService] putData failed for path '\(path)': \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed: \(error.localizedDescription)"])))
                }
                return
            }

            print("[StorageService] putData succeeded for path '\(path)', fetching download URL...")
            self?.fetchDownloadURL(ref: storageRef, path: path, retryCount: 0, completion: completion)
        }
    }

    /// Retry fetching the download URL up to 3 times with increasing delays
    private func fetchDownloadURL(ref: StorageReference, path: String, retryCount: Int, completion: @escaping (Result<String, Error>) -> Void) {
        ref.downloadURL { [weak self] url, error in
            if let error {
                print("[StorageService] downloadURL attempt \(retryCount + 1) failed for path '\(path)': \(error.localizedDescription)")

                if retryCount < 3 {
                    let delay = Double(retryCount + 1) * 1.0 // 1s, 2s, 3s
                    print("[StorageService] Retrying in \(delay)s...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.fetchDownloadURL(ref: ref, path: path, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload succeeded but failed to get download URL after \(retryCount + 1) attempts: \(error.localizedDescription)"])))
                    }
                }
                return
            }

            guard let downloadURL = url else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download URL was nil"])))
                }
                return
            }

            print("[StorageService] Got download URL for path '\(path)'")
            DispatchQueue.main.async {
                completion(.success(downloadURL.absoluteString))
            }
        }
    }

    // MARK: - Upload Multiple Images

    func uploadImages(_ images: [UIImage], basePath: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var urls: [String?] = Array(repeating: nil, count: images.count)
        let group = DispatchGroup()
        var uploadError: Error?

        for (index, image) in images.enumerated() {
            group.enter()
            let path = "\(basePath)/\(UUID().uuidString).jpg"
            uploadImage(image, path: path) { result in
                switch result {
                case .success(let url):
                    urls[index] = url
                case .failure(let error):
                    uploadError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
                return
            }
            completion(.success(urls.compactMap { $0 }))
        }
    }

    // MARK: - Image Resizing

    /// Resize image to fit within maxDimension while maintaining aspect ratio.
    /// If the image is already smaller, return it unchanged.
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
