import Foundation

class OuroborosBooru: Booru {
    let baseUrl: URL

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    static func addStandardHeaders(request: inout URLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("b2/0.0", forHTTPHeaderField: "User-Agent")
    }

    func initialFiles() throws -> [BooruFile] {
        var components = URLComponents(url: self.baseUrl, resolvingAgainstBaseURL: true)!
        components.appendQuery(name: "limit", value: "100")
        let url = components.url! / "post" / "index.json"

        var request = URLRequest(url: url)
        OuroborosBooru.addStandardHeaders(request: &request)

        let data = try? URLSession.shared.syncDataTask(with: request)
        return try JSONDecoder().decode([OuroborosFile].self, from: data!)
    }

    func search(forFilesWithTags tags: [String]) throws -> [BooruFile] {
        var components = URLComponents(url: self.baseUrl, resolvingAgainstBaseURL: true)!
        components.appendQuery(name: "limit", value: "100")
        components.appendQuery(name: "tags", value: tags.joined(separator: " "))
        let url = components.url! / "post" / "index.json"

        var request = URLRequest(url: url)
        OuroborosBooru.addStandardHeaders(request: &request)

        let data = try? URLSession.shared.syncDataTask(with: request)
        return try JSONDecoder().decode([OuroborosFile].self, from: data!)
    }
}

private extension URLComponents {
    mutating func appendQuery(name: String, value: String) {
        var queryItems = self.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        self.queryItems = queryItems
    }
}

private extension URL {
    static func / (left: URL, right: String) -> URL {
        return left.appendingPathComponent(right)
    }
}

private extension URLSession {
    func syncDataTask(with url: URLRequest) throws -> Data? {
        let semaphore = DispatchSemaphore(value: 0)

        var result: Data?
        var resultingError: Error?

        let task = self.dataTask(with: url) { (data, _, error) in
            if error != nil {
                resultingError = error
            } else if let data = data {
                result = data
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        if let error = resultingError {
            throw error
        }

        return result
    }
}
