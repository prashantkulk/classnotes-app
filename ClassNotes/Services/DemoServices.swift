import Foundation
import SwiftUI

// MARK: - Global Demo Mode Flag
enum AppMode {
    static var isDemo = false
}

// MARK: - Demo Auth Service

class DemoAuthService: AuthService {
    // super.init() will return early because AppMode.isDemo is true

    override func sendOTP(to phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(()))
        }
    }

    override func verifyOTP(_ code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentUserId = "demo-user-1"
            self.isAuthenticated = true
            self.needsOnboarding = true
            completion(.success(()))
        }
    }

    override func completeOnboarding(name: String?) {
        let userName = name ?? "Parent"
        self.currentUserName = userName
        self.needsOnboarding = false
    }

    override func signOut() {
        self.isAuthenticated = false
        self.currentUserId = ""
        self.currentUserName = ""
        self.needsOnboarding = false
    }

    override func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAuthenticated = false
            self.currentUserId = ""
            self.currentUserName = ""
            self.needsOnboarding = false
            completion(.success(()))
        }
    }
}

// MARK: - Demo Group Service

class DemoGroupService: GroupService {
    // super.init() is fine — db is lazy so Firestore won't be accessed

    override func loadGroups(for userId: String) {
        DispatchQueue.main.async {
            self.groups = DemoData.groups
        }
    }

    override func createGroup(_ group: ClassGroup, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var newGroup = group
            newGroup.members = [group.createdBy]
            self.groups.insert(newGroup, at: 0)
            completion(.success(newGroup))
        }
    }

    override func joinGroup(code: String, userId: String, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let group = DemoData.groups.first(where: { $0.inviteCode == code }) {
                // Check if already a member
                if group.members.contains(userId) || self.groups.contains(where: { $0.id == group.id }) {
                    completion(.failure(NSError(domain: "", code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "You are already a member of \(group.name)."])))
                    return
                }
                var joined = group
                joined.members.append(userId)
                self.groups.insert(joined, at: 0)
                completion(.success(joined))
            } else {
                completion(.failure(NSError(domain: "", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No group found with this code. Try: DEMO01"])))
            }
        }
    }
}

// MARK: - Demo Post Service

class DemoPostService: PostService {
    // super.init() is fine — db is lazy so Firestore won't be accessed

    override func loadPosts(for groupId: String) {
        DispatchQueue.main.async {
            self.posts = DemoData.posts.filter { $0.groupId == groupId }
        }
    }

    override func createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String,
        images: [UIImage],
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Generate placeholder URLs for images
            let photoURLs = images.enumerated().map { index, _ in
                "https://picsum.photos/seed/\(UUID().uuidString)/400/600"
            }

            let post = Post(
                id: UUID().uuidString,
                groupId: groupId,
                authorId: authorId,
                authorName: authorName,
                subject: subject,
                date: date,
                description: description,
                photoURLs: photoURLs.isEmpty ? ["https://picsum.photos/seed/demo/400/600"] : photoURLs
            )
            self.posts.insert(post, at: 0)
            completion(.success(post))
        }
    }
}

// MARK: - Demo Request Service

class DemoRequestService: RequestService {
    // super.init() is fine — db is lazy so Firestore won't be accessed

    override func loadRequests(for groupId: String) {
        DispatchQueue.main.async {
            self.requests = DemoData.requests.filter { $0.groupId == groupId }
        }
    }

    override func createRequest(
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String,
        targetUserId: String? = nil,
        targetUserName: String? = nil,
        completion: @escaping (Result<NoteRequest, Error>) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let request = NoteRequest(
                id: UUID().uuidString,
                groupId: groupId,
                authorId: authorId,
                authorName: authorName,
                subject: subject,
                date: date,
                description: description,
                targetUserId: targetUserId,
                targetUserName: targetUserName
            )
            self.requests.insert(request, at: 0)
            completion(.success(request))
        }
    }

    override func respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        images: [UIImage],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let index = self.requests.firstIndex(where: { $0.id == requestId }) {
                let photoURLs = images.isEmpty
                    ? ["https://picsum.photos/seed/resp/400/600"]
                    : images.map { _ in "https://picsum.photos/seed/\(UUID().uuidString)/400/600" }

                let response = RequestResponse(
                    authorId: authorId,
                    authorName: authorName,
                    photoURLs: photoURLs
                )
                self.requests[index].responses.append(response)
                self.requests[index].status = .fulfilled
            }
            completion(.success(()))
        }
    }

    override func markAsFulfilled(requestId: String) {
        if let index = requests.firstIndex(where: { $0.id == requestId }) {
            requests[index].status = .fulfilled
        }
    }
}

// MARK: - Demo Data

