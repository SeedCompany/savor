package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection

class MigrateFieldRegions(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migrateFieldRegionsProc = """
        create or replace function migrate_field_regions_proc(
           in directorPhone varchar(32),
           in fieldRegionName varchar(32)
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
            WHERE sp.phone = directorPhone;
            IF found THEN
                INSERT INTO sc_field_regions("director_sys_person_id", "name")
                VALUES (vPersonId, fieldRegionName);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init{
        val statement = this.connection.createStatement()
        statement.execute(this.migrateFieldRegionsProc)
        statement.close()
    }

    public fun migrateFieldRegions() {
        val createFieldRegionSQL = this.connection.prepareStatement(
            """
            select migrate_field_regions_proc from migrate_field_regions_proc(?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nField Regions ")
            val result = it.run(
                "match (n:FieldRegion) return count(n) as count"
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
                        match (n:FieldRegion)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:director {active: true}]->(user:User)
                        -[:phone {active: true}]->(userPhone:Property) 
                        return 
                            n.id as id,
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            userPhone.value as userPhone
                    """.trimIndent()
                )
                var userPhone: String? = null
                var fieldRegionName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()
                    userPhone = record.get("userPhone").asString()
                    when (propName) {
                        "name" -> {
                            fieldRegionName = record.get("propValue").asString()
                        }
                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $userPhone \n")

                createFieldRegionSQL.setString(1, userPhone)
                createFieldRegionSQL.setString(2, fieldRegionName)

                val createResult = createFieldRegionSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }
}