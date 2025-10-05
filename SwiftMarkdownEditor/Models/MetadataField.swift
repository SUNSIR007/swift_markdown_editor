import Foundation

/// 元数据字段的输入类型
enum MetadataFieldKind: Equatable {
    case text
    case multiline
    case tags
    case date
    case toggle
    case number
}

/// 描述元数据字段的结构信息，用于动态渲染表单。
struct MetadataField: Identifiable, Hashable {
    let id: String
    let key: String
    let label: String
    let kind: MetadataFieldKind
    let placeholder: String?
    let isRequired: Bool

    init(key: String, label: String, kind: MetadataFieldKind, placeholder: String? = nil, isRequired: Bool = false) {
        self.id = key
        self.key = key
        self.label = label
        self.kind = kind
        self.placeholder = placeholder
        self.isRequired = isRequired
    }
}
