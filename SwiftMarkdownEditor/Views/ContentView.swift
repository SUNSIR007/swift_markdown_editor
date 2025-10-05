import SwiftUI

struct ContentView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @ObservedObject var configViewModel: GitHubConfigViewModel
    @ObservedObject var imageUploadViewModel: ImageUploadViewModel

    @State private var showingConfigSheet = false
    @State private var showingImageSheet = false
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            EditorScreen(viewModel: editorViewModel,
                         showConfig: { showingConfigSheet = true },
                         showImageUpload: { showingImageSheet = true })
                .navigationTitle("Markdown Editor")
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) { configButton }
                    ToolbarItem(placement: .navigationBarTrailing) { photoButton }
#else
                    ToolbarItem { configButton }
                    ToolbarItem { photoButton }
#endif
                }
        }
        .sheet(isPresented: $showingConfigSheet) {
            NavigationStack {
                GitHubConfigSheet(viewModel: configViewModel)
            }
#if os(iOS)
            .presentationDetents([.medium, .large])
#endif
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerSheet { assets in
                showingPhotoPicker = false
                guard !assets.isEmpty else { return }
                showingImageSheet = true
                imageUploadViewModel.upload(assets: assets)
            }
        }
        .sheet(isPresented: $showingImageSheet, onDismiss: {
            showingImageSheet = false
        }) {
            NavigationStack {
                ImageUploadSheet(viewModel: imageUploadViewModel,
                                 onDismiss: { showingImageSheet = false })
            }
#if os(iOS)
            .presentationDetents([.medium, .large])
#endif
        }
        .alert(item: Binding(get: {
            if let error = editorViewModel.lastErrorMessage {
                return AlertMessage(message: error)
            }
            if let error = configViewModel.errorMessage {
                return AlertMessage(message: error)
            }
            if let error = imageUploadViewModel.errorMessage {
                return AlertMessage(message: error)
            }
            return nil
        }, set: { _ in
            editorViewModel.lastErrorMessage = nil
            configViewModel.errorMessage = nil
            imageUploadViewModel.errorMessage = nil
        })) { payload in
            Alert(title: Text("错误"), message: Text(payload.message), dismissButton: .default(Text("好")))
        }
    }

    private var configButton: some View {
        Button {
            showingConfigSheet = true
        } label: {
            Label("配置", systemImage: "gearshape")
        }
    }

    private var photoButton: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            Label("图片", systemImage: "photo.on.rectangle")
        }
    }
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}
