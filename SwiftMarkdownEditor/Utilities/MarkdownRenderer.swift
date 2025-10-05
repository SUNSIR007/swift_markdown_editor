import Foundation
import SwiftUI

/// 将 Markdown 文本转换为可显示的 AttributedString。
struct MarkdownRenderer {
    func render(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(markdownLiteral: markdown)
        }
    }
}
