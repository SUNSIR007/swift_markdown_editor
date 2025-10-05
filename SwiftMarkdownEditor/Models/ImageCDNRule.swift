import Foundation

/// 支持的 CDN 链接规则，参考原网页应用 image-service.js
struct ImageCDNRule: Equatable {
    enum RuleIdentifier: String, Codable, CaseIterable {
        case github
        case jsdelivr
        case statically
        case chinaJsdelivr
    }

    let id: RuleIdentifier
    let name: String
    let template: String
    let editable: Bool

    static let allRules: [RuleIdentifier: ImageCDNRule] = [
        .github: ImageCDNRule(id: .github, name: "GitHub", template: "https://github.com/{owner}/{repo}/raw/{branch}/{path}", editable: false),
        .jsdelivr: ImageCDNRule(id: .jsdelivr, name: "jsDelivr", template: "https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}/{path}", editable: false),
        .statically: ImageCDNRule(id: .statically, name: "Statically", template: "https://cdn.statically.io/gh/{owner}/{repo}/{branch}/{path}", editable: false),
        .chinaJsdelivr: ImageCDNRule(id: .chinaJsdelivr, name: "China jsDelivr", template: "https://jsd.cdn.zzko.cn/gh/{owner}/{repo}@{branch}/{path}", editable: false)
    ]

    static func rule(for identifier: RuleIdentifier) -> ImageCDNRule {
        allRules[identifier] ?? allRules[.jsdelivr]!
    }

    func formattedURL(owner: String, repo: String, branch: String, path: String) -> URL? {
        let replaced = template
            .replacingOccurrences(of: "{owner}", with: owner)
            .replacingOccurrences(of: "{repo}", with: repo)
            .replacingOccurrences(of: "{branch}", with: branch)
            .replacingOccurrences(of: "{path}", with: path)
        return URL(string: replaced)
    }
}
