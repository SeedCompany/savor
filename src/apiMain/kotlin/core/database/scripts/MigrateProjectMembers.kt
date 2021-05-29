package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection

class MigrateProjectMembers(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migrateProjectMembersProc = """
        create or replace function migrate_project_members_proc(
           in userPhone varchar(255),
           in projectId varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vGroupId INT;
            vPersonId INT;
        begin
            SELECT sp.sys_person_id
            FROM sys_people AS sp
            INTO vPersonId
            WHERE sp.phone = userPhone;
            IF found THEN
                SELECT sp.project_sys_group_id 
                FROM sc_projects AS sp 
                INTO vGroupId 
                WHERE sp.sc_internal_project_id = projectId;
                IF found THEN
                    INSERT INTO sc_project_members("project_sys_group_id", "sys_person_id")
                    VALUES (vGroupId, vPersonId); 
                    vResponseCode := 0;
                ELSE 
                    vResponseCode := 2;
                END IF;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init{
        val statement = this.connection.createStatement()
        statement.execute(this.migrateProjectMembersProc)
        statement.close()
    }

    public fun migrateProjectMembers() {
        val createProjectMemberSQL = this.connection.prepareStatement(
            """
            select migrate_project_members_proc from migrate_project_members_proc(?,?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nProject Members ")
            val result = it.run(
                "match (n:ProjectMember) return count(n) as count"
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
                        match (n:ProjectMember)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (project:Project)-[:member]->(n)-[:user {active: true}]->(user:User)
                        -[:phone {active: true}]->(userPhone:Property) 
                        return 
                            n.id as id,
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            userPhone.value as userPhone,
                            project.id as projectId
                    """.trimIndent()
                )
                var userPhone: String? = null
                var projectId: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()
                    userPhone = record.get("userPhone").asString()
                    projectId = record.get("projectId").asString()
                }
                it.commit()
                it.close()

                print("\n $userPhone, $projectId \n")

                createProjectMemberSQL.setString(1, userPhone)
                createProjectMemberSQL.setString(2, projectId)


                val createResult = createProjectMemberSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }
    }
}