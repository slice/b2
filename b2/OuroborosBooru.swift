import Foundation

private struct OuroborosPostsResponse: Decodable {
    var posts: [OuroborosFile]
}

enum OuroborosBooruError: Error {
    case noData
}

class OuroborosBooru: Booru {
    let baseUrl: URL

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    static func addStandardHeaders(request: inout URLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("b2/0.0", forHTTPHeaderField: "User-Agent")
    }

    func search(forTags tags: [String], completionHandler: @escaping (Result<[BooruFile], Error>) -> Void) {
        var components = URLComponents(url: self.baseUrl, resolvingAgainstBaseURL: true)!

        var queries = [
            URLQueryItem(name: "limit", value: "100")
        ]

        if !tags.isEmpty {
            queries.append(
                URLQueryItem(name: "tags", value: tags.joined(separator: " "))
            )
        }

        components.queryItems = queries
        let url = components.url!.appendingPathComponent("posts.json")

        var request = URLRequest(url: url)
        Self.addStandardHeaders(request: &request)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let data = data else {
                completionHandler(.failure(OuroborosBooruError.noData))
                return
            }

            do {
                let response = try JSONDecoder().decode(OuroborosPostsResponse.self, from: data)
                completionHandler(.success(response.posts))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
