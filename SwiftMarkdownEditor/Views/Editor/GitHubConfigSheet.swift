import SwiftUI

struct GitHubConfigSheet: View {
    @ObservedObject var viewModel: GitHubConfigViewModel

    var body: some View {
        Form {
            Section(header: Text("GitHub 仓库")) {
                SecureField("Token", text: Binding(
                    get: { viewModel.githubConfig.token },
                    set: { viewModel.githubConfig.token = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Owner", text: Binding(
                    get: { viewModel.githubConfig.owner },
                    set: { viewModel.githubConfig.owner = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Repo", text: Binding(
                    get: { viewModel.githubConfig.repo },
                    set: { viewModel.githubConfig.repo = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Branch", text: Binding(
                    get: { viewModel.githubConfig.branch },
                    set: { viewModel.githubConfig.branch = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }

            Section(header: Text("图床仓库")) {
                SecureField("Token", text: Binding(
                    get: { viewModel.imageConfig.token },
                    set: { viewModel.imageConfig.token = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Owner", text: Binding(
                    get: { viewModel.imageConfig.owner },
                    set: { viewModel.imageConfig.owner = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Repo", text: Binding(
                    get: { viewModel.imageConfig.repo },
                    set: { viewModel.imageConfig.repo = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("Branch", text: Binding(
                    get: { viewModel.imageConfig.branch },
                    set: { viewModel.imageConfig.branch = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField("图片目录", text: Binding(
                    get: { viewModel.imageConfig.imageDirectory },
                    set: { viewModel.imageConfig.imageDirectory = $0 }
                ))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                Picker("CDN", selection: $viewModel.linkRule) {
                    ForEach(ImageCDNRule.RuleIdentifier.allCases, id: \.self) { rule in
                        Text(ImageCDNRule.rule(for: rule).name).tag(rule)
                    }
                }
            }

            if let status = viewModel.statusMessage {
                Section {
                    Label(status, systemImage: "checkmark.seal")
                        .foregroundColor(.green)
                }
            }
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("配置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("测试连接") { viewModel.testGitHubConnection() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") { viewModel.save() }
            }
        }
    }
}
