import Foundation

struct OuroborosFile: BooruPost {
  var globalID: String = ""
  var imageURL: URL
  var thumbnailImageURL: URL
  var id: Int
  var createdAt: Date
  var size: Int
  var tags: [BooruTag]
  var mime: BooruMime

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

private func extractHashChunks(_ hash: String) -> (Substring, Substring) {
  let chunk1 = hash[hash.startIndex..<hash.index(hash.startIndex, offsetBy: 2)]
  let chunk2 = hash[
    hash.index(hash.startIndex, offsetBy: 2)..<hash.index(hash.startIndex, offsetBy: 4)]
  return (chunk1, chunk2)
}

extension OuroborosFile: Decodable {
  init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: CodingKeys.self)

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    self.id = try root.decode(Int.self, forKey: .id)
    let createdAtStringDate = try root.decode(String.self, forKey: .createdAt)
    // TODO: Don't force unwrap.
    let createdAtDate = dateFormatter.date(from: createdAtStringDate)!
    self.createdAt = createdAtDate

    let file = try root.nestedContainer(keyedBy: FileKeys.self, forKey: .file)
    let ext = try file.decode(String.self, forKey: .ext)
    // TODO: Don't force unwrap.
    self.mime = BooruMime.fromExtension(ext)!
    self.size = try file.decode(Int.self, forKey: .size)
    let md5 = try file.decode(String.self, forKey: .md5)

    if let imageURL = try file.decodeIfPresent(URL.self, forKey: .url) {
      self.imageURL = imageURL
    } else {
      // When not authenticated, the URL might be omitted. We can manually construct it instead.
      // TODO: We are assuming the image to be from e621. This is BAD, BAD, BAD!

      let (chunk1, chunk2) = extractHashChunks(md5)
      let url = "https://static1.e621.net/data/\(chunk1)/\(chunk2)/\(md5).\(ext)"
      NSLog("Synthesized URL: \(url)")

      // TODO: Don't force unwrap.
      self.imageURL = URL(string: url)!
    }

    let preview = try root.nestedContainer(keyedBy: PreviewKeys.self, forKey: .preview)
    if let previewURL = try preview.decodeIfPresent(URL.self, forKey: .url) {
      self.thumbnailImageURL = previewURL
    } else {
      // Ditto.

      let (chunk1, chunk2) = extractHashChunks(md5)
      let url = "https://static1.e621.net/data/preview/\(chunk1)/\(chunk2)/\(md5).jpg"
      NSLog("Synthesized preview URL: \(url)")

      // TODO: Don't force unwrap.
      self.thumbnailImageURL = URL(string: url)!
    }

    let tags = try root.decode([String: [String]].self, forKey: .tags)
    self.tags = tags.flatMap { namespace, tags -> [OuroborosTag] in
      let normalizedNamespace: String? = namespace == "general" ? nil : namespace
      return tags.map { OuroborosTag(namespace: normalizedNamespace, subtag: $0) }
    }
  }
}

extension BooruMime {
  fileprivate static func fromExtension(_ ext: String) -> Self? {
    switch ext {
    case "png": return .png
    case "jpg": return .jpeg
    case "gif": return .gif
    case "webm": return .webm
    case "swf": return .swf
    default: return nil
    }
  }
}
