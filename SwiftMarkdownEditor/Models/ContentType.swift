import Foundation

/// 可发布内容的类型定义，对应原网页应用的 contentTypes 配置。
enum ContentType: String, CaseIterable, Identifiable {
    case general
    case blog
    case essay
    case gallery

    var id: String { rawValue }

    /// UI 显示名称
    var displayName: String {
        switch self {
        case .general: return "General"
        case .blog: return "Blogs"
        case .essay: return "Essays"
        case .gallery: return "Gallery"
        }
    }

    /// 元数据表单配置
    var metadataSchema: [MetadataField] {
        switch self {
        case .general:
            return []
        case .blog:
            return [
                MetadataField(key: "title", label: "标题", kind: .text, placeholder: "请输入文章标题", isRequired: true),
                MetadataField(key: "categories", label: "分类", kind: .tags, placeholder: "以逗号分隔，示例：Daily, Life"),
                MetadataField(key: "pubDate", label: "发布日期", kind: .date)
            ]
        case .essay:
            return [
                MetadataField(key: "pubDate", label: "发布日期", kind: .date)
            ]
        case .gallery:
            return []
        }
    }

    /// 针对内容类型的默认元数据
    func defaultMetadata() -> MetadataStore {
        var store = MetadataStore()
        switch self {
        case .blog:
            store.set(.string(""), forKey: "title")
            store.set(.stringArray(["Daily"]), forKey: "categories")
            store.set(.date(Date()), forKey: "pubDate")
        case .essay:
            store.set(.date(Date()), forKey: "pubDate")
        case .gallery:
            break
        case .general:
            break
        }
        return store
    }
}
