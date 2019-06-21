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

    var database: Connection!
    var mappingDatabase: Connection!
    var masterDatabase: Connection!
    var cachesDatabase: Connection!

    init(databasePath path: Path) throws {
        self.databasePath = path

        func connect(_ file: String) throws -> Connection {
            let databaseFilePath = path / file
            return try Connection(databaseFilePath.string)
        }

        NSLog("Loading database at \(path.string)")
        self.database = try connect("client.db")
        self.mappingDatabase = try connect("client.mappings.db")
        self.masterDatabase = try connect("client.master.db")
        self.cachesDatabase = try connect("client.caches.db")
    }

    func pathToHash(_ hash: String) -> Path {
        let firstTwo = hash[...hash.index(hash.startIndex, offsetBy: 1)]
        return self.databasePath / "client_files" / "f\(firstTwo)" / "\(hash)"
    }

    func serviceNamed(_ name: String) throws -> Int? {
        let query = services.select(serviceId).filter(serviceName == "all local files")
        let row = try self.database.pluck(query)
        return row == nil ? nil : row![serviceId]
    }

    func resolveHash(id: Int) throws -> String {
        let query = hashes.select(hash).filter(hashId == id)
        let row = try self.masterDatabase.pluck(query)!
        return row[hash].toHex()
    }

    func media() throws -> [String] {
        let localFilesServiceId = try serviceNamed("all local files")!
        let query = currentFiles.select(hashId)
            .filter(serviceId == localFilesServiceId)

        var fileHashes: [String] = []
        for file in try self.database.prepare(query) {
            let fileHashId = file[hashId]
            try fileHashes.append(resolveHash(id: fileHashId))
        }

        return fileHashes
    }

    deinit {
        NSLog("Database deinitializing")
    }
}
