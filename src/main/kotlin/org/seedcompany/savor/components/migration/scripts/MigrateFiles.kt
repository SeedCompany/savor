package components.migration.scripts

import org.seedcompany.api.core.Neo4j
import java.sql.Connection

class MigrateFiles(val neo4j: Neo4j, val connection: Connection) {
    val migrateFilesProc = """
        create or replace function migrate_files_proc(
           in userPhone varchar(32),
           in fileName varchar(255)
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
                INSERT INTO sc_files("creator_sys_person_id", "name")
                VALUES (vPersonId, fileName);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()
    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateFilesProc)
        statement.close()
    }

    public fun migrateFiles() {
        val createFileSQL = this.connection.prepareStatement(
            """
            select migrate_files_proc from migrate_files_proc(?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nFile ")
            val result = it.run(
                "match (n:File) return count(n) as count"
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
                        match (n:File)
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


                var fileName: String? = null
                var userPhone: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()

                    userPhone = record.get("userPhone").asString()
                    when (propName) {
                        "name" -> {
                            fileName = record.get("propValue").asString()
                        }
                        else -> {
                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $userPhone,$fileName \n")

                createFileSQL.setString(1, userPhone)

                createFileSQL.setString(2, fileName)

                val createResult = createFileSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }

}