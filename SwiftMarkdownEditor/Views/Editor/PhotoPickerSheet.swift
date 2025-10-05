#if canImport(UIKit)
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@available(iOS 14.0, *)
struct PhotoPickerSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController

    var selectionLimit: Int = 0
    var onComplete: ([ImageUploadAsset]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onComplete: ([ImageUploadAsset]) -> Void

        init(onComplete: @escaping ([ImageUploadAsset]) -> Void) {
            self.onComplete = onComplete
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                onComplete([])
                return
            }

            Task {
                var collected: [ImageUploadAsset] = []
                for result in results {
                    let identifiers = result.itemProvider.registeredTypeIdentifiers
                    guard let matchedType = identifiers.compactMap({ UTType($0) }).first(where: { $0.conforms(to: .image) }) else { continue }
                    let suggestedName = result.itemProvider.suggestedName ?? UUID().uuidString
                    do {
                        let data = try await PhotoPickerSheet.loadData(from: result.itemProvider, type: matchedType)
                        let sanitizedName = PhotoPickerSheet.sanitizedFilename(from: suggestedName, fallbackExtension: matchedType.preferredFilenameExtension ?? "jpg")
                        collected.append(ImageUploadAsset(fileName: sanitizedName, data: data, utType: matchedType))
                    } catch {
                        continue
                    }
                }

                await MainActor.run {
                    onComplete(collected)
                }
            }
        }
    }

    private static func sanitizedFilename(from name: String, fallbackExtension: String) -> String {
        let invalidCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
        let components = name.components(separatedBy: ".")
        let baseComponent = components.dropLast().joined(separator: ".")
        let extComponent = components.last ?? fallbackExtension
        let safeBase = baseComponent.isEmpty ? UUID().uuidString : baseComponent
        let filteredBase = safeBase.components(separatedBy: invalidCharacters).joined(separator: "-")
        let filteredExt = extComponent.components(separatedBy: invalidCharacters).joined()
        return "\(filteredBase).\(filteredExt.isEmpty ? fallbackExtension : filteredExt)"
    }

    private static func loadData(from provider: NSItemProvider, type: UTType) async throws -> Data {
        if #available(iOS 15.0, *) {
            return try await provider.loadDataRepresentation(forTypeIdentifier: type.identifier)
        }

        return try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "PhotoPickerSheet", code: -1, userInfo: nil))
                }
            }
        }
    }
}
#else
import SwiftUI

struct PhotoPickerSheet: View {
    var selectionLimit: Int = 0
    var onComplete: ([ImageUploadAsset]) -> Void

    var body: some View {
        Text("Photo picker 不支持当前平台")
            .padding()
            .onAppear { onComplete([]) }
    }
}
#endif
