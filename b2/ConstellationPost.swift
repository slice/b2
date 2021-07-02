import Foundation

enum ConstellationTagStatus: Int {
  case current = 0
  case pending = 1
  case deleted = 2
  case petitioned = 3
}

class ConstellationPost {
  private unowned let booru: ConstellationBooru
  private let metadata: ConstellationBooruMetadataResponse.Entry

  init(metadata: ConstellationBooruMetadataResponse.Entry, booru: ConstellationBooru) {
    self.metadata = metadata
    self.booru = booru
  }

  private func computeImageURL(thumbnail: Bool) -> URL {
    let url = self.booru.baseURL / "get_files" / (thumbnail ? "thumbnail" : "file")
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      fatalError("can't compute ConstellationPost's imageURL -- invalid booru baseURL")
    }
    components.query =
      "file_id=\(self.metadata.fileID)&"
        + "\(ConstellationBooru.apiAccessKeyHeader)=\(self.booru.accessKey)"
    guard let finalURL = components.url else {
      fatalError("can't compute ConstellationPost's imageURL -- invalid final URL")
    }
    return finalURL
  }
}

extension ConstellationPost: BooruPost {
  var imageURL: URL {
    self.computeImageURL(thumbnail: false)
  }

  var thumbnailImageURL: URL {
    self.computeImageURL(thumbnail: true)
  }

  var id: Int {
    self.metadata.fileID
  }

  var globalID: String {
    self.booru.formGlobalID(withBooruID: self.metadata.fileID)
  }

  var createdAt: Date {
    // TODO: Hydrus's client API doesn't return dates, so just... do this.
    Date(timeIntervalSince1970: 0)
  }

  var size: Int {
    self.metadata.size
  }

  var tags: [BooruTag] {
    let allCurrentRawTags = self.metadata.serviceNamesToStatusesToDisplayTags
      .values
      .map { $0[String(ConstellationTagStatus.current.rawValue)] }
      .compactMap { $0 }
      .joined()
    let uniqueCurrentRawTags = Array(Set(allCurrentRawTags))
    return uniqueCurrentRawTags.compactMap { SimpleBooruTag(parsingDescription: $0) }
  }

  var mime: BooruMime {
    guard let mime = BooruMime(extension: self.metadata.mime) else {
      fatalError("hydrus provided unsupported mime -- \(self.metadata.mime)")
    }
    return mime
  }
}
