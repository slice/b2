import GRDB

/// A structure that represents a Hydrus tag.
///
/// A tag consists of a namespace (`HydrusTagNamespace`) and a subtag
/// (`HydrusSubtag`).
struct HydrusTag {
  /// The tag's ID.
  let id: Int

  private let hydrusSubtag: HydrusSubtag
  private let hydrusNamespace: HydrusTagNamespace

  init(id: Int, subtag: HydrusSubtag, namespace: HydrusTagNamespace) {
    self.id = id
    self.hydrusSubtag = subtag
    self.hydrusNamespace = namespace
  }
}

extension HydrusTag: TableRecord {
  static let databaseTableName = "tags"
}

extension HydrusTag: CustomStringConvertible {
  var description: String {
    let colon = self.hydrusNamespace.isDefault ? "" : ":"
    return "\(self.hydrusNamespace)\(colon)\(self.subtag)"
  }
}

extension HydrusTag: BooruTag {
  var subtag: String {
    self.hydrusSubtag.text
  }

  var namespace: String? {
    self.hydrusNamespace.isDefault ? nil : self.hydrusNamespace.text
  }
}
