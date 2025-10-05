import Foundation

struct GitHubFile: Equatable {
    let path: String
    let content: String
    let sha: String?
}

struct GitHubPublishResult: Equatable {
    let success: Bool
    let url: URL?
    let commitSha: String?
}
