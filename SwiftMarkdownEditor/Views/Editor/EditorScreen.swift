import SwiftUI

struct EditorScreen: View {
    @ObservedObject var viewModel: EditorViewModel
    let showConfig: () -> Void
    let showImageUpload: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                metadataSection
                editorSection
                previewSection
                actionSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            picker
            statusRow
        }
    }

    private var picker: some View {
        Picker("内容类型", selection: Binding(get: { viewModel.selectedType }, set: { viewModel.selectedType = $0 })) {
            ForEach(ContentType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            StatusBadge(isActive: viewModel.isGitHubConfigured, label: "GitHub") {
                showConfig()
            }
            StatusBadge(isActive: viewModel.isImageServiceConfigured, label: "图床") {
                showImageUpload()
            }
            Spacer()
        }
    }

    private var metadataSection: some View {
        Group {
            if !viewModel.selectedType.metadataSchema.isEmpty {
                MetadataFormView(viewModel: viewModel)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(12)
            }
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("正文")
                .font(.headline)
            TextEditor(text: Binding(
                get: { viewModel.bodyContent },
                set: { viewModel.updateBodyContent($0) }
            ))
            .frame(minHeight: 240)
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(12)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预览")
                .font(.headline)
            ScrollView {
                Text(viewModel.renderedPreview)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(minHeight: 200)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(12)
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if case .failure(let message) = viewModel.uploadProgress.state {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
            if case .success(let url) = viewModel.uploadProgress.state {
                VStack(spacing: 4) {
                    Label("发布成功", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    if let url {
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Button {
                viewModel.publish()
            } label: {
                Label("发布", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isGitHubConfigured)
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(12)
    }
}

private struct StatusBadge: View {
    let isActive: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isActive ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(20)
        }
    }
}
