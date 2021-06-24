import GRDB

/// A structure that represents a Hydrus subtag.
struct HydrusSubtag {
  /// The ID of the subtag.
  let id: Int

  /// The text of the subtag.
  let text: String
}

extension HydrusSubtag: FetchableRecord {
  static let tag = belongsTo(HydrusTag.self)

  init(row: Row) {
    self.id = row["subtag_id"]
    self.text = row["subtag"]
  }

  enum Columns: String, ColumnExpression {
    case id = "subtag_id"
    case text = "subtag"
  }
}

extension HydrusSubtag: TableRecord {
  static let databaseTableName = "master.subtags"
}

extension HydrusSubtag: CustomStringConvertible {
  var description: String {
    return self.text
  }
}
