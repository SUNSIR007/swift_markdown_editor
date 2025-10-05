import Foundation

/// GitHub 仓库访问配置
struct GitHubConfig: Codable, Equatable {
    var token: String
    var owner: String
    var repo: String
    var branch: String

    init(token: String = "", owner: String = "", repo: String = "", branch: String = "main") {
        self.token = token
        self.owner = owner
        self.repo = repo
        self.branch = branch.isEmpty ? "main" : branch
    }

    var isValid: Bool {
        !token.isEmpty && !owner.isEmpty && !repo.isEmpty
    }
}

/// 图片上传仓库配置（复用 GitHub 配置并带有图片目录等参数）。
struct ImageServiceConfig: Codable, Equatable {
    var token: String
    var owner: String
    var repo: String
    var branch: String
    var imageDirectory: String
    var linkRule: ImageCDNRule.RuleIdentifier

    init(token: String = "", owner: String = "", repo: String = "", branch: String = "master", imageDirectory: String = "images", linkRule: ImageCDNRule.RuleIdentifier = .jsdelivr) {
        self.token = token
        self.owner = owner
        self.repo = repo
        self.branch = branch.isEmpty ? "master" : branch
        self.imageDirectory = imageDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        self.linkRule = linkRule
    }

    var isValid: Bool {
        !token.isEmpty && !owner.isEmpty && !repo.isEmpty
    }
}
