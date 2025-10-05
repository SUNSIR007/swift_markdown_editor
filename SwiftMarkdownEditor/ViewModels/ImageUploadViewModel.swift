import Foundation
import PhotosUI

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

    func upload(items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isUploading = true
        uploadProgress = UploadProgress(state: .preparing, currentFileName: "")
        uploadedResults.removeAll()
        errorMessage = nil

        Task {
            do {
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    let identifier = item.itemIdentifier ?? UUID().uuidString
                    let utType = item.supportedContentTypes.first ?? .jpeg
                    let asset = ImageUploadAsset(fileName: identifier, data: data, utType: utType)
                    uploadProgress = UploadProgress(state: .processing("上传 \(identifier)"), currentFileName: identifier)
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
