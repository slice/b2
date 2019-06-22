import GRDB

/// A structure that represents a Hydrus tag.
///
/// A tag consists of a namespace (`HydrusTagNamespace`) and a subtag
/// (`HydrusSubtag`).
struct HydrusTag {
    /// The tag's ID.
    let id: Int

    /// The subtag text.
    let subtag: HydrusSubtag

    /// The namespace that this tag resides in.
    let namespace: HydrusTagNamespace

    init(id: Int, subtag: HydrusSubtag, namespace: HydrusTagNamespace) {
        self.id = id
        self.subtag = subtag
        self.namespace = namespace
    }
}

extension HydrusTag: TableRecord {
    static let databaseTableName = "tags"
}

extension HydrusTag: CustomStringConvertible {
    var description: String {
        let colon = self.namespace.isDefault ? "" : ":"
        return "\(self.namespace)\(colon)\(self.subtag)"
    }
}
