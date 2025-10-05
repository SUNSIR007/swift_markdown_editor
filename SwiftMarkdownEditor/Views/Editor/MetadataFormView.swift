import SwiftUI

struct MetadataFormView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.selectedType.metadataSchema) { field in
                VStack(alignment: .leading, spacing: 6) {
                    Text(field.label)
                        .font(.subheadline)
                    fieldView(for: field)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldView(for field: MetadataField) -> some View {
        switch field.kind {
        case .text:
            TextField(field.placeholder ?? "", text: Binding(
                get: { viewModel.metadata.string(forKey: field.key) ?? "" },
                set: { viewModel.updateMetadata(key: field.key, value: .string($0)) }
            ))
            .textFieldStyle(.roundedBorder)
        case .multiline:
            TextEditor(text: Binding(
                get: { viewModel.metadata.string(forKey: field.key) ?? "" },
                set: { viewModel.updateMetadata(key: field.key, value: .string($0)) }
            ))
            .frame(height: 120)
            .padding(6)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(8)
        case .tags:
            TextField(field.placeholder ?? "", text: Binding(
                get: { viewModel.metadata.string(forKey: field.key) ?? "" },
                set: {
                    let tags = $0
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    viewModel.updateMetadata(key: field.key, value: .stringArray(tags))
                }
            ))
            .textFieldStyle(.roundedBorder)
        case .date:
            DatePicker("", selection: Binding(
                get: { viewModel.metadata.date(forKey: field.key) ?? Date() },
                set: { viewModel.updateMetadata(key: field.key, value: .date($0)) }
            ), displayedComponents: .date)
            .datePickerStyle(.graphical)
        case .toggle:
            Toggle(isOn: Binding(
                get: { viewModel.metadata.bool(forKey: field.key) ?? false },
                set: { viewModel.updateMetadata(key: field.key, value: .bool($0)) }
            )) {
                EmptyView()
            }
            .labelsHidden()
        case .number:
            TextField(field.placeholder ?? "", value: Binding(
                get: { viewModel.metadata.number(forKey: field.key) ?? 0 },
                set: { viewModel.updateMetadata(key: field.key, value: .number($0)) }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
        }
    }
}
