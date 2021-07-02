import GRDB

/// A structure that represents a Hydrus tag namespace.
struct HydrusTagNamespace {
  /// The ID of the namespace.
  let id: Int

  /// The namespace text.
  let text: String

  /// Returns a `Bool` value indicating whether the namespace is the default
  /// one (no namespace).
  var isDefault: Bool {
    self.text == ""
  }
}

extension HydrusTagNamespace: FetchableRecord {
  static let tag = belongsTo(HydrusTag.self)

  init(row: Row) {
    self.id = row["namespace_id"]
    self.text = row["namespace"]
  }

  enum Columns: String, ColumnExpression {
    case id = "namespace_id"
    case namespace
  }
}

extension HydrusTagNamespace: TableRecord {
  static let databaseTableName = "namespaces"
}

extension HydrusTagNamespace: CustomStringConvertible {
  var description: String {
    self.text
  }
}
