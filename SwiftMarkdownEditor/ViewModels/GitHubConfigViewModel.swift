import Foundation

@MainActor
final class GitHubConfigViewModel: ObservableObject {
    @Published var githubConfig = GitHubConfig()
    @Published var imageConfig = ImageServiceConfig()
    @Published var linkRule: ImageCDNRule.RuleIdentifier = .jsdelivr
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let githubService: GitHubService
    private let imageService: ImageUploadService

    init(githubService: GitHubService = GitHubService(), imageService: ImageUploadService = ImageUploadService()) {
        self.githubService = githubService
        self.imageService = imageService
        Task { await loadExistingConfiguration() }
    }

    func loadExistingConfiguration() async {
        if let config = try? await githubService.loadConfig() {
            githubConfig = config
        }
        if let image = try? await imageService.loadConfig() {
            imageConfig = image
            linkRule = image.linkRule
        }
    }

    func save() {
        Task {
            do {
                try await githubService.setConfig(githubConfig)
                var updatedImageConfig = imageConfig
                updatedImageConfig.linkRule = linkRule
                try await imageService.setConfig(updatedImageConfig)
                statusMessage = "配置已保存"
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func testGitHubConnection() {
        Task {
            do {
                try await githubService.testConnection()
                statusMessage = "GitHub 连接成功"
                errorMessage = nil
            } catch {
                errorMessage = "GitHub 连接失败: \(error.localizedDescription)"
            }
        }
    }
}
