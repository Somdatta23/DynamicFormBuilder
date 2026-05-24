//
//  JSONLoader.swift
//  DynamicFormBuilder
//
//  Loads and decodes JSON files from the app bundle.
//
//  Design decisions:
//  - Generic: Works with any Decodable type, not just FormSchema
//  - Result type: Makes error handling explicit at the call site
//  - Injectable bundle: Defaults to .main but can be overridden for unit tests
//  - .convertFromSnakeCase: Eliminates the need for CodingKeys on every model
//    (e.g., "max_length" in JSON → maxLength in Swift — automatic)
//

import Foundation

/// A stateless utility for loading JSON from the app bundle.
///
/// Usage:
/// ```swift
/// let result = JSONLoader.load(FormSchema.self, from: "form_schema")
/// switch result {
/// case .success(let schema): // use schema
/// case .failure(let error):  // handle error
/// }
/// ```
enum JSONLoader {

    // MARK: - Error Types

    enum LoadError: LocalizedError {
        case fileNotFound(String)
        case dataReadFailed(String)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Could not find '\(name).json' in the app bundle."
            case .dataReadFailed(let name):
                return "Could not read data from '\(name).json'."
            case .decodingFailed(let error):
                return "Failed to decode JSON: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Loading

    /// Loads and decodes a JSON file from the specified bundle.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode into.
    ///   - filename: The filename without extension (e.g., "form_schema").
    ///   - bundle: The bundle to search in. Defaults to `.main`.
    ///             Override this in unit tests to load from a test bundle.
    /// - Returns: A `Result` containing the decoded value or a `LoadError`.
    static func load<T: Decodable>(
        _ type: T.Type,
        from filename: String,
        in bundle: Bundle = .main
    ) -> Result<T, LoadError> {

        // 1. Find the file in the bundle
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            return .failure(.fileNotFound(filename))
        }

        // 2. Read raw data
        guard let data = try? Data(contentsOf: url) else {
            return .failure(.dataReadFailed(filename))
        }

        // 3. Configure decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // 4. Decode
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }
}
