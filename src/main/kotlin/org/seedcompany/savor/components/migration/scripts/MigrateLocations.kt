package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection

class MigrateLocations(val neo4j: Neo4j, val connection: Connection) {
    val migrateLocationsProc = """
        create or replace function migrate_locations_proc(
           in locationName varchar(32)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vLocationId INT;
        begin
            SELECT sl.sys_location_id
            FROM sys_locations AS sl
            INTO vLocationId
            WHERE sl.name = locationName;
            IF NOT found THEN
                INSERT INTO sys_locations("name")
                VALUES (locationName);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateLocationsProc)
        statement.close()
    }

    public fun migrateLocations() {
        val createLocationSQL = this.connection.prepareStatement(
            """
            select migrate_locations_proc from migrate_locations_proc(?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nLocations")
            val result = it.run(
                "match (n:Location) return count(n) as count"
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
                        match (n:Location)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as id, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )
                var locationName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()
                    when (propName) {
                        "name" -> {
                            locationName = record.get("propValue").asString()
                        }
                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n $locationName \n")

                createLocationSQL.setString(1, locationName)

                val createResult = createLocationSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }


}