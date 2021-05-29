package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection
import java.sql.Types

class MigrateBudgets(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migrateBudgetsProc =  """
        create or replace function migrate_budgets_proc(
           in projectId varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vGroupId INT;
        begin
            SELECT sp.project_sys_group_id
            FROM sc_projects AS sp
            INTO vGroupId
            WHERE sp.sc_internal_project_id = projectId;
            IF found THEN
                INSERT INTO sc_budgets("project_sys_group_id")
                VALUES (vGroupId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateBudgetsProc)
        statement.close()
    }

    public fun migrateBudgets() {
        val createBudgetSQL = this.connection.prepareStatement(
            """
            select migrate_budgets_proc from migrate_budgets_proc(?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nBudget")
            val result = it.run(
                "match (n:Budget) return count(n) as count"
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
                        match (n:Budget)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with *
                        match (project:Project)-[:budget]->(n)
                        return
                            n.id as id,
                            project.id as projectId
                    """.trimIndent()
                )
                var projectId: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    projectId = record.get("projectId").asString()
                }
                it.commit()
                it.close()

                print("\n  projectId: $projectId  \n")
                createBudgetSQL.setString(1, projectId)
                val createResult = createBudgetSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print("code: $code")
                createResult.close()
            }
        }
    }
}