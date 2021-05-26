package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection
import java.sql.Types

class MigratePlanChanges(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migratePlanChangeProc = """
        create or replace function migrate_plan_change_proc(
            in mockSummary text
        )
        returns INT  
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
        begin
            SELECT scp.summary
            FROM sc_change_to_plans AS scp
            WHERE scp.summary = mockSummary;
            IF NOT found THEN
                INSERT INTO sc_change_to_plans("summary")
                VALUES (mockSummary);
                vResponseCode := 0;
            ELSE 
                vResponseCode := 1;
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