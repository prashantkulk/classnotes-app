import Foundation
import UIKit
import FirebaseStorage

class StorageService {
    static let shared = StorageService()

    private lazy var storage = Storage.storage()

    // MARK: - Upload Image

    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }

        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(data, metadata: metadata) { _, error in
            if let error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }

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
}
