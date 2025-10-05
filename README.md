# Swift Markdown Editor

原本的 `markdown-online-editor` Web 版已被迁移为完全原生的 SwiftUI iOS 应用。此工程位于 `SwiftMarkdownEditor.xcodeproj`，目标设备为 iPhone / iPad（iOS 16+）。项目重点功能如下：

- Markdown 正文编辑与前置 Frontmatter 生成：支持 Blog / Essay / Gallery / General 四种类型，并按照原 JS 规则生成文件路径与 frontmatter。
- GitHub 访问：通过 `GitHubService` actor 調用 REST API，实现内容创建、更新与连接测试，敏感 Token 存储于 Keychain。
- 图床上传：`ImageUploadService` 支持多张图片上传到独立仓库，并根据配置生成 CDN 链接（GitHub / jsDelivr / Statically / jsd.cdn）。
- 图片选择：使用 `PhotosPicker` 选取系统相册中的资源，可选压缩并展示上传状态与结果链接。
- 配置面板：原 Vue 的 GitHub & 图床面板改写为 `GitHubConfigSheet`，可持久化配置并即时测试连接。

## 打开与运行

1. 使用 Xcode 15（或更新版本）打开 `SwiftMarkdownEditor.xcodeproj`。
2. 目标平台设为 iOS 16 及以上，直接在模拟器或真机运行。
3. 首次运行后，先在右上角的齿轮按钮中配置 GitHub 与图床仓库信息。
   - Token 会保存到 Keychain。
   - Owner / Repo / Branch 会保存到 `UserDefaults`。
4. 返回主界面后即可编写正文、切换内容类型、生成 Frontmatter 并推送至 GitHub。

## 目录结构

```
SwiftMarkdownEditor/
├─ Models/                # 内容类型、元数据、GitHub 配置、上传实体
├─ Services/              # GitHubService、ImageUploadService、路径与Frontmatter工具
├─ ViewModels/            # Editor、配置、图片上传三大 VM（MainActor）
├─ Views/                 # SwiftUI 视图层（含编辑器、配置面板、上传弹窗）
├─ Utilities/             # Keychain 封装、Markdown 渲染、日期格式化
└─ Resources/             # Info.plist、Assets.xcassets、PreviewAssets
```

## 手动测试建议

- **内容发布**：选择不同类型（Blog / Essay），验证自动填充的元数据、前置 Frontmatter 与 GitHub 提交结果；发布成功后留意成功提示链接。
- **配置面板**：在配置页输入 GitHub Token / Owner / Repo 后，使用“测试连接”确认权限；切换 CDN 选项时应即时生效。
- **图片上传**：通过导航栏的相册按钮选择多张图片，观察压缩与上传进度，核对生成的最终 CDN URL。
- **Essay 路径生成**：在正文开头输入中文 / 英文字母，确认生成路径前缀与 Web 版一致（取前四个字符）。
- **Keychain 清除**：若需重置配置，可在设置页输入空 Token 并保存，或修改 `SecureStore` 调用以清理。

## 未来拓展

- 增加离线缓存与草稿恢复逻辑。
- 引入单元测试覆盖 GitHub 与图片上传服务。
- 支持更多 frontmatter 字段（如 tags、slug 自定义）及多仓库选择。
- 结合 App Intents / Share Extension，实现系统级分享入口。

欢迎继续在此项目上扩展，如需自动化构建可引入 `fastlane` 或 GitHub Actions（需额外配置代码签名）。
