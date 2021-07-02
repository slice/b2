import Combine
import Foundation

enum ConstellationError: Error {
  case tagEncodingFailure
  case invalidBaseURL
}

struct ConstellationBooruSearchFilesResponse: Decodable {
  let fileIDs: [Int]

  enum CodingKeys: String, CodingKey {
    case fileIDs = "file_ids"
  }
}

struct ConstellationBooruMetadataResponse: Decodable {
  let metadata: [Entry]

  struct Entry: Decodable {
    let fileID: Int
    let hash: String
    let size: Int
    let mime: String
    let ext: String
    let width: Int
    let height: Int
    let hasAudio: Bool
    let isInbox: Bool
    let isLocal: Bool
    let isTrashed: Bool
    let serviceNamesToStatusesToDisplayTags: [String: [String: [String]]]

    enum CodingKeys: String, CodingKey {
      case fileID = "file_id"
      case hash
      case size
      case mime
      case ext
      case width
      case height
      case hasAudio = "has_audio"
      case isInbox = "is_inbox"
      case isLocal = "is_local"
      case isTrashed = "is_trashed"
      case serviceNamesToStatusesToDisplayTags = "service_names_to_statuses_to_display_tags"
    }
  }
}

class ConstellationBooru: Booru {
  static let apiAccessKeyHeader: String = "Hydrus-Client-API-Access-Key"

  var id = UUID()
  var name: String = "Hydrus (Client API)"
  var supportedPaginationTypes: [BooruPaginationType] = [.none]

  var baseURL: URL
  var accessKey: String

  var sinks: Set<AnyCancellable> = Set()

  init(baseURL: URL, accessKey: String) {
    self.baseURL = baseURL
    self.accessKey = accessKey
  }

  private func temporaryFlag(named name: String, default: Bool) -> String {
    let key = "constellation\(name)"
    guard let flag = UserDefaults.standard.object(forKey: key) as? Bool else {
      return String(`default`.description)
    }

    return flag.description
  }

  func search(
    forTags tags: [String], offsetBy _: BooruQueryOffset,
    completionHandler: @escaping (Result<[BooruPost], Error>) -> Void
  ) {
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    // Convert underscores to spaces, because spaces separate tags within the
    // search field, and Hydrus tags predominantly use spaces.
    //
    // TODO: Fix this by using tokens instead.
    let transformedTags = tags.map { $0.replacingOccurrences(of: "_", with: " ") }

    guard let encodedTags = try? jsonEncoder.encode(transformedTags),
          let encodedTagsString = String(data: encodedTags, encoding: .utf8)
    else {
      completionHandler(.failure(ConstellationError.tagEncodingFailure))
      return
    }

    guard
      let searchRequest = RequestBuilder(url: self.baseURL / "get_files" / "search_files")
      .header(name: Self.apiAccessKeyHeader, value: self.accessKey)
      .query(name: "tags", value: encodedTagsString)
      .query(
        name: "system_inbox",
        value: self.temporaryFlag(named: "SearchInInbox", default: false)
      )
      .query(
        name: "system_archive",
        value: self.temporaryFlag(named: "SearchInArchive", default: false)
      )
      .build()
    else {
      completionHandler(.failure(ConstellationError.invalidBaseURL))
      return
    }

    URLSession.shared.dataTaskPublisher(for: searchRequest)
      .map(\.data)
      .decode(type: ConstellationBooruSearchFilesResponse.self, decoder: jsonDecoder)
      .map(\.fileIDs)
      .encode(encoder: jsonEncoder)
      .flatMap { String(data: $0, encoding: .utf8).publisher }
      .flatMap {
        encodedFileIDs -> AnyPublisher<[ConstellationBooruMetadataResponse.Entry], Error> in
        guard
          let metadataRequest = RequestBuilder(url: self.baseURL / "get_files" / "file_metadata")
          .header(name: Self.apiAccessKeyHeader, value: self.accessKey)
          .query(name: "file_ids", value: encodedFileIDs)
          .build()
        else {
          return Fail(error: ConstellationError.invalidBaseURL).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: metadataRequest)
          .map(\.data)
          .decode(type: ConstellationBooruMetadataResponse.self, decoder: jsonDecoder)
          .map(\.metadata)
          .eraseToAnyPublisher()
      }
      .map { $0.map { ConstellationPost(metadata: $0, booru: self) } }
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            completionHandler(.failure(error))
          }
        }, receiveValue: { completionHandler(.success($0)) }
      )
      .store(in: &self.sinks)
  }
}
