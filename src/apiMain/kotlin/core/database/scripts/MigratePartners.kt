package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection
import java.sql.Types

class MigratePartners(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migratePartnersProc = """
        create or replace function migrate_partners_proc(
            in groupName varchar(255),
            in globalInnovationsClient bool,
            in pmcEntityCode varchar(32)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vGroupId INT;
            vPersonId INT;
        begin
            SELECT sys_group_id
            FROM sys_groups
            INTO vGroupId
            WHERE sys_groups.name = groupName;
            IF found THEN
                INSERT INTO sc_partners("sys_group_id","is_global_innovations_client", "pmc_entity_code")
                VALUES (vGroupId, globalInnovationsClient, pmcEntityCode)
                RETURNING sys_group_id
                INTO vGroupId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migratePartnersProc)
        statement.close()
    }
    public fun migratePartners() {
        val createPartnerSQL = this.connection.prepareStatement(
            """
            select migrate_partners_proc from migrate_partners_proc(?, ?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nPartners ")
            val result = it.run(
                "match (n:Partner) return count(n) as count"
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
                        match (n:Partner)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:organization {active: true}]->(org:Organization)
                        -[:name {active: true}]->(orgName:Property) 
                        return 
                            n.id as groupId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            orgName.value as groupName
                    """.trimIndent()
                )
                var globalInnovationsClient: Boolean? = null
                var pmcEntityCode: String? = null
                var groupName: String? = null

                while(getUserResult.hasNext()){
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()

                    groupName = record.get("groupName").asString()
                    when(propName){
                        "globalInnovationsClient"->{
                            globalInnovationsClient = record.get("propValue").asBoolean()
                        }
                        "pmcEntityCode" ->{
                            pmcEntityCode = record.get("propValue").asString()
                        }
                        else -> {
                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                createPartnerSQL.setString(1,groupName)
                if (globalInnovationsClient != null) {
                    createPartnerSQL.setBoolean(2, globalInnovationsClient)
                } else {
                    createPartnerSQL.setNull(2, Types.NULL)
                }
                createPartnerSQL.setString(3,pmcEntityCode)

                val createResult = createPartnerSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }

    }
}