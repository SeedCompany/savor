package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection
import java.sql.Types

class MigrateFileVersions(val neo4j: Neo4j, val connection: Connection) {
    val migrateFileVersionProc = """
        create or replace function migrate_file_versions_proc(
           in userPhone varchar(32),
           in fileVersionName varchar(255),
           in fileVersionSize int
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vPersonId INT;
        begin
            SELECT sp.sys_person_id 
            FROM sys_people AS sp
            INTO vPersonId
            WHERE sp.phone = userPhone;
            IF found THEN
                INSERT INTO sc_file_versions("creator_sys_person_id", "name", "file_size")
                VALUES (vPersonId, fileVersionName, fileVersionSize);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init{
        val statement = this.connection.createStatement()
        statement.execute(this.migrateFileVersionProc)
        statement.close()
    }

    public fun migrateFileVersions() {
        val createFileVersionSQL = this.connection.prepareStatement(
            """
            select migrate_file_versions_proc from migrate_file_versions_proc(?, ?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nFile Version ")
            val result = it.run(
                "match (n:FileVersion) return count(n) as count"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("count").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }
        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
                val getUserResult = it.run(
                    """
                        match (n:FileVersion)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:createdBy {active: true}]->(user:User)
                        -[:phone {active: true}]->(userPhone:Property) 
                        return 
                            n.id as id,
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            userPhone.value as userPhone
                    """.trimIndent()
                )
                var fileVersionName: String? = null
                var userPhone: String? = null
                var fileVersionSize: Int? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()

                    userPhone = record.get("userPhone").asString()
                    when (propName) {
                        "name" -> {
                            fileVersionName = record.get("propValue").asString()
                        }
                        "size" -> {
                            fileVersionSize = record.get("propValue").asInt()
                        }

                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $userPhone, $fileVersionName, $fileVersionSize \n")

                createFileVersionSQL.setString(1, userPhone)

                createFileVersionSQL.setString(2, fileVersionName)
                if (fileVersionSize != null) {
                    createFileVersionSQL.setInt(3, fileVersionSize)
                } else {
                    createFileVersionSQL.setNull(3, Types.NULL)
                }


                val createResult = createFileVersionSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print("code:$code")
                createResult.close()
            }
        }
    }

}