import Foundation
import NoopImplementation

// マクロを使用するプロトコル
@NoopImplementation(overrides: [
    "UserProfile": UserProfile(id: "default-id", name: "Default User", email: "default@example.com",
                               registrationDate: Date()),
])
protocol UserProfileFetcherProtocol {
    var defaultUsername: String { get }

    func fetchUserProfile(userID: String) async throws -> UserProfile
    func clearCache()
}

@NoopImplementation
protocol ImageCacheProtocol {
    func loadImage(url: URL) -> Data?
    func storeImage(_ image: Data, for url: URL)
}

@NoopImplementation
protocol EmptyProtocol {}

@NoopImplementation(overrides: [
    "UserProfile": UserProfile(id: "default-id", name: "Default User", email: "default@example.com",
                               registrationDate: Date()),
])
public protocol UserAPI {
    var fetchUserProfileCalledCount: Int { get }

    func fetchUserProfile(id: String) async throws -> UserProfile
}
