package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection

class MigrateDirectories(val neo4j: Neo4j, val connection: Connection) {
    val migrateDirectoriesProc = """
        create or replace function migrate_directories_proc(
           in userPhone varchar(255),
           in directoryName varchar(255)
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
                INSERT INTO sc_directories("creator_sys_person_id","name")
                VALUES (vPersonId,directoryName);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()


    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateDirectoriesProc)
        statement.close()
    }


    public fun migrateDirectories() {
        val createDirectorySQL = this.connection.prepareStatement(
            """
            select migrate_directories_proc from migrate_directories_proc(?,?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nDirectory")
            val result = it.run(
                "match (n:Directory) return count(n) as count"
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
                        match (n:Directory)
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
                var directoryName: String? = null
                var userPhone: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()
                    userPhone = record.get("userPhone").asString()
                    when (propName) {
                        "name" -> {
                            directoryName = record.get("propValue").asString()
                        }
                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $directoryName \n")
                createDirectorySQL.setString(1, userPhone)
                createDirectorySQL.setString(2, directoryName)

                val createResult = createDirectorySQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print("code: $code")
                createResult.close()
            }
        }
    }
}