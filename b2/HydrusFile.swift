import Foundation
import Path

/// A file in a Hydrus database.
class HydrusFile {
  fileprivate enum PathType: String {
    case original = "f"
    case thumbnail = "t"
  }

  /// The hash of the file as a hexadecimal string.
  let hash: String

  /// The ID of the hash of the file in the database.
  let hashId: Int

  /// A weak reference to the `HydrusDatabase`.
  weak var database: HydrusDatabase?

  /// The file's metadata.
  private var metadata: HydrusMetadata

  let globalID: String

  private lazy var cachedTags: [HydrusTag] = {
    try! measure("Initial Hydrus tag fetch for \(self.hashId)") {
      try self.fetchTags()
    }
  }()

  init(
    hash: String, hashId: Int, database: HydrusDatabase, metadata: HydrusMetadata, globalID: String
  ) {
    self.hash = hash
    self.hashId = hashId
    self.database = database
    self.metadata = metadata
    self.globalID = globalID
  }

  private func path(ofType type: PathType = .original) -> Path {
    guard let database = self.database else {
      // This happens when the file is loaded after the database has been
      // freed, e.g. if the user switches away from the booru source while
      // files are being loaded. This causes the database object itself
      // to be freed, but files will still try to load.
      //
      // TODO: This should be fixed by canceling the load when the booru
      // changes.
      NSLog("Warning: Attempted to fetch path of a HydrusFile after database was freed.")
      let url = Bundle.main.url(forResource: "FailedToLoadImage", withExtension: "png")
      return Path(url: url!)!
    }

    let firstTwo = self.hash[...self.hash.index(self.hash.startIndex, offsetBy: 1)]
    let sectorId = type.rawValue + firstTwo
    let sectorPath = database.base / "client_files" / sectorId

    switch type {
    case .thumbnail:
      return sectorPath / "\(self.hash).thumbnail"
    case .original:
      let ext = self.metadata.mime.extension
      return sectorPath / "\(self.hash).\(ext)"
    }
  }

  private func fetchTags() throws -> [HydrusTag] {
    guard let database = self.database else {
      NSLog("Warning: Attempted to fetch tags of a HydrusFile after database was freed.")
      return []
    }

    return try database.queue.read { db in
      try database.tags.tags(forFile: self, database: db)
    }
  }
}

extension HydrusFile: BooruPost {
  var id: Int {
    self.hashId
  }

  var imageURL: URL {
    self.path(ofType: .original).url
  }

  var thumbnailImageURL: URL {
    self.path(ofType: .thumbnail).url
  }

  var createdAt: Date {
    self.metadata.timestamp
  }

  var size: Int {
    self.metadata.size
  }

  var tags: [BooruTag] {
    self.cachedTags
  }

  var mime: BooruMime {
    self.metadata.mime.booruMime!
  }

  var postURL: URL? {
    nil
  }
}
