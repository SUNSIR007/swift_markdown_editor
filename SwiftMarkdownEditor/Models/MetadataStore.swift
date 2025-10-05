import Foundation

/// 统一存放前端需要的元数据值。
struct MetadataStore: Equatable {
    private var values: [String: MetadataValue] = [:]

    init(initialValues: [String: MetadataValue] = [:]) {
        self.values = initialValues
    }

    func value(forKey key: String) -> MetadataValue? {
        values[key]
    }

    mutating func set(_ value: MetadataValue?, forKey key: String) {
        guard let value else {
            values.removeValue(forKey: key)
            return
        }
        values[key] = value
    }

    mutating func merge(_ other: MetadataStore) {
        values.merge(other.values) { _, new in new }
    }

    mutating func reset() {
        values.removeAll(keepingCapacity: true)
    }

    func string(forKey key: String) -> String? {
        switch values[key] {
        case .string(let str):
            return str
        case .stringArray(let array):
            return array.joined(separator: ", ")
        default:
            return nil
        }
    }

    func stringArray(forKey key: String) -> [String] {
        switch values[key] {
        case .stringArray(let array):
            return array
        case .string(let string):
            return string
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        default:
            return []
        }
    }

    func date(forKey key: String) -> Date? {
        switch values[key] {
        case .date(let date):
            return date
        case .string(let isoString):
            return ISO8601DateFormatter().date(from: isoString)
        default:
            return nil
        }
    }

    func bool(forKey key: String) -> Bool? {
        switch values[key] {
        case .bool(let value):
            return value
        case .string(let string):
            return (string as NSString).boolValue
        default:
            return nil
        }
    }

    func number(forKey key: String) -> Double? {
        switch values[key] {
        case .number(let value):
            return value
        case .string(let string):
            return Double(string)
        default:
            return nil
        }
    }

    func asDictionary() -> [String: MetadataValue] {
        values
    }
}

/// 可序列化的元数据值类型。
enum MetadataValue: Equatable {
    case string(String)
    case stringArray([String])
    case date(Date)
    case bool(Bool)
    case number(Double)
}
