package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection

class MigrateFieldZones(val neo4j: Neo4j, val connection: Connection)  {
    val migrateFieldZonesProc = """
        create or replace function migrate_field_zones_proc(
           in directorPhone varchar(32),
           in fieldZoneName varchar(32)
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
                INSERT INTO sc_field_zone("director_sys_person_id", "name")
                VALUES (vPersonId, fieldZoneName);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init{
        val statement = this.connection.createStatement()
        statement.execute(this.migrateFieldZonesProc)
        statement.close()
    }

    public fun migrateFieldZones() {
        val createFieldZoneSQL = this.connection.prepareStatement(
            """
            select migrate_field_zones_proc from migrate_field_zones_proc(?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nField Zones ")
            val result = it.run(
                "match (n:FieldZone) return count(n) as count"
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
                        match (n:FieldZone)
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
                var fieldZoneName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()
                    userPhone = record.get("userPhone").asString()
                    when (propName) {
                        "name" -> {
                            fieldZoneName = record.get("propValue").asString()
                        }
                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $userPhone \n")

                createFieldZoneSQL.setString(1, userPhone)
                createFieldZoneSQL.setString(2, fieldZoneName)

                val createResult = createFieldZoneSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }

}