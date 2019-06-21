import Foundation
import SQLite
import Path_swift

// @@ services table
let services = Table("services")
let serviceId = Expression<Int>("service_id")
let serviceKey = Expression<SQLite.Blob>("service_key")
let serviceType = Expression<Int>("service_type")
let serviceName = Expression<String>("name")
let serviceDictString = Expression<String>("dictionary_string")

// @@ current_files table
let currentFiles = Table("current_files")
// serviceId
let hashId = Expression<Int>("hash_id")
let timestamp = Expression<Int>("timestamp")

// @@ hashes table
let hashes = Table("hashes")
// hashId
let hash = Expression<SQLite.Blob>("hash")

class MediaDatabase {
    var databasePath: Path

    var db: Connection!
    var mappingsDb: Connection!
    var masterDb: Connection!
    var cachesDb: Connection!

    init(databasePath path: Path) throws {
        databasePath = path

        NSLog("Loading database at \(databasePath.string)")
        db = try Connection((databasePath / "client.db").string)
        mappingsDb = try Connection((databasePath / "client.mappings.db").string)
        masterDb = try Connection((databasePath / "client.master.db").string)
        cachesDb = try Connection((databasePath / "client.caches.db").string)
    }

    func pathToHash(_ hash: String) -> Path {
        let firstTwo = hash[...hash.index(hash.startIndex, offsetBy: 1)]
        return databasePath / "client_files" / "f\(firstTwo)" / "\(hash)"
    }

    func serviceNamed(_ name: String) throws -> Int? {
        let query = services.select(serviceId).filter(serviceName == "all local files")
        if let row = try db.pluck(query) {
            return row[serviceId]
        } else {
            return nil
        }
    }

    func resolveHash(id: Int) throws -> String {
        let query = hashes.select(hash).filter(hashId == id)
        let row = try masterDb.pluck(query)!
        return row[hash].toHex()
    }

    func media() throws -> [String] {
        let localFilesServiceId = try serviceNamed("all local files")!
        let query = currentFiles.select(hashId)
            .filter(serviceId == localFilesServiceId)

        var fileHashes: [String] = []
        for file in try db.prepare(query) {
            let fileHashId = file[hashId]
            try fileHashes.append(resolveHash(id: fileHashId))
        }

        return fileHashes
    }

    deinit {
        NSLog("Database leaving")
    }
}
