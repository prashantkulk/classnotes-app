import Foundation
import UIKit

class MockStorageService: StorageServiceProtocol {
    // Configurable results
    var uploadImageResult: Result<String, Error> = .success("https://example.com/uploaded.jpg")
    var uploadImagesResult: Result<[String], Error> = .success(["https://example.com/img1.jpg"])

    // Call tracking
    var uploadImageCallCount = 0
    var uploadImageLastPath: String?
    var uploadImagesCallCount = 0
    var uploadImagesLastBasePath: String?
    var uploadImagesLastImageCount: Int?

    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        uploadImageCallCount += 1
        uploadImageLastPath = path
        completion(uploadImageResult)
    }

    func uploadImages(_ images: [UIImage], basePath: String, completion: @escaping (Result<[String], Error>) -> Void) {
        uploadImagesCallCount += 1
        uploadImagesLastBasePath = basePath
        uploadImagesLastImageCount = images.count
        completion(uploadImagesResult)
    }
}
