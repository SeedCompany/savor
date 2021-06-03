package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection

class MigratePlanChanges(val neo4j: Neo4j, val connection: Connection) {
    val migratePlanChangeProc = """
        create or replace function migrate_plan_change_proc(
            in mockSummary text
        )
        returns INT  
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vPlanChangeId INT;
        begin
            SELECT scp.sc_change_to_plan_id
            FROM sc_change_to_plans AS scp
            INTO vPlanChangeId
            WHERE scp.summary = mockSummary;
            IF NOT found THEN
                INSERT INTO sc_change_to_plans("summary")
                VALUES (mockSummary);
                vResponseCode := 0;
            ELSE 
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migratePlanChangeProc)
        statement.close()
    }

    public fun migratePlanChange() {

        //language=SQL
        val createPlanChangeSQL= this.connection.prepareStatement(
            """
            select migrate_plan_change_proc from migrate_plan_change_proc(?);
        """.trimIndent()
        )


        for (i in 0 until 1000) {
            neo4j.driver.session().readTransaction {
                print("\n${i} ")
                var summary: String = "A${i}"



                it.commit()
                it.close()

                // write to postgres
                createPlanChangeSQL.setString(1, summary)

                val createResult = createPlanChangeSQL.executeQuery()
                createResult.next()
                val returnCode = createResult.getInt(1)
                print("internal ethId: $i returnCode: $returnCode ")
                createResult.close()
            }
        }
    }
}