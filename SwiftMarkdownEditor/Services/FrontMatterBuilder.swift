import Foundation

/// 将元数据和正文组合为 Markdown frontmatter 的工具。
struct FrontMatterBuilder {
    func compose(contentType: ContentType, metadata: MetadataStore, body: String) -> String {
        guard contentType != .general else {
            return body
        }

        let frontmatter = metadata
            .asDictionary()
            .compactMap { key, value -> String? in
                switch value {
                case .string(let string):
                    guard !string.isEmpty else { return nil }
                    let escaped = string.contains(":") ? "\"\(string)\"" : string
                    return "\(key): \(escaped)"
                case .stringArray(let array):
                    let cleaned = array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    guard !cleaned.isEmpty else { return nil }
                    let serialized = cleaned.map { "\"\($0)\"" }.joined(separator: ", ")
                    return "\(key): [\(serialized)]"
                case .date(let date):
                    let formatted = DateFormatter.iso8601DateOnly.string(from: date)
                    return "\(key): \(formatted)"
                case .bool(let flag):
                    return "\(key): \(flag ? "true" : "false")"
                case .number(let number):
                    return "\(key): \(number)"
                }
            }
            .joined(separator: "\n")

        guard !frontmatter.isEmpty else {
            return body
        }

        return "---\n\(frontmatter)\n---\n\n\(body)"
    }
}

