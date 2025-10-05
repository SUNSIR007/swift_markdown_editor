import Foundation

/// 上传进度与状态反馈信息
struct UploadProgress: Equatable {
    enum State: Equatable {
        case idle
        case preparing
        case uploading(Double)
        case processing(String)
        case success(URL?)
        case failure(String)
    }

    var state: State = .idle
    var currentFileName: String = ""
    var summary: String = ""
    var messages: [String] = []

    init(state: State = .idle, currentFileName: String = "", summary: String = "", messages: [String] = []) {
        self.state = state
        self.currentFileName = currentFileName
        self.summary = summary
        self.messages = messages
    }

    static let idle = UploadProgress()
}
