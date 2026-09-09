import Foundation
import SQLite3

struct SyncTableRecord {
    let name: String
    let packageId: String
    let lastMod: Int64
    let conflict: Int
}

class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?
    
    private init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentsURL.appendingPathComponent("sync.sqlite3")
        
        // sqlite3_open automatically creates the file if it doesn't exist
        if sqlite3_open(dbURL.path, &db) == SQLITE_OK {
            print("✅ Database opened/created at: \(dbURL.path)")
            createTableIfNeeded()
        } else {
            print("❌ Unable to open or create database.")
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Initialize Table
    
    private func createTableIfNeeded() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS sync (
            name TEXT PRIMARY KEY NOT NULL,
            packageId TEXT NOT NULL,
            lastMod INTEGER NOT NULL,
            conflict INTEGER NOT NULL
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Sync table is ready.")
            } else {
                print("❌ Could not execute CREATE TABLE.")
            }
        } else {
            print("❌ CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Fetch Records
    
    func getSyncRecords(for packageId: String) -> [SyncTableRecord] {
        let query = "SELECT name, packageId, lastMod, conflict FROM sync WHERE packageId = ?;"
        var statement: OpaquePointer?
        var records: [SyncTableRecord] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (packageId as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                records.append(SyncTableRecord(
                    name: String(cString: sqlite3_column_text(statement, 0)),
                    packageId: String(cString: sqlite3_column_text(statement, 1)),
                    lastMod: sqlite3_column_int64(statement, 2),
                    conflict: Int(sqlite3_column_int(statement, 3))
                ))
            }
        }
        sqlite3_finalize(statement)
        return records
    }
    
    // MARK: - Insert or Update Record
    
    func upsertSyncRecord(name: String, packageId: String, lastMod: Int64, conflict: Int = 0) {
        // INSERT OR REPLACE adds the row if it's new, or updates it if 'name' already exists
        let query = "INSERT OR REPLACE INTO sync (name, packageId, lastMod, conflict) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (packageId as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 3, lastMod)
            sqlite3_bind_int(statement, 4, Int32(conflict))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Database Saved: \(name) -> \(lastMod)")
            } else {
                print("❌ Could not save row for \(name).")
            }
        }
        sqlite3_finalize(statement)
    }
}
