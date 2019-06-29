import Foundation

struct OuroborosFile: BooruFile {
    var imageURL: URL
    var thumbnailImageURL: URL
    var id: Int
    var createdAt: Date
    var size: Int
    var tags: [BooruTag]
    var mime: BooruMime

    enum CodingKeys: String, CodingKey {
        case artist
        case fileExtension = "file_ext"
        case id
        case size = "file_size"
        case imageURL = "file_url"
        case thumbnailImageURL = "preview_url"
        case createdAt = "created_at"
        case tags
    }

    enum CreatedAtKeys: String, CodingKey {
        case timestamp = "s" // ?
    }
}

extension OuroborosFile: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.imageURL = try values.decode(URL.self, forKey: .imageURL)
        self.thumbnailImageURL = try values.decode(URL.self, forKey: .thumbnailImageURL)
        self.id = try values.decode(Int.self, forKey: .id)
        self.size = try values.decode(Int.self, forKey: .size)

        let createdAtInfo = try values.nestedContainer(keyedBy: CreatedAtKeys.self, forKey: .createdAt)
        self.createdAt = Date(timeIntervalSince1970: try createdAtInfo.decode(Double.self, forKey: .timestamp))

        self.mime = BooruMime.fromExtension(try values.decode(String.self, forKey: .fileExtension))!

        let tagsString = try values.decode(String.self, forKey: .tags)
        let artistsArray = try values.decode([String].self, forKey: .artist)

        self.tags = tagsString.split(separator: " ")
            .map { OuroborosTag(text: String($0)) }
            + artistsArray.map { OuroborosTag(namespace: "artist", subtag: $0) }
    }
}

private extension BooruMime {
    static func fromExtension(_ ext: String) -> Self? {
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
