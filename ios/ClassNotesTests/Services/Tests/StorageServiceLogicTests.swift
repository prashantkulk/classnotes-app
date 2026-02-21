import XCTest
import UIKit

final class StorageServiceLogicTests: XCTestCase {

    var mockService: MockStorageService!

    override func setUp() {
        super.setUp()
        mockService = MockStorageService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - uploadImage

    func testUploadImage_success_returnsURL() {
        mockService.uploadImageResult = .success("https://firebase.storage/photo.jpg")

        let testImage = UIImage()
        let expectation = expectation(description: "upload")
        var receivedURL: String?

        mockService.uploadImage(testImage, path: "posts/123/photo.jpg") { result in
            if case .success(let url) = result {
                receivedURL = url
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedURL, "https://firebase.storage/photo.jpg")
        XCTAssertEqual(mockService.uploadImageCallCount, 1)
        XCTAssertEqual(mockService.uploadImageLastPath, "posts/123/photo.jpg")
    }

    func testUploadImage_failure_returnsError() {
        let testError = NSError(domain: "storage", code: 507, userInfo: [NSLocalizedDescriptionKey: "Storage full"])
        mockService.uploadImageResult = .failure(testError)

        let testImage = UIImage()
        let expectation = expectation(description: "upload")
        var receivedError: Error?

        mockService.uploadImage(testImage, path: "test/path.jpg") { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 507)
    }

    // MARK: - uploadImages

    func testUploadImages_success_returnsURLs() {
        let urls = ["https://example.com/1.jpg", "https://example.com/2.jpg", "https://example.com/3.jpg"]
        mockService.uploadImagesResult = .success(urls)

        let images = [UIImage(), UIImage(), UIImage()]
        let expectation = expectation(description: "uploadMultiple")
        var receivedURLs: [String]?

        mockService.uploadImages(images, basePath: "posts/456") { result in
            if case .success(let u) = result {
                receivedURLs = u
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedURLs?.count, 3)
        XCTAssertEqual(receivedURLs, urls)
        XCTAssertEqual(mockService.uploadImagesCallCount, 1)
        XCTAssertEqual(mockService.uploadImagesLastBasePath, "posts/456")
        XCTAssertEqual(mockService.uploadImagesLastImageCount, 3)
    }

    func testUploadImages_failure_returnsError() {
        let testError = NSError(domain: "storage", code: 500)
        mockService.uploadImagesResult = .failure(testError)

        let expectation = expectation(description: "uploadMultiple")
        var receivedError: Error?

        mockService.uploadImages([], basePath: "test") { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 500)
    }

    func testUploadImages_emptyArray_success() {
        mockService.uploadImagesResult = .success([])

        let expectation = expectation(description: "uploadEmpty")
        var receivedURLs: [String]?

        mockService.uploadImages([], basePath: "empty") { result in
            if case .success(let urls) = result {
                receivedURLs = urls
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedURLs?.count, 0)
        XCTAssertEqual(mockService.uploadImagesLastImageCount, 0)
    }

    // MARK: - Call tracking

    func testUploadImage_multipleCallsTracked() {
        mockService.uploadImageResult = .success("url")
        let img = UIImage()

        let exp1 = expectation(description: "upload1")
        let exp2 = expectation(description: "upload2")

        mockService.uploadImage(img, path: "path/a.jpg") { _ in exp1.fulfill() }
        mockService.uploadImage(img, path: "path/b.jpg") { _ in exp2.fulfill() }

        wait(for: [exp1, exp2], timeout: 1.0)
        XCTAssertEqual(mockService.uploadImageCallCount, 2)
        XCTAssertEqual(mockService.uploadImageLastPath, "path/b.jpg")
    }
}
