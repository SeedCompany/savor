package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import org.seedcompany.savor.core.PostgresConfig
import java.sql.Connection
import java.sql.Types

class MigrateProjects(val config: PostgresConfig, val neo4j: Neo4j, val connection: Connection) {
    val migrateProjectsProc =  """
        create or replace function migrate_projects_proc(
           in internalProjectId varchar(255),
           in departmentId varchar(255),
           in projectName varchar(255), 
           in groupName varchar(255),
           in planChangeId int
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
            WHERE sg.name = groupName;
            IF found THEN
                INSERT INTO sc_projects("project_sys_group_id","sc_internal_project_id","name", "department_id", "sc_change_to_plan_id")
                VALUES (vGroupId, internalProjectId, projectName, departmentId, planChangeId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateProjectsProc)
        statement.close()
    }

    public fun migrateProjects() {
        val createProjectSQL = this.connection.prepareStatement(
            """
            select migrate_projects_proc from migrate_projects_proc(?,?,?,?,?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nProject")
            val result = it.run(
                "match (n:Project) return count(n) as count"
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
                        match (n:Project)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:owningOrganization {active: true}]->(organization:Organization)
                        -[:name {active: true}]->(groupName:Property) 
                        return 
                            n.id as id, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            groupName.value as orgName
                    """.trimIndent()
                )
                var orgName: String? = null
                var departmentId: Int? = null
                var projectInteralId: String? = null
                var projectName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()
                    orgName = record.get("orgName").asString()
                    projectInteralId = record.get("id").asString()
                    when (propName) {
                        "name" -> {
                            projectName = record.get("propValue").asString()
                        }
//                        "departmentId"->{
//                            departmentId = record.get("propValue").asInt()
//                        }
                        else -> {
//                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                print("\n projectName: $projectName, orgName: $orgName, projectId: $projectInteralId  \n")
                createProjectSQL.setString(1, projectInteralId)
                if (departmentId != null) {
                    createProjectSQL.setInt(2, departmentId)
                } else {
                    createProjectSQL.setNull(2, Types.NULL)
                }
                createProjectSQL.setString(3, projectName)
                createProjectSQL.setString(4,orgName)
                createProjectSQL.setInt(5,i)

                val createResult = createProjectSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print("code: $code")
                createResult.close()
            }
        }
    }

}