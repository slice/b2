import Foundation

private struct OuroborosPostsResponse: Decodable {
  var posts: [OuroborosFile]
}

enum OuroborosBooruError: Error {
  case noData
}

/// The booru used by e621 and e926. It's actually just called "e621", but
/// "Ouroboros" is a cooler name.
class OuroborosBooru: Booru {
  let id = UUID()

  let name: String

  let supportedPaginationTypes: [BooruPaginationType] = [.pages, .relativeToLowestPreviousID]

  let baseUrl: URL

  init(named name: String, baseUrl: URL) {
    self.name = name
    self.baseUrl = baseUrl
  }

  static func addStandardHeaders(request: inout URLRequest) {
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("b2/0.0", forHTTPHeaderField: "User-Agent")
  }

  func search(
    forTags tags: [String], offsetBy offset: BooruQueryOffset,
    completionHandler: @escaping (Result<[BooruPost], Error>) -> Void
  ) {
    var components = URLComponents(url: self.baseUrl, resolvingAgainstBaseURL: true)!

    var queries = [
      // TODO: make this configurable?
      URLQueryItem(name: "limit", value: "100")
    ]

    if !tags.isEmpty {
      queries.append(
        URLQueryItem(name: "tags", value: tags.joined(separator: " "))
      )
    }

    if case .pageNumber(let pageNumber) = offset {
      queries.append(URLQueryItem(name: "page", value: String(pageNumber)))
    } else if case .previousChunk(let posts) = offset {
      let lowestPost = posts.min { a, b in a.id < b.id }
      guard let lowestPost = lowestPost else {
        fatalError("empty array passed as previousChunk")
      }
      queries.append(URLQueryItem(name: "page", value: "b\(lowestPost.id)"))
    }

    components.queryItems = queries
    let url = components.url!.appendingPathComponent("posts.json")

    var request = URLRequest(url: url)
    Self.addStandardHeaders(request: &request)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
        // *sigh*
        let posts = response.posts.map { post -> OuroborosFile in
          var newPost = post
          newPost.globalID = self.formGlobalID(withBooruID: post.id)
          return newPost
        }
        completionHandler(.success(posts))
      } catch {
        completionHandler(.failure(error))
      }
    }

    task.resume()
  }
}
