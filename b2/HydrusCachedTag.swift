import GRDB

/// A fetchable record that represents a cached tag.
///
/// This structure should not be used to represent real tags. `HydrusTag` should
/// be used instead.
///
/// This type maps directly to the rows in the `local_tags_cache` table, and is
/// useful for quickly fetching a tag's full text from its ID or vice versa.
struct HydrusCachedTag {
  /// The ID of the cached tag.
  let id: Int

  /// The text of the cached tag.
  let text: String
}

extension HydrusCachedTag: FetchableRecord {
  init(row: Row) {
    self.id = row["tag_id"]
    self.text = row["tag"]
  }

  enum Columns: String, ColumnExpression {
    case id = "tag_id"
    case tag
  }
}

extension HydrusCachedTag: TableRecord {
  static let databaseTableName = "local_tags_cache"
}

extension HydrusCachedTag: CustomStringConvertible {
  var description: String {
    self.text
  }
}
