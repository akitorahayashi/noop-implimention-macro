import Foundation

// MARK: - Data Models

// データ構造
// (クライアント内部でのみ使用されるため public は不要)
struct UserProfile: Equatable {
    let id: String
    let name: String
    let email: String?

    init(id: String, name: String, email: String?) {
        self.id = id
        self.name = name
        self.email = email
    }
} 