import Foundation
import SQLite3

// MARK: - Sync Table Record

struct SyncTableRecord {

    let name: String
    let packageId: String
    let lastMod: Int64
    let conflict: Bool
}

// MARK: - Sync Table

final class SyncTable {

    static let shared = SyncTable()

    private init() {
        openDatabase()
    }

    private var database: OpaquePointer?

    // MARK: - Database Location

    private var databaseURL: URL {

        let applicationSupportDirectory =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]

        return applicationSupportDirectory.appendingPathComponent(
            "sync.sqlite3"
        )
    }

    // MARK: - Open Database

    private func openDatabase() {

        do {

            let applicationSupportDirectory =
                FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                )[0]

            try FileManager.default.createDirectory(
                at: applicationSupportDirectory,
                withIntermediateDirectories: true
            )

            let writableDatabaseURL = databaseURL

            // ------------------------------------------------
            // First launch:
            // Copy the database supplied with the app
            // into Application Support.
            // ------------------------------------------------

            if !FileManager.default.fileExists(
                atPath: writableDatabaseURL.path
            ) {

                guard let bundledDatabaseURL =
                        Bundle.main.url(
                            forResource: "sync",
                            withExtension: "sqlite3"
                        )
                else {

                    print("❌ sync.sqlite3 not found in app bundle")
                    return
                }

                try FileManager.default.copyItem(
                    at: bundledDatabaseURL,
                    to: writableDatabaseURL
                )

                print("📦 sync.sqlite3 copied to Application Support")
            }

            // ------------------------------------------------
            // Open writable database
            // ------------------------------------------------

            let result =
                sqlite3_open(
                    writableDatabaseURL.path,
                    &database
                )

            guard result == SQLITE_OK else {

                print("❌ Could not open sync.sqlite3")

                if let database {
                    print(
                        String(
                            cString: sqlite3_errmsg(database)
                        )
                    )
                }

                return
            }

            print("✅ SyncTable database opened")
            print(writableDatabaseURL.path)

        } catch {

            print("❌ Database setup error:")
            print(error.localizedDescription)
        }
    }

    // MARK: - Close Database

    deinit {

        if let database {
            sqlite3_close(database)
        }
    }

    // MARK: - Get Record

    func getRecord(
        packageId: String
    ) -> SyncTableRecord? {

        guard let database else {

            print("❌ Database is not open")

            return nil
        }

        let sql = """
        SELECT name, packageId, lastMod, conflict
        FROM sync
        WHERE packageId = ?
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {

            print("❌ Could not prepare SELECT statement")

            print(
                String(
                    cString: sqlite3_errmsg(database)
                )
            )

            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        bindText(
            statement: statement,
            index: 1,
            value: packageId
        )

        guard sqlite3_step(statement) == SQLITE_ROW
        else {

            return nil
        }

        guard let namePointer =
                sqlite3_column_text(statement, 0),
              let packageIdPointer =
                sqlite3_column_text(statement, 1)
        else {

            return nil
        }

        let name =
            String(
                cString: namePointer
            )

        let returnedPackageId =
            String(
                cString: packageIdPointer
            )

        let lastMod =
            sqlite3_column_int64(
                statement,
                2
            )

        let conflictValue =
            sqlite3_column_int(
                statement,
                3
            )

        let conflict =
            conflictValue != 0

        return SyncTableRecord(
            name: name,
            packageId: returnedPackageId,
            lastMod: lastMod,
            conflict: conflict
        )
    }

    // MARK: - Insert Record

    func insertRecord(
        name: String,
        packageId: String,
        lastMod: Int64,
        conflict: Bool
    ) {

        guard let database else {

            print("❌ Database is not open")

            return
        }

        let sql = """
        INSERT INTO sync
        (name, packageId, lastMod, conflict)
        VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {

            print("❌ Could not prepare INSERT statement")

            print(
                String(
                    cString: sqlite3_errmsg(database)
                )
            )

            return
        }

        defer {
            sqlite3_finalize(statement)
        }

        bindText(
            statement: statement,
            index: 1,
            value: name
        )

        bindText(
            statement: statement,
            index: 2,
            value: packageId
        )

        // IMPORTANT:
        // Store the exact server millisecond value.

        sqlite3_bind_int64(
            statement,
            3,
            lastMod
        )

        sqlite3_bind_int(
            statement,
            4,
            conflict ? 1 : 0
        )

        guard sqlite3_step(statement) == SQLITE_DONE
        else {

            print("❌ Could not insert SyncTable record")

            print(
                String(
                    cString: sqlite3_errmsg(database)
                )
            )

            return
        }

        print("✅ SyncTable record inserted")
        print("Package:", packageId)
        print("lastMod:", lastMod)
        print("conflict:", conflict)
    }

    // MARK: - Update Record

    func updateRecord(
        packageId: String,
        lastMod: Int64,
        conflict: Bool
    ) {

        guard let database else {

            print("❌ Database is not open")

            return
        }

        let sql = """
        UPDATE sync
        SET lastMod = ?, conflict = ?
        WHERE packageId = ?
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {

            print("❌ Could not prepare UPDATE statement")

            print(
                String(
                    cString: sqlite3_errmsg(database)
                )
            )

            return
        }

        defer {
            sqlite3_finalize(statement)
        }

        // Exact server timestamp.

        sqlite3_bind_int64(
            statement,
            1,
            lastMod
        )

        sqlite3_bind_int(
            statement,
            2,
            conflict ? 1 : 0
        )

        bindText(
            statement: statement,
            index: 3,
            value: packageId
        )

        guard sqlite3_step(statement) == SQLITE_DONE
        else {

            print("❌ Could not update SyncTable record")

            print(
                String(
                    cString: sqlite3_errmsg(database)
                )
            )

            return
        }

        print("✅ SyncTable record updated")
        print("Package:", packageId)
        print("lastMod:", lastMod)
        print("conflict:", conflict)
    }

    // MARK: - Update Conflict

    func updateConflict(
        packageId: String,
        conflict: Bool
    ) {

        guard let database else {

            print("❌ Database is not open")

            return
        }

        let sql = """
        UPDATE sync
        SET conflict = ?
        WHERE packageId = ?
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK
        else {

            print("❌ Could not prepare conflict UPDATE")

            return
        }

        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_int(
            statement,
            1,
            conflict ? 1 : 0
        )

        bindText(
            statement: statement,
            index: 2,
            value: packageId
        )

        guard sqlite3_step(statement) == SQLITE_DONE
        else {

            print("❌ Could not update conflict")

            return
        }

        print("⚠️ SyncTable conflict updated")
        print("Package:", packageId)
        print("conflict:", conflict)
    }

    // MARK: - Save Record

    func saveRecord(
        name: String,
        packageId: String,
        lastMod: Int64,
        conflict: Bool
    ) {

        if getRecord(packageId: packageId) != nil {

            updateRecord(
                packageId: packageId,
                lastMod: lastMod,
                conflict: conflict
            )

        } else {

            insertRecord(
                name: name,
                packageId: packageId,
                lastMod: lastMod,
                conflict: conflict
            )
        }
    }

    // MARK: - Force Update Server LastMod

    func forceUpdateLastMod(
        packageId: String,
        serverLastMod: Int64,
        name: String
    ) {

        if getRecord(packageId: packageId) != nil {

            updateRecord(
                packageId: packageId,
                lastMod: serverLastMod,
                conflict: false
            )

        } else {

            insertRecord(
                name: name,
                packageId: packageId,
                lastMod: serverLastMod,
                conflict: false
            )
        }

        print("")
        print("💾 SyncTable synchronized with SERVER")
        print("Package:", packageId)
        print("Server lastMod:", serverLastMod)
        print("Conflict:", false)
        print("")
    }

    // MARK: - SQLite Text Binding

    private func bindText(
        statement: OpaquePointer?,
        index: Int32,
        value: String
    ) {

        let destructor =
            unsafeBitCast(
                -1,
                to: sqlite3_destructor_type.self
            )

        sqlite3_bind_text(
            statement,
            index,
            value,
            -1,
            destructor
        )
    }
}