enum DemoData {
    static let users: [AppUser] = [
        AppUser(id: "demo-user-1", phone: "+919876543210", name: "You"),
        AppUser(id: "demo-user-2", phone: "+919876543211", name: "Priya's Mom"),
        AppUser(id: "demo-user-3", phone: "+919876543212", name: "Rahul's Dad"),
        AppUser(id: "demo-user-4", phone: "+919876543213", name: "Ananya's Mom"),
        AppUser(id: "demo-user-5", phone: "+919876543214", name: "Vikram's Mom"),
        AppUser(id: "demo-user-6", phone: "+919876543215", name: "Neha's Dad"),
        AppUser(id: "demo-user-7", phone: "+919876543216", name: "Arjun's Mom"),
    ]

    static let groups: [ClassGroup] = [
        ClassGroup(
            id: "demo-group-1",
            name: "Class 5A",
            school: "Delhi Public School",
            inviteCode: "DEMO01",
            members: ["demo-user-1", "demo-user-2", "demo-user-3", "demo-user-4", "demo-user-5"],
            createdBy: "demo-user-1"
        ),
        ClassGroup(
            id: "demo-group-2",
            name: "Class 5B",
            school: "Delhi Public School",
            inviteCode: "DEMO02",
            members: ["demo-user-1", "demo-user-6", "demo-user-7"],
            createdBy: "demo-user-6"
        ),
    ]

    static let posts: [Post] = [
        Post(
            id: "demo-post-1",
            groupId: "demo-group-1",
            authorId: "demo-user-2",
            authorName: "Priya's Mom",
            subject: .math,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            description: "Chapter 7 - Fractions and Decimals (all 4 pages)",
            photoURLs: [
                "https://picsum.photos/seed/math1/400/600",
                "https://picsum.photos/seed/math2/400/600",
                "https://picsum.photos/seed/math3/400/600",
                "https://picsum.photos/seed/math4/400/600",
            ]
        ),
        Post(
            id: "demo-post-2",
            groupId: "demo-group-1",
            authorId: "demo-user-3",
            authorName: "Rahul's Dad",
            subject: .science,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            description: "Water cycle diagram + notes from today's class",
            photoURLs: [
                "https://picsum.photos/seed/sci1/400/600",
                "https://picsum.photos/seed/sci2/400/600",
            ]
        ),
        Post(
            id: "demo-post-3",
            groupId: "demo-group-1",
            authorId: "demo-user-4",
            authorName: "Ananya's Mom",
            subject: .english,
            date: Date(),
            description: "Grammar - Tenses worksheet",
            photoURLs: [
                "https://picsum.photos/seed/eng1/400/600",
            ]
        ),
        Post(
            id: "demo-post-4",
            groupId: "demo-group-1",
            authorId: "demo-user-2",
            authorName: "Priya's Mom",
            subject: .hindi,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            description: "Hindi essay topic and reference notes",
            photoURLs: [
                "https://picsum.photos/seed/hindi1/400/600",
                "https://picsum.photos/seed/hindi2/400/600",
            ]
        ),
        Post(
            id: "demo-post-5",
            groupId: "demo-group-1",
            authorId: "demo-user-5",
            authorName: "Vikram's Mom",
            subject: .socialStudies,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            description: "History - Mughal Empire timeline",
            photoURLs: [
                "https://picsum.photos/seed/ss1/400/600",
            ]
        ),
        Post(
            id: "demo-post-6",
            groupId: "demo-group-2",
            authorId: "demo-user-6",
            authorName: "Neha's Dad",
            subject: .math,
            date: Date(),
            description: "Geometry homework - angles worksheet",
            photoURLs: [
                "https://picsum.photos/seed/geo1/400/600",
                "https://picsum.photos/seed/geo2/400/600",
            ]
        ),
    ]

    static let requests: [NoteRequest] = [
        NoteRequest(
            id: "demo-req-1",
            groupId: "demo-group-1",
            authorId: "demo-user-1",
            authorName: "You",
            subject: .science,
            date: Date(),
            description: "My child was absent today. Can someone share the Science notes from today's class?"
        ),
        NoteRequest(
            id: "demo-req-2",
            groupId: "demo-group-1",
            authorId: "demo-user-4",
            authorName: "Ananya's Mom",
            subject: .math,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            description: "Need Math homework page - Ananya forgot to copy it",
            status: .fulfilled,
            responses: [
                RequestResponse(
                    id: "demo-resp-1",
                    authorId: "demo-user-2",
                    authorName: "Priya's Mom",
                    photoURLs: ["https://picsum.photos/seed/resp1/400/600"]
                )
            ]
        ),
        NoteRequest(
            id: "demo-req-3",
            groupId: "demo-group-1",
            authorId: "demo-user-3",
            authorName: "Rahul's Dad",
            subject: .english,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            description: "English comprehension passage from Monday's class"
        ),
        NoteRequest(
            id: "demo-req-4",
            groupId: "demo-group-1",
            authorId: "demo-user-2",
            authorName: "Priya's Mom",
            subject: .hindi,
            date: Date(),
            description: "Can you share Hindi notes from today? Priya says your child writes very neatly!",
            targetUserId: "demo-user-1",
            targetUserName: "You"
        ),
    ]
}
