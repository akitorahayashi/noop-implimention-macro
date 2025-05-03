import NoopImplementation
import Foundation

// --- Definitions Moved Here ---

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

// Test case: Protocol with no requirements
@NoopImplementation
protocol EmptyProtocol {} 