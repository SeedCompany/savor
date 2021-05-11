package core

import core.database.Neo4j
import java.sql.Connection

import java.time.ZonedDateTime


class Migration (
    val config: Config,
    val neo4j: Neo4j,
    val connection: Connection,
) {


    fun migrate(){
        this.migrateOrganizations()
        this.migrateUsers()
    }

    // ORGS ////////////////////////////////////////////////////////////////////////////////////////////////

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

    private fun migrateOrganizations(){

        //language=SQL
        val callFun = this.connection.prepareStatement("""
            select migrate_org_proc from migrate_org_proc(?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            println("Organizations")
            val result = it.run(
            "match (n:Organization) return count(n) as orgs"
            )

            while (result.hasNext()){
                val record = result.next()
                count = record.get("orgs").asInt()
                println("Count: $count")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print(" ${i}")
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

                while (getOrgResult.hasNext()){
                    val record = getOrgResult.next()

                    orgId = record.get("orgId").asString()
                    val propName = record.get("propName").asString()

                    when (propName){
                        "address" -> {
                            orgAddress = record.get("propValue").asString()
                            orgAddressCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "name" -> {
                            orgName = record.get("propValue").asString()
                            orgNameCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        else -> {
                            println("orgId $orgId: failed to recognize property $propName")
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
                println("internal org id: $orgId code: $code")
                createOrgResult.close()
            }
        }
    }

    // USERS ////////////////////////////////////////////////////////////////////////////////////////////////

    val migrateUserProc = """
        create or replace function migrate_user_proc(
            in pInternalId VARCHAR(32),
            in pAbout text,
            in pEmail varchar(255),
            in pPrivateFirstName varchar(32),
            in pPrivateLastName varchar(32),
            in pPassword varchar(255),
            in pPhone varchar(32),
            in pPublicFirstName varchar(32),
            in pPublicLastName varchar(32),
            in pStatus varchar(32),
            in pTimezone varchar(32),
            in pTitle varchar(32)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysPersonId INT;
        begin
            SELECT sys_person_id 
            FROM sc_people_ext_sys_people
            INTO vSysPersonId
            WHERE sc_people_ext_sys_people.sc_internal_person_id = pInternalId;
            IF NOT found THEN
                INSERT INTO sys_people("about", "phone", "private_first_name", "public_first_name", "public_first_name", "public_last_name", "time_zone", "title")
                VALUES (pName, 'Organization')
                RETURNING sys_person_id
                INTO vSysPersonId;
                INSERT INTO sc_people_ext_sys_people("sys_person_id", "sc_internal_person_id", "status")
                VALUES (vSysPersonId, pInternalId, pStatus);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateUserProc)
        statement.close()
    }

    private fun migrateUsers(){

        //language=SQL
        val createUserSQL = this.connection.prepareStatement("""
            select migrate_user_proc from migrate_user_proc(?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            println("Users")
            val result = it.run(
                "match (n:Users) return count(n) as users"
            )

            while (result.hasNext()){
                val record = result.next()
                count = record.get("users").asInt()
                println("Count: $count")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print(" ${i}")
                val getOrgResult = it.run(
                    """
                        match (n:Users)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as userId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var userId: String? = null

                var about: String? = null
                var email: String? = null
                var displayFirstName: String? = null
                var displayLastName: String? = null
                var password: String? = null
                var phone: String? = null
                var realFirstName: String? = null
                var realLastName: String? = null
                var status: String? = null
                var timezone: String? = null
                var title: String? = null

                while (getOrgResult.hasNext()){
                    val record = getOrgResult.next()

                    userId = record.get("userId").asString()
                    val propName = record.get("propName").asString()

                    when(propName){
                        "about" -> {
                            about = record.get("propValue").asString()
                        }
                        "email" -> {
                            email = record.get("propValue").asString()
                        }
                        "displayFirstName" -> {
                            displayFirstName = record.get("propValue").asString()
                        }
                        "displayLastName" -> {
                            displayLastName = record.get("propValue").asString()
                        }
                        "password" -> {
                            timezone = record.get("propValue").asString()
                        }
                        "phone" -> {
                            phone = record.get("propValue").asString()
                        }
                        "realFirstName" -> {
                            realFirstName = record.get("propValue").asString()
                        }
                        "realLastName" -> {
                            realLastName = record.get("propValue").asString()
                        }
                        "status" -> {
                            status = record.get("propValue").asString()
                        }
                        "timezone" -> {
                            timezone = record.get("propValue").asString()
                        }
                        "title" -> {
                            title = record.get("propValue").asString()
                        }
                        else -> {
                            println("userId $userId: failed to recognize property $propName")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                createUserSQL.setString(1, userId)
                createUserSQL.setString(2, about)
                createUserSQL.setString(3, email)
                createUserSQL.setString(4, realFirstName)
                createUserSQL.setString(5, realLastName)
                createUserSQL.setString(6, password)
                createUserSQL.setString(7, phone)
                createUserSQL.setString(8, displayFirstName)
                createUserSQL.setString(9, displayLastName)
                createUserSQL.setString(10, status)
                createUserSQL.setString(11, timezone)
                createUserSQL.setString(12, title)

                val createResult = createUserSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                println("skip $i internal user id: $userId code: $code")
                createResult.close()
            }
        }
    }
}