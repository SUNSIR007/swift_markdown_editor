import SwiftUI

struct ImageUploadSheet: View {
    @ObservedObject var viewModel: ImageUploadViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            progressView
            resultList
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") { onDismiss() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("图片上传")
                .font(.title2)
                .bold()
            Text("选择图片后会自动上传到配置的 GitHub 图床仓库并返回 CDN 链接")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var progressView: some View {
        Group {
            switch viewModel.uploadProgress.state {
            case .idle:
                Text("等待选择图片")
                    .foregroundColor(.secondary)
            case .preparing:
                ProgressView("准备上传...")
            case .processing(let message):
                ProgressView(message)
            case .uploading(let value):
                ProgressView(value: value)
            case .success(let url):
                VStack(alignment: .leading, spacing: 8) {
                    Label("上传成功", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    if let url {
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            case .failure(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }

    private var resultList: some View {
        Group {
            if viewModel.uploadedResults.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("已上传")
                        .font(.headline)
                    ForEach(viewModel.uploadedResults, id: \.fileName) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.fileName)
                                .font(.subheadline)
                            if let url = result.cdnURL {
                                Text(url.absoluteString)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}
