import Foundation

/// 与 GitHub REST API 交互的服务，支持配置保存、文件读取与写入。
actor GitHubService {
    enum ServiceError: Error {
        case configurationMissing
        case invalidResponse
        case httpError(status: Int, message: String)
        case decodingError
    }

    private let baseURL = URL(string: "https://api.github.com")!
    private let session: URLSession
    private let frontMatterBuilder = FrontMatterBuilder()
    private let pathBuilder = ContentPathBuilder()

    private let defaultsKey = "GitHubConfig"
    private let keychainService = "SwiftMarkdownEditor.GitHub"
    private let keychainAccount = "token"

    private var cachedConfig: GitHubConfig?

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Configuration

    func setConfig(_ config: GitHubConfig) async throws {
        try SecureStore.save(config.token, service: keychainService, account: keychainAccount)
        let storable = CodableConfig(owner: config.owner, repo: config.repo, branch: config.branch)
        let data = try JSONEncoder().encode(storable)
        UserDefaults.standard.set(data, forKey: defaultsKey)
        cachedConfig = config
    }

    func loadConfig() async throws -> GitHubConfig? {
        if let cachedConfig {
            return cachedConfig
        }
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return nil
        }
        let decoded = try JSONDecoder().decode(CodableConfig.self, from: data)
        let token = try SecureStore.read(service: keychainService, account: keychainAccount) ?? ""
        let config = GitHubConfig(token: token, owner: decoded.owner, repo: decoded.repo, branch: decoded.branch)
        cachedConfig = config
        return config
    }

    func isConfigured() async throws -> Bool {
        try await loadConfig()?.isValid ?? false
    }

    func clearConfig() async throws {
        try SecureStore.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        cachedConfig = nil
    }

    // MARK: - API Requests

    private func performRequest(path: String, method: String = "GET", body: Data? = nil, additionalHeaders: [String: String] = [:]) async throws -> Data {
        guard let config = try await loadConfig(), config.isValid else {
            throw ServiceError.configurationMissing
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("token \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SwiftMarkdownEditor", forHTTPHeaderField: "User-Agent")
        additionalHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: httpResponse.statusCode, message: message)
        }

        return data
    }

    // MARK: - File Operations

    func fetchFile(at path: String) async throws -> GitHubFile? {
        guard let config = try await loadConfig(), config.isValid else {
            throw ServiceError.configurationMissing
        }

        let endpoint = "repos/\(config.owner)/\(config.repo)/contents/\(path)"
        do {
            let data = try await performRequest(path: endpoint)
            let decoded = try JSONDecoder().decode(GitHubContentResponse.self, from: data)
            let contentData = Data(base64Encoded: decoded.content.filter { !$0.isWhitespace }) ?? Data()
            let content = String(data: contentData, encoding: .utf8) ?? ""
            return GitHubFile(path: decoded.path, content: content, sha: decoded.sha)
        } catch ServiceError.httpError(let status, _) where status == 404 {
            return nil
        }
    }

    func ensureRepositoryAccess() async throws {
        guard let config = try await loadConfig(), config.isValid else {
            throw ServiceError.configurationMissing
        }
        _ = try await performRequest(path: "repos/\(config.owner)/\(config.repo)")
    }

    func publish(contentType: ContentType, metadata: MetadataStore, body: String, commitMessage: String? = nil, overridePath: String? = nil) async throws -> GitHubPublishResult {
        guard let config = try await loadConfig(), config.isValid else {
            throw ServiceError.configurationMissing
        }

        let preparedContent = frontMatterBuilder.compose(contentType: contentType, metadata: metadata, body: body)
        let path = overridePath ?? pathBuilder.generatePath(for: contentType, metadata: metadata, body: body)
        let fileInfo = try await fetchFile(at: path)

        let payload = GitHubCreateOrUpdateRequest(
            message: commitMessage ?? defaultCommitMessage(for: contentType),
            content: preparedContent.data(using: .utf8)?.base64EncodedString() ?? "",
            branch: config.branch,
            sha: fileInfo?.sha
        )

        let bodyData = try JSONEncoder().encode(payload)
        let endpoint = "repos/\(config.owner)/\(config.repo)/contents/\(path)"
        let data = try await performRequest(path: endpoint, method: "PUT", body: bodyData)
        let response = try JSONDecoder().decode(GitHubWriteResponse.self, from: data)
        cachedConfig = config // ensure token retained
        return GitHubPublishResult(
            success: true,
            url: URL(string: response.content.htmlURL ?? ""),
            commitSha: response.commit.sha
        )
    }

    func testConnection() async throws {
        try await ensureRepositoryAccess()
    }

    // MARK: - Helpers

    private func defaultCommitMessage(for contentType: ContentType) -> String {
        switch contentType {
        case .blog:
            return "feat: 发布 Blog 内容"
        case .essay:
            return "feat: 发布 Essay 内容"
        case .gallery:
            return "feat: 更新 Gallery 资源"
        case .general:
            return "feat: 更新内容"
        }
    }
}

// MARK: - Codable Helpers

private struct CodableConfig: Codable {
    let owner: String
    let repo: String
    let branch: String
}

private struct GitHubContentResponse: Decodable {
    let path: String
    let content: String
    let sha: String
}

private struct GitHubCreateOrUpdateRequest: Encodable {
    let message: String
    let content: String
    let branch: String
    let sha: String?
}

private struct GitHubWriteResponse: Decodable {
    struct Commit: Decodable {
        let sha: String
        let htmlURL: String?
        private enum CodingKeys: String, CodingKey {
            case sha
            case htmlURL = "html_url"
        }
    }

    struct Content: Decodable {
        let path: String
        let sha: String
        let htmlURL: String?
        private enum CodingKeys: String, CodingKey {
            case path
            case sha
            case htmlURL = "html_url"
        }
    }

    let content: Content
    let commit: Commit
}
