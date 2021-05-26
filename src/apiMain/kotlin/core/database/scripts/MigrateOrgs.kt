package core.database.scripts
import core.Config
import java.time.ZonedDateTime
import core.database.Neo4j
import java.sql.Connection

class MigrateOrgs(val config: Config, val neo4j: Neo4j, val connection: Connection) {
    val migrateOrgProc = """
        create or replace function migrate_org_proc(
            in pInternalId VARCHAR(32),
            in pName VARCHAR(255),
            in pAddress VARCHAR(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vId
            WHERE sys_groups.name = pName;
            IF NOT found THEN
                INSERT INTO sys_groups("name", "type")
                VALUES (pName, 'Organization')
                RETURNING sys_group_id
                INTO vId;
                INSERT INTO sc_organizations_ext_sys_groups("sys_group_id", "address", "sc_internal_org_id")
                VALUES (vId, pAddress, pInternalId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateOrgProc)
        statement.close()
    }

    public fun migrateOrganizations() {

        //language=SQL
        val callFun = this.connection.prepareStatement(
            """
            select migrate_org_proc from migrate_org_proc(?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("Organizations ")
            val result = it.run(
                "match (n:Organization) return count(n) as orgs"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("orgs").asInt()
                print("Count: $count ")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
                val getOrgResult = it.run(
                    """
                        match (n:Organization)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as orgId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var orgId: String? = null
                var orgAddress: String? = null
                var orgAddressCreatedAt: ZonedDateTime? = null
                var orgName: String? = null
                var orgNameCreatedAt: ZonedDateTime? = null

                while (getOrgResult.hasNext()) {
                    val record = getOrgResult.next()

                    orgId = record.get("orgId").asString()
                    val propName = record.get("propName").asString()

                    when (propName) {
                        "address" -> {
                            orgAddress = record.get("propValue").asString()
                            orgAddressCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "name" -> {
                            orgName = record.get("propValue").asString()
                            orgNameCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "canDelete" -> {
                        }
                        else -> {
                            print("orgId $orgId: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                callFun.setString(1, orgId)
                callFun.setString(2, orgName)
                callFun.setString(3, orgAddress)
                val createOrgResult = callFun.executeQuery()
                createOrgResult.next()
                val code = createOrgResult.getInt(1)
                print("internal org id: $orgId code: $code")
                createOrgResult.close()
            }
        }
    }
}