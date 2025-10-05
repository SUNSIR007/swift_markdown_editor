import SwiftUI
import PhotosUI

struct ContentView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @ObservedObject var configViewModel: GitHubConfigViewModel
    @ObservedObject var imageUploadViewModel: ImageUploadViewModel

    @State private var showingConfigSheet = false
    @State private var showingImageSheet = false
    @State private var selectedPhotosItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            EditorScreen(viewModel: editorViewModel,
                         showConfig: { showingConfigSheet = true },
                         showImageUpload: { showingImageSheet = true })
                .navigationTitle("Markdown Editor")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showingConfigSheet = true
                        } label: {
                            Label("配置", systemImage: "gearshape")
                        }

                        PhotosPicker(selection: $selectedPhotosItems, matching: .images) {
                            Label("图片", systemImage: "photo.on.rectangle")
                        }
                    }
                }
                .onChange(of: selectedPhotosItems) { newItems in
                    guard !newItems.isEmpty else { return }
                    showingImageSheet = true
                    imageUploadViewModel.upload(items: newItems)
                }
        }
        .sheet(isPresented: $showingConfigSheet) {
            NavigationStack {
                GitHubConfigSheet(viewModel: configViewModel)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingImageSheet, onDismiss: { selectedPhotosItems = [] }) {
            NavigationStack {
                ImageUploadSheet(viewModel: imageUploadViewModel,
                                 onDismiss: { showingImageSheet = false })
            }
            .presentationDetents([.medium, .large])
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
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}
