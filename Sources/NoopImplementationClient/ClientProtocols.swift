import Foundation
import NoopImplementation

// マクロを使用するプロトコル
@NoopImplementation
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

@NoopImplementation
public protocol UserAPI {
    var fetchUserProfileCalledCount: Int { get }

    func fetchUserProfile(id: String) async throws -> UserProfile
}
