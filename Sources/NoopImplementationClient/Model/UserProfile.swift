import Foundation

public struct UserProfile: Equatable {
    public let id: String
    public let name: String
    public let email: String?
    public let registrationDate: Date
}
