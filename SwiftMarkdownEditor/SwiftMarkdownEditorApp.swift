import SwiftUI

@main
struct SwiftMarkdownEditorApp: App {
    @StateObject private var editorViewModel: EditorViewModel
    @StateObject private var configViewModel: GitHubConfigViewModel
    @StateObject private var imageUploadViewModel: ImageUploadViewModel

    init() {
        let githubService = GitHubService()
        let imageService = ImageUploadService()
        _editorViewModel = StateObject(wrappedValue: EditorViewModel(githubService: githubService, imageService: imageService))
        _configViewModel = StateObject(wrappedValue: GitHubConfigViewModel(githubService: githubService, imageService: imageService))
        _imageUploadViewModel = StateObject(wrappedValue: ImageUploadViewModel(imageService: imageService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(editorViewModel: editorViewModel,
                        configViewModel: configViewModel,
                        imageUploadViewModel: imageUploadViewModel)
        }
    }
}
