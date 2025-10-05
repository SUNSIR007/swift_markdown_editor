import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var selectedType: ContentType = .essay {
        didSet { resetMetadata() }
    }
    @Published var metadata: MetadataStore
    @Published var bodyContent: String = ""
    @Published var renderedPreview: AttributedString = .init("")
    @Published var uploadProgress: UploadProgress = .idle
    @Published var isGitHubConfigured: Bool = false
    @Published var isImageServiceConfigured: Bool = false
    @Published var lastErrorMessage: String?

    private let githubService: GitHubService
    private let imageService: ImageUploadService
    private let renderer = MarkdownRenderer()
    private let frontMatterBuilder = FrontMatterBuilder()

    init(githubService: GitHubService = GitHubService(), imageService: ImageUploadService = ImageUploadService()) {
        self.githubService = githubService
        self.imageService = imageService
        self.metadata = ContentType.essay.defaultMetadata()
        Task {
            await refreshConfigurationStates()
        }
        renderPreview()
    }

    func refreshConfigurationStates() async {
        isGitHubConfigured = (try? await githubService.isConfigured()) ?? false
        isImageServiceConfigured = (try? await imageService.isConfigured()) ?? false
    }

    func resetMetadata() {
        metadata = selectedType.defaultMetadata()
        renderPreview()
    }

    func updateMetadata(key: String, value: MetadataValue?) {
        metadata.set(value, forKey: key)
        renderPreview()
    }

    func updateBodyContent(_ text: String) {
        bodyContent = text
        renderPreview()
    }

    func renderPreview() {
        let combined = frontMatterBuilder.compose(contentType: selectedType, metadata: metadata, body: bodyContent)
        renderedPreview = renderer.render(combined)
    }

    func publish(commitMessage: String? = nil) {
        Task {
            guard (try? await githubService.isConfigured()) == true else {
                lastErrorMessage = "请先配置 GitHub 信息"
                return
            }

            guard !bodyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                lastErrorMessage = "正文内容不能为空"
                return
            }

            if selectedType == .blog {
                let title = metadata.string(forKey: "title") ?? ""
                guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    lastErrorMessage = "博客需要填写标题"
                    return
                }
            }

            uploadProgress = UploadProgress(state: .preparing, currentFileName: "")
            do {
                let result = try await githubService.publish(
                    contentType: selectedType,
                    metadata: metadata,
                    body: bodyContent,
                    commitMessage: commitMessage
                )
                uploadProgress = UploadProgress(state: .success(result.url), currentFileName: result.commitSha ?? "")
                bodyContent = ""
                resetMetadata()
            } catch {
                uploadProgress = UploadProgress(state: .failure(error.localizedDescription), currentFileName: "")
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    func parseFrontMatter(from markdown: String) {
        let parser = FrontMatterParser()
        let parsed = parser.parse(markdown: markdown)
        selectedType = parsed.inferredType ?? selectedType
        metadata = parsed.metadata
        bodyContent = parsed.content
        renderPreview()
    }
}

/// 将 Markdown frontmatter 解析为 MetadataStore，便于编辑现有文件。
struct FrontMatterParser {
    func parse(markdown: String) -> (metadata: MetadataStore, content: String, inferredType: ContentType?) {
        var storage = MetadataStore()
        guard markdown.hasPrefix("---\n") else {
            return (storage, markdown, nil)
        }
        let components = markdown.components(separatedBy: "\n---\n")
        guard components.count >= 2 else {
            return (storage, markdown, nil)
        }
        let yamlPart = components[0].replacingOccurrences(of: "---\n", with: "")
        let body = components.dropFirst().joined(separator: "\n---\n")

        yamlPart.split(separator: "\n").forEach { line in
            guard let separatorIndex = line.firstIndex(of: ":") else { return }
            let key = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)

            if value.hasPrefix("[") && value.hasSuffix("]") {
                let trimmed = value.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                let items = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                storage.set(.stringArray(items), forKey: key)
            } else if let date = DateFormatter.iso8601DateOnly.date(from: value) {
                storage.set(.date(date), forKey: key)
            } else if ["true", "false"].contains(value.lowercased()) {
                storage.set(.bool(value.lowercased() == "true"), forKey: key)
            } else if let number = Double(value) {
                storage.set(.number(number), forKey: key)
            } else {
                storage.set(.string(value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))), forKey: key)
            }
        }

        let inferredType: ContentType? = {
            if storage.value(forKey: "categories") != nil { return .blog }
            if storage.value(forKey: "pubDate") != nil { return .essay }
            return nil
        }()

        return (storage, body, inferredType)
    }
}

