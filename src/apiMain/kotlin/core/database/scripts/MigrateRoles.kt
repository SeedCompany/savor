package core.database.scripts
import core.Config
import java.time.ZonedDateTime
import core.database.Neo4j
import java.sql.Connection

class MigrateRoles(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val createSCRoleProc = """
        create or replace function create_sc_role(
            in pRoleName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysGroupId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vSysGroupId
            WHERE sys_groups.name = pRoleName AND sys_groups.type = 'SC Global Role';
            IF NOT found THEN
                INSERT INTO sys_groups("name", "type")
                VALUES (pRoleName, 'SC Global Role')
                RETURNING sys_group_id
                INTO vSysGroupId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    val addUserRoleProc = """
        create or replace function add_user_role_proc(
            in pInternalId varchar(32),
            in pRoleName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysPersonId INT;
            vSysGroupId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vSysGroupId
            WHERE sys_groups.name = pRoleName AND sys_groups.type = 'SC Global Role';
            IF FOUND THEN
                SELECT sys_person_id
                FROM sc_people_ext_sys_people
                INTO vSysPersonId
                WHERE sc_people_ext_sys_people.sc_internal_person_id = pInternalId;
                IF FOUND THEN
                    INSERT INTO sys_group_membership_by_person("sys_person_id", "sys_group_id")
                    VALUES (vSysPersonId, vSysGroupId);
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

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.createSCRoleProc)
        statement.execute(this.addUserRoleProc)
        statement.close()
    }

    public fun migrateRoles() {

        // create roles

        val roles = listOf(
            "Administrator",
            "Consultant",
            "Consultant Manager",
            "Controller",
            "Field Operations Director",
            "Financial Analyst",
            "Fundraising",
            "Intern",
            "Leadership",
            "Lead Financial Analyst",
            "Liaison",
            "Marketing",
            "Mentor",
            "Project Manager",
            "Regional Communications Coordinator",
            "Regional Director",
            "Staff Member",
            "Translator"
        )

        //language=SQL
        val createRoleSQL = this.connection.prepareStatement(
            """
            select create_sc_role from create_sc_role(?);
        """.trimIndent()
        )

        for (role in roles) {
            createRoleSQL.setString(1, role)
            val createResult = createRoleSQL.executeQuery()
            createResult.next()
            val code = createResult.getInt(1)
            println("role created: $role code: $code ")
            createResult.close()
        }

        // add user roles

        //language=SQL
        val addUserRoleSQL = this.connection.prepareStatement(
            """
            select add_user_role_proc from add_user_role_proc(?, ?);
        """.trimIndent()
        )

        neo4j.driver.session().readTransaction {

            var count = 0

            val getUserRoles = it.run(
                """
                    match (n:User)-[r:roles {active: true}]->(prop:Property)
                    return n.id as id, prop.value as role
                    """.trimIndent()
            )

            var userId: String? = null

            while (getUserRoles.hasNext()) {
                val record = getUserRoles.next()

                userId = record.get("id").asString()
                val neoRole = record.get("role").asString()
                var newRole: String? = null

                when (neoRole) {
                    "Administrator" -> newRole = "Administrator"
                    "ProjectManager" -> newRole = "Project Manager"
                    "FinancialAnalyst" -> newRole = "Financial Analyst"
                    "Marketing" -> newRole = "Marketing"
                    "Fundraising" -> newRole = "Fundraising"
                    "RegionalDirector" -> newRole = "Regional Director"
                    "Consultant" -> newRole = "Consultant"
                    "BibleTranslationLiaison" -> newRole = "Bible Translation Liaison"
                    "Mentor" -> newRole = "Mentor"
                    "Leadership" -> newRole = "Leadership"
                    "FieldOperationsDirector" -> newRole = "Field Operations Director"
                    "LeadFinancialAnalyst" -> newRole = "Lead Financial Analyst"
                    "Intern" -> newRole = "Intern"
                    "Controller" -> newRole = "Controller"
                    "ConsultantManager" -> newRole = "Consultant Manager"
                    "FieldPartner" -> newRole = "Field Partner"
                    "Translator" -> newRole = "Translator"
                    "RegionalCommunicationsCoordinator" -> newRole = "Regional Communications Coordinator"
                    "StaffMember" -> newRole = "Staff Member"

                    else -> {
                        print("userId $userId: failed to recognize role $neoRole ")
                    }
                }

                if (newRole != null) {

                    // write to postgres
                    addUserRoleSQL.setString(1, userId)
                    addUserRoleSQL.setString(2, newRole)

                    val createResult = addUserRoleSQL.executeQuery()
                    createResult.next()
                    val code = createResult.getInt(1)
                    count++
                    println("$count role added for internal user id: $userId code: $code role: $newRole")
                    createResult.close()

                }
            }

            it.commit()
            it.close()

            println("added $count role entries")

        }

    }

}