import Foundation
@MainActor
final class ImageUploadViewModel: ObservableObject {
    @Published var uploadProgress: UploadProgress = .idle
    @Published var uploadedResults: [ImageUploadResult] = []
    @Published var errorMessage: String?
    @Published var isUploading: Bool = false

    private let imageService: ImageUploadService

    init(imageService: ImageUploadService = ImageUploadService()) {
        self.imageService = imageService
    }

    func upload(assets: [ImageUploadAsset]) {
        guard !assets.isEmpty else { return }
        isUploading = true
        uploadProgress = UploadProgress(state: .preparing, currentFileName: "")
        uploadedResults.removeAll()
        errorMessage = nil

        Task {
            do {
                for asset in assets {
                    uploadProgress = UploadProgress(state: .processing("上传 \(asset.fileName)"), currentFileName: asset.fileName)
                    let result = try await imageService.upload(asset)
                    uploadedResults.append(result)
                }
                uploadProgress = UploadProgress(state: .success(uploadedResults.last?.cdnURL), currentFileName: uploadedResults.last?.fileName ?? "")
            } catch {
                errorMessage = error.localizedDescription
                uploadProgress = UploadProgress(state: .failure(error.localizedDescription), currentFileName: "")
            }
            isUploading = false
        }
    }
}
