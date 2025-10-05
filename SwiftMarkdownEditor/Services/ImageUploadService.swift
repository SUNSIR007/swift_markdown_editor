import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

/// 管理图片上传至 GitHub 仓库，并返回对应 CDN 链接。
actor ImageUploadService {
    enum ServiceError: Error {
        case configurationMissing
        case invalidImageData
        case httpError(status: Int, message: String)
    }

    private let baseURL = URL(string: "https://api.github.com")!
    private let session: URLSession

    private let defaultsKey = "ImageServiceConfig"
    private let keychainService = "SwiftMarkdownEditor.Image"
    private let keychainAccount = "token"

    private var cachedConfig: ImageServiceConfig?

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Configuration

    func setConfig(_ config: ImageServiceConfig) async throws {
        try SecureStore.save(config.token, service: keychainService, account: keychainAccount)
        let storable = CodableConfig(owner: config.owner, repo: config.repo, branch: config.branch, imageDirectory: config.imageDirectory, linkRule: config.linkRule)
        let data = try JSONEncoder().encode(storable)
        UserDefaults.standard.set(data, forKey: defaultsKey)
        cachedConfig = config
    }

    func loadConfig() async throws -> ImageServiceConfig? {
        if let cachedConfig {
            return cachedConfig
        }
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return nil
        }
        let decoded = try JSONDecoder().decode(CodableConfig.self, from: data)
        let token = try SecureStore.read(service: keychainService, account: keychainAccount) ?? ""
        let config = ImageServiceConfig(
            token: token,
            owner: decoded.owner,
            repo: decoded.repo,
            branch: decoded.branch,
            imageDirectory: decoded.imageDirectory,
            linkRule: decoded.linkRule
        )
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

    // MARK: - Upload

    func upload(_ asset: ImageUploadAsset, compressIfNeeded: Bool = true) async throws -> ImageUploadResult {
        guard var config = try await loadConfig(), config.isValid else {
            throw ServiceError.configurationMissing
        }

        var processedData = asset.data
        if compressIfNeeded {
            processedData = await compressDataIfPossible(asset)
        }

        let fileName = normalizedFileName(asset.fileName, fallbackExtension: asset.fileExtension)
        let remotePath = [config.imageDirectory, fileName]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        let payload = GitHubCreateOrUpdateRequest(
            message: "chore: 上传图片 \(fileName)",
            content: processedData.base64EncodedString(),
            branch: config.branch,
            sha: nil
        )

        let endpoint = "repos/\(config.owner)/\(config.repo)/contents/\(remotePath)"
        let body = try JSONEncoder().encode(payload)
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("token \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SwiftMarkdownEditor", forHTTPHeaderField: "User-Agent")

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.httpError(status: -1, message: "Invalid response")
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: responseData, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: httpResponse.statusCode, message: message)
        }

        let rule = ImageCDNRule.rule(for: config.linkRule)
        let cdnURL = rule.formattedURL(owner: config.owner, repo: config.repo, branch: config.branch, path: remotePath)
        return ImageUploadResult(fileName: fileName, remotePath: remotePath, cdnURL: cdnURL)
    }

    // MARK: - Helpers

    private func normalizedFileName(_ name: String, fallbackExtension: String) -> String {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9.]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if sanitized.isEmpty {
            return "image-\(Int(Date().timeIntervalSince1970)).\(fallbackExtension)"
        }
        if sanitized.contains(".") {
            return sanitized
        }
        return "\(sanitized).\(fallbackExtension)"
    }

    private func compressDataIfPossible(_ asset: ImageUploadAsset) async -> Data {
        #if canImport(UIKit)
        guard let image = UIImage(data: asset.data) else {
            return asset.data
        }
        let targetSize: CGFloat = 2048
        let maxDimension = max(image.size.width, image.size.height)
        let scale = min(1, targetSize / maxDimension)
        var resizedImage = image
        if scale < 1 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        let compressionQuality: CGFloat = 0.85
        return resizedImage.jpegData(compressionQuality: compressionQuality) ?? asset.data
        #else
        return asset.data
        #endif
    }
}

// MARK: - Supporting Types

struct ImageUploadAsset {
    let fileName: String
    let data: Data
    let utType: UTType

    var fileExtension: String {
        utType.preferredFilenameExtension ?? "dat"
    }
}

struct ImageUploadResult: Equatable {
    let fileName: String
    let remotePath: String
    let cdnURL: URL?
}

private struct CodableConfig: Codable {
    let owner: String
    let repo: String
    let branch: String
    let imageDirectory: String
    let linkRule: ImageCDNRule.RuleIdentifier
}

private struct GitHubCreateOrUpdateRequest: Encodable {
    let message: String
    let content: String
    let branch: String
    let sha: String?
}
