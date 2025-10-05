import Foundation

/// 根据内容类型生成目标仓库中的文件路径。
struct ContentPathBuilder {
    func generatePath(for contentType: ContentType, metadata: MetadataStore, body: String) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)

        let year = components.year ?? 1970
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        let hour = String(format: "%02d", components.hour ?? 0)
        let minute = String(format: "%02d", components.minute ?? 0)
        let second = String(format: "%02d", components.second ?? 0)

        let datePrefix = "\(year)-\(month)-\(day)"
        let timestamp = "\(hour)\(minute)\(second)"

        switch contentType {
        case .blog:
            let title = metadata.string(forKey: "title") ?? "untitled"
            let safeTitle = Self.normalizedSlug(title)
            let fileName = safeTitle.isEmpty ? "untitled-\(timestamp)" : "\(safeTitle)-\(timestamp)"
            return "src/content/posts/\(fileName).md"
        case .essay:
            let plainText = body
                .removingFrontMatter()
                .removingMarkdownArtifacts()
            let snippet = plainText.prefixValidCharacters(limit: 4)
            let prefix = snippet.isEmpty ? datePrefix : "\(datePrefix)-\(snippet)"
            return "src/content/essays/\(prefix)-\(timestamp).md"
        case .gallery:
            let title = metadata.string(forKey: "title") ?? "gallery"
            let safeTitle = Self.normalizedSlug(title)
            return "docs/\(datePrefix)-\(safeTitle)-\(timestamp).md"
        case .general:
            let title = metadata.string(forKey: "title") ?? "general"
            let safeTitle = Self.normalizedSlug(title)
            return "docs/\(datePrefix)-\(safeTitle)-\(timestamp).md"
        }
    }

    private static func normalizedSlug(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-"))
        let cleaned = input
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let filtered = cleaned.unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
        let condensed = String(filtered).replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        return condensed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

private extension String {
    func removingFrontMatter() -> String {
        guard let startRange = range(of: "---", options: [], range: startIndex..<endIndex),
              let trailingRange = range(of: "---", options: [], range: startRange.upperBound..<endIndex) else {
            return self
        }
        return String(self[trailingRange.upperBound...])
    }

    func removingMarkdownArtifacts() -> String {
        self
            .replacingOccurrences(of: "!\\[[^]]*\\]\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\[[^]]*\\]\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[#*`_~\\->/]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }

    func prefixValidCharacters(limit: Int) -> String {
        var result = ""
        var count = 0
        for scalar in unicodeScalars {
            if CharacterSet.letters.contains(scalar) || (0x4e00...0x9fff).contains(Int(scalar.value)) {
                result.unicodeScalars.append(scalar)
                count += 1
            }
            if count >= limit { break }
        }
        return result
    }
}
