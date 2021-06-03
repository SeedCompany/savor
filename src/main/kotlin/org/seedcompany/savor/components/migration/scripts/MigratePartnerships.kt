package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection

class MigratePartnerships(val neo4j: Neo4j, val connection: Connection) {
    val migratePartnershipsProc = """
        create or replace function migrate_partnerships_proc(
           in orgName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vGroupId INT;
        begin
            SELECT sg.sys_group_id
            FROM sys_groups AS sg
            INTO vGroupId
            WHERE sg.name = orgName;
            IF found THEN
                INSERT INTO sc_partnerships("project_sys_group_id", "partner_sys_group_id")
                VALUES (vGroupId, vGroupId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init{
        val statement = this.connection.createStatement()
        statement.execute(this.migratePartnershipsProc)
        statement.close()
    }

    public fun migratePartnerships() {
        val createFileSQL = this.connection.prepareStatement(
            """
            select migrate_partnerships_proc from migrate_partnerships_proc(?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nPartnerships ")
            val result = it.run(
                "match (n:Partnership) return count(n) as count"
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
                        match (n:Partnership)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (project:Project)-[:partnership]->(n)-[:partner {active: true}]->(partner:Partner)
                        -[:organization {active:true}]->(org:Organization)
                        -[:name {active: true}]->(orgName:Property) 
                        return 
                            n.id as id,
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            orgName.value as orgName,
                            project.id as projectId
                    """.trimIndent()
                )
                var orgName: String? = null
                var projectId: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    orgName = record.get("orgName").asString()
                }
                it.commit()
                it.close()

                print("\n $orgName \n")

                createFileSQL.setString(1, orgName)


                val createResult = createFileSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }
}