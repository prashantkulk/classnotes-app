import Foundation
import UIKit

protocol StorageServiceProtocol {
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void)
    func uploadImages(_ images: [UIImage], basePath: String, completion: @escaping (Result<[String], Error>) -> Void)
}
