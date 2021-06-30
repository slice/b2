import Foundation

struct OuroborosPostResponse {
  var imageURL: URL?
  var thumbnailImageURL: URL?
  var id: Int
  var createdAt: Date
  var size: Int
  var tags: [String: [String]]
  var ext: String
  var md5: String

  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case tags

    // File information substructure.
    case file

    // Preview thumbnail substructure.
    case preview
  }

  enum FileKeys: String, CodingKey {
    case ext
    case size
    case md5
    case url
  }

  enum PreviewKeys: String, CodingKey {
    case url
  }
}

extension OuroborosPostResponse: Decodable {
  init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: CodingKeys.self)

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    self.id = try root.decode(Int.self, forKey: .id)
    let createdAtStringDate = try root.decode(String.self, forKey: .createdAt)
    guard let createdAtDate = dateFormatter.date(from: createdAtStringDate) else {
      fatalError("ouroboros post response has invalid date: \(createdAtStringDate)")
    }
    self.createdAt = createdAtDate

    let file = try root.nestedContainer(keyedBy: FileKeys.self, forKey: .file)
    self.ext = try file.decode(String.self, forKey: .ext)
    self.size = try file.decode(Int.self, forKey: .size)
    self.md5 = try file.decode(String.self, forKey: .md5)
    self.imageURL = try file.decodeIfPresent(URL.self, forKey: .url)

    let preview = try root.nestedContainer(keyedBy: PreviewKeys.self, forKey: .preview)
    self.thumbnailImageURL = try preview.decodeIfPresent(URL.self, forKey: .url)

    self.tags = try root.decode([String: [String]].self, forKey: .tags)
  }
}
